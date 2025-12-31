from typing import Optional
from datetime import datetime
from pydantic import BaseModel
from app.models.models import OfferStatus

class TaskOfferBase(BaseModel):
    price_cents: int
    message: Optional[str] = None

class TaskOfferCreate(TaskOfferBase):
    pass

class TaskOfferUpdate(BaseModel):
    price_cents: Optional[int] = None
    message: Optional[str] = None
    status: Optional[str] = None

class TaskOfferResponse(TaskOfferBase):
    id: int
    task_id: int
    helper_id: int
    status: str
    created_at: datetime
    updated_at: Optional[datetime] = None
    
    # Helper Details
    helper_name: Optional[str] = None
    helper_avatar_url: Optional[str] = None
    helper_rating: Optional[float] = None

    class Config:
        from_attributes = True
