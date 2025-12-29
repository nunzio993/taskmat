from datetime import datetime
from typing import Optional, List
from pydantic import BaseModel
from app.models.models import TaskStatus

# Import Sub-Schemas
from .task_offers import TaskOfferResponse
from .chat import TaskThreadResponse
from .task_proofs import TaskProofResponse

class UserPublicProfile(BaseModel):
    id: int
    display_name: Optional[str] = "User"
    avatar_url: Optional[str] = None
    avg_rating: Optional[float] = 0.0
    review_count: int = 0

    class Config:
        from_attributes = True

class TaskBase(BaseModel):
    title: str
    description: Optional[str] = None
    category: Optional[str] = None
    price_cents: int
    urgency: Optional[str] = None
    
    # New Fields
    address_line: Optional[str] = None
    city: Optional[str] = None
    scheduled_at: Optional[datetime] = None

class TaskCreate(TaskBase):
    lat: float
    lon: float
    client_id: int 

class TaskUpdate(BaseModel):
    title: Optional[str] = None
    description: Optional[str] = None
    price_cents: Optional[int] = None
    status: Optional[str] = None
    version: Optional[int] = None # For optimistic locking check

class TaskOut(TaskBase):
    id: int
    client_id: int
    client: Optional[UserPublicProfile] = None
    status: TaskStatus
    
    # Financials
    selected_offer_id: Optional[int] = None
    
    # Optimization
    version: int
    
    # Timestamps
    created_at: datetime
    expires_at: Optional[datetime] = None
    assigned_at: Optional[datetime] = None
    started_at: Optional[datetime] = None
    completion_requested_at: Optional[datetime] = None
    completed_at: Optional[datetime] = None
    dispute_open_until: Optional[datetime] = None
    
    # Geo
    lat: float
    lon: float
    
    # Relationships (Optional based on query)
    offers: List[TaskOfferResponse] = []
    proofs: List[TaskProofResponse] = []
    # active_thread: Optional[TaskThreadResponse] = None

    class Config:
        from_attributes = True
