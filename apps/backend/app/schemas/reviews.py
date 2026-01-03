from datetime import datetime
from typing import Optional, List
from pydantic import BaseModel, field_validator


# Tag whitelists by role
CLIENT_TAGS = ["Professionale", "Puntuale", "Cordiale", "Veloce", "Affidabile", "Comunicativo"]
HELPER_TAGS = ["Chiaro", "Rispettoso", "Disponibile", "Pagamento rapido", "Collaborativo"]


class ReviewCreate(BaseModel):
    """Schema for creating a review."""
    stars: int
    comment: Optional[str] = None
    tags: Optional[List[str]] = None

    @field_validator('stars')
    @classmethod
    def validate_stars(cls, v):
        if v < 1 or v > 5:
            raise ValueError('Stars must be between 1 and 5')
        return v

    @field_validator('comment')
    @classmethod
    def validate_comment(cls, v):
        if v is not None:
            if len(v) < 10:
                raise ValueError('Comment must be at least 10 characters if provided')
            if len(v) > 500:
                raise ValueError('Comment must be at most 500 characters')
        return v

    @field_validator('tags')
    @classmethod
    def validate_tags(cls, v):
        if v is not None and len(v) > 3:
            raise ValueError('Maximum 3 tags allowed')
        return v


class ReviewUpdate(BaseModel):
    """Schema for updating a review (within time window)."""
    comment: Optional[str] = None
    tags: Optional[List[str]] = None

    @field_validator('comment')
    @classmethod
    def validate_comment(cls, v):
        if v is not None:
            if len(v) < 10:
                raise ValueError('Comment must be at least 10 characters if provided')
            if len(v) > 500:
                raise ValueError('Comment must be at most 500 characters')
        return v

    @field_validator('tags')
    @classmethod
    def validate_tags(cls, v):
        if v is not None and len(v) > 3:
            raise ValueError('Maximum 3 tags allowed')
        return v


class ReviewResponse(BaseModel):
    """Schema for review response."""
    id: int
    task_id: int
    from_user_id: int
    to_user_id: int
    from_user_name: Optional[str] = None
    from_role: str
    stars: int
    comment: Optional[str] = None
    tags: Optional[List[str]] = None
    status: str
    created_at: datetime

    class Config:
        from_attributes = True


class ReviewStatusResponse(BaseModel):
    """Schema for review status on a task."""
    task_id: int
    task_status: str
    can_review: bool  # True if user can submit a review
    has_reviewed: bool  # True if user already submitted
    other_reviewed: bool  # True if other party submitted (for blind mode)
    reviews_visible: bool  # True if reviews are visible (both submitted or blind off)
    my_review: Optional[ReviewResponse] = None
    other_review: Optional[ReviewResponse] = None  # Only if visible
    edit_allowed: bool = False  # True if within edit window
