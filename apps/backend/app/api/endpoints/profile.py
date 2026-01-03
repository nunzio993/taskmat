from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession
from app.api import deps
from app.core import database
from app.models.user import User
from app.models.address import Address
from app.models.payment_method import PaymentMethod
from app.schemas.user import UserResponse, UserUpdate
from app.schemas.address import AddressCreate, AddressResponse, AddressUpdate
from app.schemas.payment_method import PaymentMethodCreate, PaymentMethodResponse
from sqlalchemy import select

router = APIRouter()

from sqlalchemy.orm import selectinload

@router.get("/me")
async def read_users_me(
    current_user: User = Depends(deps.get_current_user),
    db: AsyncSession = Depends(database.get_db)
):
    # Re-fetch with eager loading to support Pydantic model serialization
    result = await db.execute(
        select(User)
        .options(selectinload(User.addresses), selectinload(User.payment_methods))
        .filter(User.id == current_user.id)
    )
    user = result.scalars().first()
    
    # Manual construction to avoid Greenlet error
    return UserResponse(
        id=user.id,
        email=user.email,
        role=user.role,
        name=user.name,
        phone=user.phone,
        bio=user.bio,
        languages=user.languages if user.languages else ['Italiano'],
        hourly_rate=user.hourly_rate,
        is_available=user.is_available,
        skills=user.skills if user.skills else [],
        document_status=user.document_status,
        preferences=user.preferences if user.preferences else {},
        readiness_status=user.readiness_status if user.readiness_status else {},
        addresses=[], # Avoid lazy load issues
        payment_methods=[] # Avoid lazy load issues
    )

@router.patch("/me")
async def update_user_me(
    user_in: UserUpdate,
    current_user: User = Depends(deps.get_current_user),
    db: AsyncSession = Depends(database.get_db),
):
    # Update simple fields
    if user_in.name is not None:
        current_user.name = user_in.name
    if user_in.phone is not None:
        current_user.phone = user_in.phone
    if user_in.bio is not None:
        current_user.bio = user_in.bio
    if user_in.languages is not None:
        current_user.languages = user_in.languages
    if user_in.hourly_rate is not None:
        current_user.hourly_rate = user_in.hourly_rate
    if user_in.is_available is not None:
        current_user.is_available = user_in.is_available
        
    # Update complex JSONB fields (merge logic)
    if user_in.preferences is not None:
        # Merge existing preferences with new ones
        current_prefs = dict(current_user.preferences or {})
        current_prefs.update(user_in.preferences)
        current_user.preferences = current_prefs
        
    if user_in.readiness_status is not None:
        current_readiness = dict(current_user.readiness_status or {})
        current_readiness.update(user_in.readiness_status)
        current_user.readiness_status = current_readiness

    db.add(current_user)
    await db.commit()

    # Re-fetch to get relationships and updated formatting
    result = await db.execute(
        select(User)
        .options(selectinload(User.addresses), selectinload(User.payment_methods))
        .filter(User.id == current_user.id)
    )
    user = result.scalars().first()

    return UserResponse(
        id=user.id,
        email=user.email,
        role=user.role,
        name=user.name,
        phone=user.phone,
        bio=user.bio,
        languages=user.languages if user.languages else ['Italiano'],
        hourly_rate=user.hourly_rate,
        is_available=user.is_available,
        skills=user.skills if user.skills else [],
        document_status=user.document_status,
        preferences=user.preferences if user.preferences else {},
        readiness_status=user.readiness_status if user.readiness_status else {},
        addresses=[],
        payment_methods=[]
    )

# ADDRESSES
@router.post("/addresses", response_model=AddressResponse)
async def create_address(
    address_in: AddressCreate,
    current_user: User = Depends(deps.get_current_user),
    db: AsyncSession = Depends(database.get_db),
):
    address = Address(**address_in.dict(), user_id=current_user.id)
    db.add(address)
    await db.commit()
    await db.refresh(address)
    return address

@router.get("/addresses", response_model=list[AddressResponse])
async def read_addresses(
    current_user: User = Depends(deps.get_current_user),
    db: AsyncSession = Depends(database.get_db),
):
    result = await db.execute(select(Address).filter(Address.user_id == current_user.id))
    return result.scalars().all()

# PAYMENT METHODS
@router.post("/payment-methods", response_model=PaymentMethodResponse)
async def create_payment_method(
    payment_in: PaymentMethodCreate,
    current_user: User = Depends(deps.get_current_user),
    db: AsyncSession = Depends(database.get_db),
):
    # Basic Check to ensure only 1 default exists logic could be added here
    payment = PaymentMethod(**payment_in.dict(), user_id=current_user.id)
    db.add(payment)
    await db.commit()
    await db.refresh(payment)
    return payment

@router.get("/payment-methods", response_model=list[PaymentMethodResponse])
async def read_payment_methods(
    current_user: User = Depends(deps.get_current_user),
    db: AsyncSession = Depends(database.get_db),
):
    result = await db.execute(select(PaymentMethod).filter(PaymentMethod.user_id == current_user.id))
    return result.scalars().all()

@router.post("/become-helper")
async def become_helper(
    current_user: User = Depends(deps.get_current_user),
    db: AsyncSession = Depends(database.get_db),
):
    current_user.role = "helper"
    db.add(current_user)
    await db.commit()
    
    # Re-fetch with eager loading
    result = await db.execute(
        select(User)
        .options(selectinload(User.addresses), selectinload(User.payment_methods))
        .filter(User.id == current_user.id)
    )
    user = result.scalars().first()
    
    return UserResponse(
        id=user.id,
        email=user.email,
        role=user.role,
        name=user.name,
        phone=user.phone,
        bio=user.bio,
        languages=user.languages if user.languages else ['Italiano'],
        hourly_rate=user.hourly_rate,
        is_available=user.is_available,
        skills=user.skills if user.skills else [],
        document_status=user.document_status,
        preferences=user.preferences if user.preferences else {},
        readiness_status=user.readiness_status if user.readiness_status else {},
        addresses=[],
        payment_methods=[]
    )
