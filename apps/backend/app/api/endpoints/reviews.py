"""
Reviews API endpoints with blind mode support.
"""
from datetime import datetime, timedelta, timezone
from typing import Optional
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, and_

from app.api import deps
from app.models.models import Task, Review, ReviewStatus, TaskStatus
from app.models.user import User
from app.schemas.reviews import (
    ReviewCreate, ReviewUpdate, ReviewResponse, ReviewStatusResponse
)

router = APIRouter()

# Configuration (could be moved to SystemSettings)
BLIND_MODE_ENABLED = True
EDIT_WINDOW_MINUTES = 10


def format_user_name(user: User) -> str:
    """Format user name as 'First L.' for privacy."""
    if not user or not user.name:
        return "User"
    parts = user.name.strip().split()
    if len(parts) >= 2:
        return f"{parts[0].capitalize()} {parts[-1][0].upper()}."
    return parts[0].capitalize() if parts else "User"


async def check_and_reveal_reviews(db: AsyncSession, task_id: int):
    """
    Check if both reviews are submitted for a task.
    If so, reveal them (change status from PENDING_BLIND to VISIBLE).
    """
    reviews_result = await db.execute(
        select(Review).where(Review.task_id == task_id)
    )
    reviews = reviews_result.scalars().all()
    
    if len(reviews) == 2:
        # Both parties reviewed, reveal both
        for review in reviews:
            if review.status == ReviewStatus.PENDING_BLIND.value:
                review.status = ReviewStatus.VISIBLE.value
        await db.commit()


@router.get("/tasks/{task_id}/reviews/status", response_model=ReviewStatusResponse)
async def get_review_status(
    task_id: int,
    current_user: User = Depends(deps.get_current_user),
    db: AsyncSession = Depends(deps.get_db)
):
    """
    Get the review status for a task.
    Returns whether user can/has reviewed and visibility info.
    """
    # Fetch task
    task = await db.get(Task, task_id)
    if not task:
        raise HTTPException(status_code=404, detail="Task not found")
    
    # Check if user is involved in this task
    is_client = task.client_id == current_user.id
    
    # Get assigned helper from selected offer
    helper_id = None
    if task.selected_offer_id:
        from app.models.models import TaskOffer
        offer = await db.get(TaskOffer, task.selected_offer_id)
        if offer:
            helper_id = offer.helper_id
    
    is_helper = helper_id == current_user.id if helper_id else False
    
    if not is_client and not is_helper:
        raise HTTPException(status_code=403, detail="Not authorized to view review status for this task")
    
    # Can only review completed tasks
    can_review = task.status == TaskStatus.COMPLETED.value
    
    # Fetch existing reviews
    reviews_result = await db.execute(
        select(Review).where(Review.task_id == task_id)
    )
    reviews = list(reviews_result.scalars().all())
    
    my_review = None
    other_review = None
    
    for r in reviews:
        if r.from_user_id == current_user.id:
            my_review = r
        else:
            other_review = r
    
    has_reviewed = my_review is not None
    other_reviewed = other_review is not None
    
    # Determine visibility
    if BLIND_MODE_ENABLED:
        reviews_visible = has_reviewed and other_reviewed
    else:
        reviews_visible = True
    
    # Check edit window
    edit_allowed = False
    if my_review and my_review.created_at:
        edit_deadline = my_review.created_at + timedelta(minutes=EDIT_WINDOW_MINUTES)
        edit_allowed = datetime.now(timezone.utc) < edit_deadline
    
    # Build response
    def review_to_response(r: Review, from_user: User = None) -> ReviewResponse:
        return ReviewResponse(
            id=r.id,
            task_id=r.task_id,
            from_user_id=r.from_user_id,
            to_user_id=r.to_user_id,
            from_user_name=format_user_name(from_user) if from_user else None,
            from_role=r.from_role,
            stars=r.stars,
            comment=r.comment,
            tags=r.tags or [],
            status=r.status,
            created_at=r.created_at,
        )
    
    my_review_response = None
    if my_review:
        my_review_response = review_to_response(my_review, current_user)
    
    other_review_response = None
    if other_review and reviews_visible and other_review.status == ReviewStatus.VISIBLE.value:
        # Fetch other user for name
        other_user = await db.get(User, other_review.from_user_id)
        other_review_response = review_to_response(other_review, other_user)
    
    return ReviewStatusResponse(
        task_id=task_id,
        task_status=task.status,
        can_review=can_review and not has_reviewed,
        has_reviewed=has_reviewed,
        other_reviewed=other_reviewed,
        reviews_visible=reviews_visible,
        my_review=my_review_response,
        other_review=other_review_response,
        edit_allowed=edit_allowed,
    )


@router.post("/tasks/{task_id}/reviews", response_model=ReviewResponse)
async def submit_review(
    task_id: int,
    review_in: ReviewCreate,
    current_user: User = Depends(deps.get_current_user),
    db: AsyncSession = Depends(deps.get_db)
):
    """
    Submit a review for a completed task.
    """
    # Fetch task
    task = await db.get(Task, task_id)
    if not task:
        raise HTTPException(status_code=404, detail="Task not found")
    
    # Must be completed
    if task.status != TaskStatus.COMPLETED.value:
        raise HTTPException(status_code=400, detail="Can only review completed tasks")
    
    # Determine role and target
    is_client = task.client_id == current_user.id
    
    helper_id = None
    if task.selected_offer_id:
        from app.models.models import TaskOffer
        offer = await db.get(TaskOffer, task.selected_offer_id)
        if offer:
            helper_id = offer.helper_id
    
    is_helper = helper_id == current_user.id if helper_id else False
    
    if not is_client and not is_helper:
        raise HTTPException(status_code=403, detail="Not authorized to review this task")
    
    # Determine to_user
    if is_client:
        to_user_id = helper_id
        from_role = "client"
    else:
        to_user_id = task.client_id
        from_role = "helper"
    
    if not to_user_id:
        raise HTTPException(status_code=400, detail="Cannot determine review recipient")
    
    # Check if already reviewed
    existing = await db.execute(
        select(Review).where(
            and_(Review.task_id == task_id, Review.from_user_id == current_user.id)
        )
    )
    if existing.scalars().first():
        raise HTTPException(status_code=400, detail="You have already reviewed this task")
    
    # Validate tags against whitelist
    if review_in.tags:
        from app.schemas.reviews import CLIENT_TAGS, HELPER_TAGS
        allowed_tags = CLIENT_TAGS if from_role == "client" else HELPER_TAGS
        for tag in review_in.tags:
            if tag not in allowed_tags:
                raise HTTPException(status_code=400, detail=f"Invalid tag: {tag}")
    
    # Create review
    initial_status = ReviewStatus.PENDING_BLIND.value if BLIND_MODE_ENABLED else ReviewStatus.VISIBLE.value
    
    review = Review(
        task_id=task_id,
        from_user_id=current_user.id,
        to_user_id=to_user_id,
        from_role=from_role,
        stars=review_in.stars,
        comment=review_in.comment,
        tags=review_in.tags or [],
        status=initial_status,
    )
    db.add(review)
    await db.commit()
    await db.refresh(review)
    
    # Check if we should reveal reviews (both submitted)
    await check_and_reveal_reviews(db, task_id)
    await db.refresh(review)
    
    return ReviewResponse(
        id=review.id,
        task_id=review.task_id,
        from_user_id=review.from_user_id,
        to_user_id=review.to_user_id,
        from_user_name=format_user_name(current_user),
        from_role=review.from_role,
        stars=review.stars,
        comment=review.comment,
        tags=review.tags or [],
        status=review.status,
        created_at=review.created_at,
    )


@router.patch("/tasks/{task_id}/reviews/me", response_model=ReviewResponse)
async def update_my_review(
    task_id: int,
    review_in: ReviewUpdate,
    current_user: User = Depends(deps.get_current_user),
    db: AsyncSession = Depends(deps.get_db)
):
    """
    Update own review within the edit window.
    """
    # Find my review
    result = await db.execute(
        select(Review).where(
            and_(Review.task_id == task_id, Review.from_user_id == current_user.id)
        )
    )
    review = result.scalars().first()
    
    if not review:
        raise HTTPException(status_code=404, detail="Review not found")
    
    # Check edit window
    if review.created_at:
        edit_deadline = review.created_at + timedelta(minutes=EDIT_WINDOW_MINUTES)
        if datetime.now(timezone.utc) >= edit_deadline:
            raise HTTPException(status_code=400, detail="Edit window has expired")
    
    # Validate tags if provided
    if review_in.tags:
        from app.schemas.reviews import CLIENT_TAGS, HELPER_TAGS
        allowed_tags = CLIENT_TAGS if review.from_role == "client" else HELPER_TAGS
        for tag in review_in.tags:
            if tag not in allowed_tags:
                raise HTTPException(status_code=400, detail=f"Invalid tag: {tag}")
    
    # Update fields
    if review_in.comment is not None:
        review.comment = review_in.comment
    if review_in.tags is not None:
        review.tags = review_in.tags
    
    await db.commit()
    await db.refresh(review)
    
    return ReviewResponse(
        id=review.id,
        task_id=review.task_id,
        from_user_id=review.from_user_id,
        to_user_id=review.to_user_id,
        from_user_name=format_user_name(current_user),
        from_role=review.from_role,
        stars=review.stars,
        comment=review.comment,
        tags=review.tags or [],
        status=review.status,
        created_at=review.created_at,
    )


@router.get("/tasks/{task_id}/reviews")
async def get_task_reviews(
    task_id: int,
    current_user: User = Depends(deps.get_current_user),
    db: AsyncSession = Depends(deps.get_db)
):
    """
    Get all visible reviews for a task.
    """
    # Fetch reviews
    result = await db.execute(
        select(Review).where(Review.task_id == task_id)
    )
    reviews = result.scalars().all()
    
    visible_reviews = []
    for r in reviews:
        # Show if visible OR if it's my own review
        if r.status == ReviewStatus.VISIBLE.value or r.from_user_id == current_user.id:
            from_user = await db.get(User, r.from_user_id)
            visible_reviews.append(ReviewResponse(
                id=r.id,
                task_id=r.task_id,
                from_user_id=r.from_user_id,
                to_user_id=r.to_user_id,
                from_user_name=format_user_name(from_user),
                from_role=r.from_role,
                stars=r.stars,
                comment=r.comment,
                tags=r.tags or [],
                status=r.status,
                created_at=r.created_at,
            ))
    
    return visible_reviews
