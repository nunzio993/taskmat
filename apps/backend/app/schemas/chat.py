from typing import Optional, List, Dict, Any
from datetime import datetime
from pydantic import BaseModel
from app.models.models import MessageType

class TaskMessageBase(BaseModel):
    body: Optional[str] = None
    type: MessageType = MessageType.TEXT
    payload: Optional[Dict[str, Any]] = None

class TaskMessageCreate(TaskMessageBase):
    pass

class TaskMessageResponse(TaskMessageBase):
    id: int
    thread_id: int
    sender_id: int
    created_at: datetime
    read_at: Optional[datetime] = None

    class Config:
        from_attributes = True

class TaskThreadBase(BaseModel):
    pass

class TaskThreadResponse(TaskThreadBase):
    id: int
    task_id: int
    client_id: int
    helper_id: int
    created_at: datetime
    messages: List[TaskMessageResponse] = []
    
    # Helper details for display
    helper_name: Optional[str] = None
    helper_avatar_url: Optional[str] = None
    helper_rating: Optional[float] = None
    helper_review_count: Optional[int] = None

    class Config:
        from_attributes = True
