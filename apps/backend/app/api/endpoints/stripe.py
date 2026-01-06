"""
Stripe Connect Integration
- Helper onboarding (create Connect account)
- Payment intent with application fee
- Webhook handling
"""
import stripe
from fastapi import APIRouter, Depends, HTTPException, Request, Header
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from pydantic import BaseModel
from typing import Optional

from app.core import database
from app.core.config import settings
from app.models.user import User
from app.models.models import Task, Payment, TaskStatus, PaymentStatus
from app.models.category_settings import CategorySettings
from app.api.deps import get_current_user

# Configure Stripe
stripe.api_key = settings.STRIPE_SECRET_KEY

router = APIRouter(prefix="/stripe", tags=["stripe"])


# ============================================
# SCHEMAS
# ============================================

class OnboardingResponse(BaseModel):
    account_id: str
    onboarding_url: str


class PaymentIntentRequest(BaseModel):
    task_id: int


class PaymentIntentResponse(BaseModel):
    client_secret: str
    payment_intent_id: str
    amount_cents: int
    fee_cents: int


# ============================================
# HELPER ONBOARDING
# ============================================

@router.post("/connect/onboard", response_model=OnboardingResponse)
async def create_connect_account(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(database.get_db)
):
    """Create a Stripe Connect account for helper and return onboarding link"""
    if current_user.role != 'helper':
        raise HTTPException(status_code=400, detail="Only helpers can create Stripe accounts")
    
    # Check if already has account
    if current_user.stripe_account_id:
        # Return new onboarding link for existing account
        account_link = stripe.AccountLink.create(
            account=current_user.stripe_account_id,
            refresh_url="http://localhost:3002/#/profile?stripe=refresh",
            return_url="http://localhost:3002/#/profile?stripe=complete",
            type="account_onboarding",
        )
        return OnboardingResponse(
            account_id=current_user.stripe_account_id,
            onboarding_url=account_link.url
        )
    
    # Create new Express account
    account = stripe.Account.create(
        type="express",
        country="IT",
        email=current_user.email,
        capabilities={
            "card_payments": {"requested": True},
            "transfers": {"requested": True},
        },
        business_type="individual",
        metadata={"user_id": str(current_user.id)},
    )
    
    # Save account ID
    current_user.stripe_account_id = account.id
    await db.commit()
    
    # Create onboarding link
    account_link = stripe.AccountLink.create(
        account=account.id,
        refresh_url="http://localhost:3002/#/profile?stripe=refresh",
        return_url="http://localhost:3002/#/profile?stripe=complete",
        type="account_onboarding",
    )
    
    return OnboardingResponse(
        account_id=account.id,
        onboarding_url=account_link.url
    )


@router.get("/connect/status")
async def get_connect_status(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(database.get_db)
):
    """Check Stripe Connect onboarding status"""
    if not current_user.stripe_account_id:
        return {"connected": False, "onboarding_complete": False}
    
    try:
        account = stripe.Account.retrieve(current_user.stripe_account_id)
        
        # Check if onboarding is complete
        is_complete = (
            account.charges_enabled and 
            account.payouts_enabled and
            account.details_submitted
        )
        
        # Update database if status changed
        if is_complete and not current_user.stripe_onboarding_complete:
            current_user.stripe_onboarding_complete = True
            # Update readiness status
            if current_user.readiness_status is None:
                current_user.readiness_status = {}
            current_user.readiness_status['stripe'] = True
            await db.commit()
        
        return {
            "connected": True,
            "onboarding_complete": is_complete,
            "charges_enabled": account.charges_enabled,
            "payouts_enabled": account.payouts_enabled,
        }
    except stripe.error.StripeError as e:
        raise HTTPException(status_code=400, detail=str(e))


# ============================================
# PAYMENT INTENT (Client pays for task)
# ============================================

@router.post("/payment-intent", response_model=PaymentIntentResponse)
async def create_payment_intent(
    request: PaymentIntentRequest,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(database.get_db)
):
    """Create a payment intent for a task with platform fee"""
    # Get task
    result = await db.execute(
        select(Task).where(Task.id == request.task_id)
    )
    task = result.scalars().first()
    
    if not task:
        raise HTTPException(status_code=404, detail="Task not found")
    
    if task.client_id != current_user.id:
        raise HTTPException(status_code=403, detail="Not your task")
    
    if task.status != TaskStatus.ASSIGNED:
        raise HTTPException(status_code=400, detail="Task must be assigned before payment")
    
    # Get helper
    helper_result = await db.execute(
        select(User).where(User.id == task.helper_id)
    )
    helper = helper_result.scalars().first()
    
    if not helper or not helper.stripe_account_id:
        raise HTTPException(status_code=400, detail="Helper not connected to Stripe")
    
    if not helper.stripe_onboarding_complete:
        raise HTTPException(status_code=400, detail="Helper Stripe onboarding incomplete")
    
    # Get category fee settings
    cat_result = await db.execute(
        select(CategorySettings).where(CategorySettings.slug == task.category)
    )
    category = cat_result.scalars().first()
    
    # Calculate fee
    amount_cents = task.price_cents
    if category:
        fee_percent = float(category.fee_percent)
        fee_cents = max(
            int(amount_cents * fee_percent / 100),
            category.fee_min_cents
        )
        if category.fee_max_cents:
            fee_cents = min(fee_cents, category.fee_max_cents)
    else:
        # Default 15% fee
        fee_cents = int(amount_cents * 0.15)
    
    # Create payment intent with transfer
    try:
        payment_intent = stripe.PaymentIntent.create(
            amount=amount_cents,
            currency="eur",
            payment_method_types=["card"],
            application_fee_amount=fee_cents,
            transfer_data={
                "destination": helper.stripe_account_id,
            },
            metadata={
                "task_id": str(task.id),
                "client_id": str(current_user.id),
                "helper_id": str(helper.id),
            },
        )
        
        # Create/update payment record
        payment_result = await db.execute(
            select(Payment).where(Payment.task_id == task.id)
        )
        payment = payment_result.scalars().first()
        
        if payment:
            payment.stripe_payment_intent_id = payment_intent.id
            payment.amount_cents = amount_cents
            payment.app_fee_cents = fee_cents
        else:
            payment = Payment(
                task_id=task.id,
                stripe_payment_intent_id=payment_intent.id,
                amount_cents=amount_cents,
                app_fee_cents=fee_cents,
                status=PaymentStatus.PENDING,
            )
            db.add(payment)
        
        await db.commit()
        
        return PaymentIntentResponse(
            client_secret=payment_intent.client_secret,
            payment_intent_id=payment_intent.id,
            amount_cents=amount_cents,
            fee_cents=fee_cents,
        )
        
    except stripe.error.StripeError as e:
        raise HTTPException(status_code=400, detail=str(e))


# ============================================
# WEBHOOK
# ============================================

@router.post("/webhook")
async def stripe_webhook(
    request: Request,
    stripe_signature: Optional[str] = Header(None, alias="Stripe-Signature"),
    db: AsyncSession = Depends(database.get_db)
):
    """Handle Stripe webhooks"""
    payload = await request.body()
    
    try:
        event = stripe.Webhook.construct_event(
            payload, stripe_signature, settings.STRIPE_WEBHOOK_SECRET
        )
    except ValueError:
        raise HTTPException(status_code=400, detail="Invalid payload")
    except stripe.error.SignatureVerificationError:
        raise HTTPException(status_code=400, detail="Invalid signature")
    
    # Handle events
    if event.type == "payment_intent.succeeded":
        payment_intent = event.data.object
        task_id = payment_intent.metadata.get("task_id")
        
        if task_id:
            # Update payment status
            result = await db.execute(
                select(Payment).where(Payment.stripe_payment_intent_id == payment_intent.id)
            )
            payment = result.scalars().first()
            
            if payment:
                payment.status = PaymentStatus.CAPTURED
                from datetime import datetime, timezone
                payment.captured_at = datetime.now(timezone.utc)
                await db.commit()
    
    elif event.type == "account.updated":
        # Helper account status changed
        account = event.data.object
        user_id = account.metadata.get("user_id")
        
        if user_id:
            result = await db.execute(
                select(User).where(User.id == int(user_id))
            )
            user = result.scalars().first()
            
            if user:
                is_complete = (
                    account.charges_enabled and 
                    account.payouts_enabled and
                    account.details_submitted
                )
                user.stripe_onboarding_complete = is_complete
                if user.readiness_status is None:
                    user.readiness_status = {}
                user.readiness_status['stripe'] = is_complete
                await db.commit()
    
    return {"status": "ok"}


# ============================================
# PUBLIC KEY (for frontend)
# ============================================

@router.get("/config")
async def get_stripe_config():
    """Get Stripe publishable key for frontend"""
    return {
        "publishable_key": settings.STRIPE_PUBLISHABLE_KEY,
    }
