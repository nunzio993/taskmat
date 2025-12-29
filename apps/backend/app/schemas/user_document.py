from datetime import datetime
from pydantic import BaseModel
from typing import Optional

class UserDocumentBase(BaseModel):
    type: str
    file_url: str

class UserDocumentCreate(UserDocumentBase):
    pass

class UserDocumentResponse(UserDocumentBase):
    id: int
    user_id: int
    status: str
    rejection_reason: Optional[str] = None
    created_at: datetime
    verified_at: Optional[datetime] = None

    class Config:
        from_attributes = True
