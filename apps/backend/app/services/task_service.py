from datetime import datetime
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from fastapi import HTTPException

from app.models.models import Task, TaskAssignment, TaskStatus, Payment, PaymentStatus, TaskOffer, OfferStatus
from app.models.user import User
from app.core.redis_client import redis_client

class TaskService:
    async def select_offer(self, db: AsyncSession, task_id: int, offer_id: int):
        """
        Transition: POSTED -> ASSIGNED
        Action:
        1. Verify Task is POSTED
        2. Verify Offer exists and matches Task
        3. Create Payment (Authorized)
        4. Update Task (status=ASSIGNED, selected_offer_id=offer_id, price=offer.price)
        5. Update Offers (Selected -> ACCEPTED, Others -> DECLINED)
        6. Create TaskAssignment
        """
        # 1. Fetch Task
        task = await db.get(Task, task_id)
        if not task:
            raise HTTPException(status_code=404, detail="Task not found")
            
        # Idempotency / State Check
        if task.status == TaskStatus.ASSIGNED:
            if task.selected_offer_id == offer_id:
                return task
            raise HTTPException(status_code=400, detail="Task already assigned to another offer")
            
        if task.status != TaskStatus.POSTED:
             raise HTTPException(status_code=400, detail="Task is not available for assignment (current status: " + str(task.status) + ")")
             
        # 2. Fetch Offer
        offer = await db.get(TaskOffer, offer_id)
        if not offer or offer.task_id != task_id:
            raise HTTPException(status_code=404, detail="Offer not found for this task")
            
        # 3. MOCK PAYMENT PRE-AUTH
        stripe_pi_id = f"pi_mock_{task_id}_{datetime.utcnow().timestamp()}"
        payment = Payment(
            task_id=task_id,
            stripe_payment_intent_id=stripe_pi_id,
            amount_cents=offer.price_cents,
            app_fee_cents=int(offer.price_cents * 0.15), # 15% fee
            status=PaymentStatus.REQUIRES_CAPTURE
        )
        db.add(payment)
        
        # 4. Update Task
        task.status = TaskStatus.ASSIGNED
        task.selected_offer_id = offer.id
        task.price_cents = offer.price_cents
        task.assigned_at = datetime.utcnow()
        task.version += 1
        
        # 5. Update Offers
        # Set selected to ACCEPTED
        offer.status = OfferStatus.ACCEPTED
        
        # Set others to DECLINED
        
        # Re-fetch offers to decline
        other_offers_result = await db.execute(select(TaskOffer).where(TaskOffer.task_id == task_id, TaskOffer.id != offer_id))
        for o in other_offers_result.scalars().all():
            o.status = OfferStatus.DECLINED
            
        # 6. Create Assignment
        assignment = TaskAssignment(
            task_id=task_id,
            helper_id=offer.helper_id,
            status=TaskStatus.ASSIGNED,
            assigned_at=datetime.utcnow()
        )
        db.add(assignment)
        
        await db.commit()
        await db.refresh(task)
        
        # Publish WebSocket event to notify helper that offer was accepted
        await redis_client.publish_event(
            user_id=offer.helper_id,
            event_type="offer_accepted",
            payload={"task_id": task_id, "offer_id": offer_id}
        )
        
        return task

    async def start_task(self, db: AsyncSession, task_id: int, helper_id: int):
        """Transition: ASSIGNED -> IN_PROGRESS"""
        task = await db.get(Task, task_id)
        if not task:
            raise HTTPException(status_code=404, detail="Task not found")
            
        if task.status == TaskStatus.IN_PROGRESS:
            return task

        if task.status != TaskStatus.ASSIGNED:
             raise HTTPException(status_code=400, detail=f"Task not in ASSIGNED state (current: {task.status})")
             
        # Verify helper is the assignee
        assignment_result = await db.execute(
            select(TaskAssignment).where(
                TaskAssignment.task_id == task_id,
                TaskAssignment.helper_id == helper_id
            )
        )
        assignment = assignment_result.scalars().first()
        if not assignment:
            raise HTTPException(status_code=403, detail="You are not assigned to this task")
        
        task.status = TaskStatus.IN_PROGRESS
        task.started_at = datetime.utcnow()
        await db.commit()
        await db.refresh(task)
        return task

    async def request_completion(self, db: AsyncSession, task_id: int, helper_id: int):
        """Transition: IN_PROGRESS -> IN_CONFIRMATION"""
        task = await db.get(Task, task_id)
        if not task:
            raise HTTPException(status_code=404, detail="Task not found")
            
        if task.status == TaskStatus.IN_CONFIRMATION:
            return task

        if task.status != TaskStatus.IN_PROGRESS:
             raise HTTPException(status_code=400, detail=f"Task not in IN_PROGRESS state (current: {task.status})")
             
        # Check for Proofs
        from app.models.models import TaskProof
        result = await db.execute(select(TaskProof).where(TaskProof.task_id == task_id))
        proofs = result.scalars().all()
        if not proofs:
             # In strict mode, we require proofs. 
             # For MVP dev flow, we might warn or block. 
             # Let's BLOCK as per requirements.
             raise HTTPException(status_code=400, detail="Completion requires at least one proof of work (photo/doc).")
             
        task.status = TaskStatus.IN_CONFIRMATION
        task.completion_requested_at = datetime.utcnow()
        
        await db.commit()
        await db.refresh(task)
        return task

    async def confirm_completion(self, db: AsyncSession, task_id: int, client_id: int):
        """
        Transition: IN_CONFIRMATION -> COMPLETED
        Action: Capture Payment
        """
        task = await db.get(Task, task_id)
        if not task:
             raise HTTPException(status_code=404, detail="Task not found")
             
        if task.status == TaskStatus.COMPLETED:
            return task

        if task.status != TaskStatus.IN_CONFIRMATION:
             raise HTTPException(status_code=400, detail=f"Task not in IN_CONFIRMATION state (current: {task.status})")
             
        # Mock Capture
        result = await db.execute(select(Payment).where(Payment.task_id == task_id))
        payment = result.scalars().first()
        
        if payment:
            payment.status = PaymentStatus.CAPTURED
            payment.captured_at = datetime.utcnow()
            
        task.status = TaskStatus.COMPLETED
        task.completed_at = datetime.utcnow()
        
        # Dispute Window (e.g. 48h)
        from datetime import timedelta
        task.dispute_open_until = datetime.utcnow() + timedelta(hours=48)
        
        # Update assignment completed_at
        result_assign = await db.execute(select(TaskAssignment).where(TaskAssignment.task_id == task_id))
        assignment = result_assign.scalars().first()
        if assignment:
            assignment.completed_at = datetime.utcnow()
            assignment.status = TaskStatus.COMPLETED
            
        await db.commit()
        await db.refresh(task)
        
        # Publish WebSocket event to notify helper about task completion
        if assignment:
            await redis_client.publish_event(
                user_id=assignment.helper_id,
                event_type="task_status_changed",
                payload={"task_id": task_id, "status": "completed"}
            )
        
        return task

task_service = TaskService()
