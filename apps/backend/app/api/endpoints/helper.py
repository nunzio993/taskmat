from fastapi import APIRouter, Depends, HTTPException, status
from datetime import datetime, timedelta, timezone
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, func as sql_func
from typing import List

from app.api import deps
from app.core import database
from app.models.user import User
from app.models.user_document import UserDocument
from app.models.models import Task, TaskAssignment, Review, TaskThread, TaskMessage
from app.schemas.user import UserResponse, UserUpdate
from app.schemas.user_document import UserDocumentCreate, UserDocumentResponse

router = APIRouter()

@router.post("/documents", response_model=UserDocumentResponse)
async def upload_document(
    doc_in: UserDocumentCreate,
    current_user: User = Depends(deps.get_current_user),
    db: AsyncSession = Depends(database.get_db),
):
    # Mock upload: in real scenario, we'd handle file upload here or get signed URL
    new_doc = UserDocument(
        user_id=current_user.id,
        type=doc_in.type,
        file_url=doc_in.file_url,
        status="pending"
    )
    db.add(new_doc)
    await db.commit()
    await db.refresh(new_doc)
    return new_doc

@router.get("/documents", response_model=List[UserDocumentResponse])
async def list_documents(
    current_user: User = Depends(deps.get_current_user),
    db: AsyncSession = Depends(database.get_db),
):
    result = await db.execute(select(UserDocument).where(UserDocument.user_id == current_user.id))
    return result.scalars().all()

@router.patch("/profile")
async def update_helper_profile(
    profile_in: UserUpdate,
    current_user: User = Depends(deps.get_current_user),
    db: AsyncSession = Depends(database.get_db),
):
    # This reuses UserUpdate schema but focused on helper fields
    # We could restrict valid fields here if needed
    
    if profile_in.is_available is not None:
        current_user.is_available = profile_in.is_available
    if profile_in.hourly_rate is not None:
        current_user.hourly_rate = profile_in.hourly_rate
    if profile_in.bio is not None:
        current_user.bio = profile_in.bio
    if profile_in.skills is not None:
        current_user.skills = profile_in.skills
        
    db.add(current_user)
    await db.commit()
    await db.refresh(current_user)
    return UserResponse(
        id=current_user.id,
        email=current_user.email,
        role=current_user.role,
        name=current_user.name,
        phone=current_user.phone,
        bio=current_user.bio,
        hourly_rate=current_user.hourly_rate,
        is_available=current_user.is_available,
        skills=current_user.skills,
        document_status=current_user.document_status,
        preferences=current_user.preferences if current_user.preferences else {},
        readiness_status=current_user.readiness_status if current_user.readiness_status else {},
        addresses=[],
        payment_methods=[]
    )

@router.post("/verify")
async def request_verification(
    current_user: User = Depends(deps.get_current_user),
    db: AsyncSession = Depends(database.get_db),
):
    # Check if docs exist
    result = await db.execute(select(UserDocument).where(UserDocument.user_id == current_user.id))
    docs = result.scalars().all()
    
    if not docs:
         raise HTTPException(status_code=400, detail="Please upload at least one document before requesting verification.")
         
    current_user.document_status = "pending"
    db.add(current_user)
    await db.commit()
    
    return {"status": "pending", "message": "Verification request submitted"}


@router.get("/stats")
async def get_helper_stats(
    current_user: User = Depends(deps.get_current_user),
    db: AsyncSession = Depends(database.get_db),
):
    """
    Get helper statistics: earnings (today, week, pending) and rating.
    """
    if current_user.role != "helper":
        raise HTTPException(status_code=403, detail="Only helpers can access stats")
    
    now = datetime.now(timezone.utc)
    today_start = now.replace(hour=0, minute=0, second=0, microsecond=0)
    week_start = today_start - timedelta(days=today_start.weekday())
    
    # Query completed tasks for this helper (where they are assigned)
    completed_today = await db.execute(
        select(sql_func.coalesce(sql_func.sum(Task.price_cents), 0))
        .join(TaskAssignment, Task.id == TaskAssignment.task_id)
        .where(
            TaskAssignment.helper_id == current_user.id,
            Task.status == "completed",
            Task.completed_at >= today_start
        )
    )
    today_cents = completed_today.scalar() or 0
    
    completed_week = await db.execute(
        select(sql_func.coalesce(sql_func.sum(Task.price_cents), 0))
        .join(TaskAssignment, Task.id == TaskAssignment.task_id)
        .where(
            TaskAssignment.helper_id == current_user.id,
            Task.status == "completed",
            Task.completed_at >= week_start
        )
    )
    week_cents = completed_week.scalar() or 0
    
    # Pending payout: tasks in_confirmation or completed but not yet paid out
    # For now, approximate as tasks completed in last 7 days (payout typically weekly)
    pending_result = await db.execute(
        select(sql_func.coalesce(sql_func.sum(Task.price_cents), 0))
        .join(TaskAssignment, Task.id == TaskAssignment.task_id)
        .where(
            TaskAssignment.helper_id == current_user.id,
            Task.status.in_(["completed", "in_confirmation"])
        )
    )
    pending_payout_cents = pending_result.scalar() or 0
    
    # Rating from reviews where this helper is the recipient
    rating_result = await db.execute(
        select(
            sql_func.coalesce(sql_func.avg(Review.stars), 0),
            sql_func.count(Review.id)
        )
        .where(
            Review.to_user_id == current_user.id,
            Review.status == "visible"
        )
    )
    row = rating_result.one()
    avg_rating = float(row[0]) if row[0] else 0.0
    review_count = row[1] or 0
    
    return {
        "today_cents": int(today_cents),
        "week_cents": int(week_cents),
        "pending_payout_cents": int(pending_payout_cents),
        "rating": round(avg_rating, 1),
        "review_count": review_count
    }


@router.get("/my-threads")
async def get_helper_threads(
    current_user: User = Depends(deps.get_current_user),
    db: AsyncSession = Depends(database.get_db),
):
    """
    Get recent chat threads for the helper with last message info.
    """
    if current_user.role != "helper":
        raise HTTPException(status_code=403, detail="Only helpers can access their threads")
    
    # Get threads where this helper is a participant AND task is still active
    threads_result = await db.execute(
        select(TaskThread)
        .join(Task, TaskThread.task_id == Task.id)
        .where(
            TaskThread.helper_id == current_user.id,
            Task.status.in_(["posted", "assigned", "in_progress", "in_confirmation"])
        )
        .order_by(TaskThread.created_at.desc())
        .limit(10)
    )
    threads = threads_result.scalars().all()
    
    result = []
    for thread in threads:
        # Get task info
        task_result = await db.execute(
            select(Task).where(Task.id == thread.task_id)
        )
        task = task_result.scalar_one_or_none()
        if not task:
            continue
            
        # Get client info
        client_result = await db.execute(
            select(User).where(User.id == thread.client_id)
        )
        client = client_result.scalar_one_or_none()
        
        # Get last message
        last_msg_result = await db.execute(
            select(TaskMessage)
            .where(TaskMessage.thread_id == thread.id)
            .order_by(TaskMessage.created_at.desc())
            .limit(1)
        )
        last_msg = last_msg_result.scalar_one_or_none()
        
        # Count unread messages (messages from client not read by helper)
        unread_result = await db.execute(
            select(sql_func.count(TaskMessage.id))
            .where(
                TaskMessage.thread_id == thread.id,
                TaskMessage.sender_id != current_user.id,
                TaskMessage.read_at.is_(None)
            )
        )
        unread_count = unread_result.scalar() or 0
        
        result.append({
            "thread_id": thread.id,
            "task_id": thread.task_id,
            "task_title": task.title if task else "Task",
            "task_status": task.status if task else "posted",
            "other_user_name": client.name if client else "Cliente",
            "other_user_avatar": client.avatar_url if client else None,
            "last_message": last_msg.body if last_msg and last_msg.body else "Nessun messaggio",
            "last_message_at": last_msg.created_at.isoformat() if last_msg else thread.created_at.isoformat(),
            "has_unread": unread_count > 0
        })
    
    return result
