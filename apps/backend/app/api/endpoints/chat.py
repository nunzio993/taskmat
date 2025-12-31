from typing import List, Any
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from sqlalchemy.orm import selectinload

from app.api import deps
from app.models.models import Task, TaskThread, TaskMessage
from app.models.user import User
from app.schemas import chat as schemas

router = APIRouter()

@router.post("/tasks/{task_id}/thread", response_model=schemas.TaskThreadResponse)
async def get_or_create_thread(
    task_id: int,
    helper_id: int = None, # Optional query param, required if client
    current_user: User = Depends(deps.get_current_user),
    db: AsyncSession = Depends(deps.get_db)
):
    """
    Get existing thread or create a new one for a task.
    - Helper: Auto-determines client_id from task.
    - Client: Must provide helper_id query param to specify which helper to chat with.
    """
    # Fetch Task
    task_result = await db.execute(select(Task).where(Task.id == task_id))
    task = task_result.scalars().first()
    if not task:
        raise HTTPException(status_code=404, detail="Task not found")

    target_client_id = task.client_id
    target_helper_id = None

    if current_user.role == 'helper':
        # Helper initiating/getting chat with Client
        target_helper_id = current_user.id
        # Guard: Prevent self-chat
        if target_helper_id == target_client_id:
             raise HTTPException(status_code=400, detail="You cannot chat with yourself.")
             
    elif current_user.role == 'client':
        # Client initiating/getting chat with a Helper
        if task.client_id != current_user.id:
            raise HTTPException(status_code=403, detail="Not authorized to access threads for this task")
            
        if not helper_id:
             raise HTTPException(status_code=400, detail="helper_id is required for clients to initiate chat")
             
        target_helper_id = helper_id
        
        # Verify helper exists
        helper_user = await db.get(User, target_helper_id)
        if not helper_user:
            raise HTTPException(status_code=404, detail="Helper not found")
            
    else:
        # Admin or other?
        raise HTTPException(status_code=403, detail="Role not authorized to initiate chat")

    # Check existence of thread between this Task, Client, and Helper
    query = select(TaskThread).where(
        TaskThread.task_id == task_id,
        TaskThread.client_id == target_client_id,
        TaskThread.helper_id == target_helper_id
    ).options(selectinload(TaskThread.messages))
    
    result = await db.execute(query)
    thread = result.scalars().first()

    if not thread:
        thread = TaskThread(
            task_id=task_id,
            client_id=target_client_id,
            helper_id=target_helper_id
        )
        db.add(thread)
        await db.commit()
        await db.refresh(thread)
        # Re-fetch or manually set messages to empty to satisfy response model
        # (A fresh object usually satisfies the ORM relation as empty list if not loaded, or explicit re-load)
    
    return thread

@router.get("/tasks/{task_id}/threads", response_model=List[schemas.TaskThreadResponse])
async def get_task_threads(
    task_id: int,
    current_user: User = Depends(deps.get_current_user),
    db: AsyncSession = Depends(deps.get_db)
):
    """
    Client only: Get all threads for my task with helper details.
    """
    from sqlalchemy import func as sql_func
    from app.models.models import Review
    
    # Verify task ownership
    task_result = await db.execute(select(Task).where(Task.id == task_id))
    task = task_result.scalars().first()
    if not task:
        raise HTTPException(status_code=404, detail="Task not found")
        
    if task.client_id != current_user.id:
         raise HTTPException(status_code=403, detail="Not authorized")

    query = select(TaskThread).where(
        TaskThread.task_id == task_id
    ).options(selectinload(TaskThread.messages))
    
    result = await db.execute(query)
    threads = result.scalars().all()
    
    # Enrich threads with helper details
    enriched_threads = []
    for thread in threads:
        # Fetch helper user
        helper_result = await db.execute(select(User).where(User.id == thread.helper_id))
        helper = helper_result.scalars().first()
        
        # Calculate rating from reviews
        rating_result = await db.execute(
            select(
                sql_func.avg(Review.stars).label("avg_rating"),
                sql_func.count(Review.id).label("review_count")
            ).where(Review.to_user_id == thread.helper_id)
        )
        rating_row = rating_result.first()
        avg_rating = float(rating_row.avg_rating) if rating_row and rating_row.avg_rating else None
        review_count = rating_row.review_count if rating_row else 0
        
        # Format name as "First L." (full first name capitalized + last initial)
        helper_display_name = None
        if helper and helper.name:
            parts = helper.name.strip().split()
            if len(parts) >= 2:
                helper_display_name = f"{parts[0].capitalize()} {parts[-1][0].upper()}."
            else:
                helper_display_name = parts[0].capitalize() if parts else None
        
        # Build messages list first
        messages_list = []
        for msg in thread.messages:
            messages_list.append(schemas.TaskMessageResponse(
                id=msg.id,
                thread_id=msg.thread_id,
                sender_id=msg.sender_id,
                body=msg.body,
                type=msg.type,
                payload=msg.payload,
                created_at=msg.created_at,
                read_at=msg.read_at,
            ))
        
        # Build complete thread response
        thread_response = schemas.TaskThreadResponse(
            id=thread.id,
            task_id=thread.task_id,
            client_id=thread.client_id,
            helper_id=thread.helper_id,
            created_at=thread.created_at,
            messages=messages_list,
            helper_name=helper_display_name,
            helper_avatar_url=None,
            helper_rating=avg_rating,
            helper_review_count=review_count,
        )
        enriched_threads.append(thread_response)
    
    return enriched_threads

@router.get("/threads/{thread_id}/messages", response_model=List[schemas.TaskMessageResponse])
async def get_messages(
    thread_id: int,
    current_user: User = Depends(deps.get_current_user),
    db: AsyncSession = Depends(deps.get_db)
):
    # Verify participation
    thread_result = await db.execute(select(TaskThread).where(TaskThread.id == thread_id))
    thread = thread_result.scalars().first()
    if not thread:
        raise HTTPException(status_code=404, detail="Thread not found")
        
    if current_user.id not in [thread.client_id, thread.helper_id]:
        raise HTTPException(status_code=403, detail="Not authorized")

    query = select(TaskMessage).where(TaskMessage.thread_id == thread_id).order_by(TaskMessage.created_at)
    result = await db.execute(query)
    return result.scalars().all()

@router.post("/threads/{thread_id}/messages", response_model=schemas.TaskMessageResponse)
async def send_message(
    thread_id: int,
    message_in: schemas.TaskMessageCreate,
    current_user: User = Depends(deps.get_current_user),
    db: AsyncSession = Depends(deps.get_db)
):
    # Verify participation
    thread_result = await db.execute(select(TaskThread).where(TaskThread.id == thread_id))
    thread = thread_result.scalars().first()
    if not thread:
        raise HTTPException(status_code=404, detail="Thread not found")
        
    if current_user.id not in [thread.client_id, thread.helper_id]:
        raise HTTPException(status_code=403, detail="Not authorized")

    message = TaskMessage(
        thread_id=thread_id,
        sender_id=current_user.id,
        body=message_in.body,
        type=message_in.type,
        payload=message_in.payload
    )
    db.add(message)
    await db.commit()
    await db.refresh(message)
    return message
