from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, func, desc, or_
from app.api import deps
from app.core import database
from app.models.user import User
from app.models.models import Task, TaskAssignment, Review, TaskStatus, UserRole
from app.schemas.public_user import PublicUserResponse, PublicUserStats
from app.schemas.user import UserResponse # Re-use for reviews if needed, or simple dict
from typing import List, Optional
from pydantic import BaseModel
from datetime import datetime

router = APIRouter()

class ReviewResponse(BaseModel):
    id: int
    from_user_name: str
    stars: int
    comment: Optional[str]
    created_at: datetime
    
    class Config:
        from_attributes = True

class PaginatedReviews(BaseModel):
    items: List[ReviewResponse]
    total: int
    page: int
    size: int

@router.get("/{user_id}/public", response_model=PublicUserResponse)
async def read_public_profile(
    user_id: int,
    db: AsyncSession = Depends(database.get_db),
    current_user: Optional[User] = Depends(deps.get_current_user_optional) # Optional auth for viewing
):
    # Fetch User
    result = await db.execute(select(User).filter(User.id == user_id))
    user = result.scalars().first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")

    # Calculate Stats
    # 1. Rating & Reviews Count
    reviews_stats = await db.execute(
        select(
            func.count(Review.id),
            func.avg(Review.stars)
        ).filter(Review.to_user_id == user_id)
    )
    r_count, r_avg = reviews_stats.one()
    r_count = r_count or 0
    r_avg = float(r_avg) if r_avg else 0.0

    # 2. Tasks/Jobs Completed
    completed_count = 0
    if user.role == UserRole.HELPER:
        # Helper: jobs completed
        jobs_stats = await db.execute(
            select(func.count(TaskAssignment.id))
            .join(Task, Task.id == TaskAssignment.task_id)
            .filter(
                TaskAssignment.helper_id == user_id,
                Task.status == TaskStatus.COMPLETED
            )
        )
        completed_count = jobs_stats.scalar() or 0
    else:
        # Client: tasks posted and completed
        tasks_stats = await db.execute(
            select(func.count(Task.id))
            .filter(
                Task.client_id == user_id,
                Task.status == TaskStatus.COMPLETED
            )
        )
        completed_count = tasks_stats.scalar() or 0
        
    stats = PublicUserStats(
        tasks_completed=completed_count,
        reviews_count=r_count,
        average_rating=round(r_avg, 1),
        cancel_rate_label="Reliable" # Placeholder logic
    )

    return PublicUserResponse(
        id=user.id,
        name=user.name,
        role=user.role,
        bio=user.bio,
        languages=user.languages if user.languages else [],
        hourly_rate=user.hourly_rate if user.role == UserRole.HELPER else None,
        skills=user.skills if user.skills else [],
        stats=stats
    )

@router.get("/{user_id}/reviews", response_model=PaginatedReviews)
async def read_public_reviews(
    user_id: int,
    page: int = 1,
    size: int = 10,
    db: AsyncSession = Depends(database.get_db)
):
    offset = (page - 1) * size
    
    # Query Reviews
    query = (
        select(Review, User.name)
        .join(User, User.id == Review.from_user_id)
        .filter(Review.to_user_id == user_id)
        .order_by(desc(Review.created_at))
        .offset(offset)
        .limit(size)
    )
    
    result = await db.execute(query)
    rows = result.all() # list of (Review, name)
    
    # Total count
    count_res = await db.execute(
        select(func.count(Review.id)).filter(Review.to_user_id == user_id)
    )
    total = count_res.scalar() or 0
    
    items = []
    for review, from_name in rows:
        items.append(ReviewResponse(
            id=review.id,
            from_user_name=from_name,
            stars=review.stars,
            comment=review.comment,
            created_at=review.created_at
        ))
        
    return PaginatedReviews(
        items=items,
        total=total,
        page=page,
        size=size
    )
