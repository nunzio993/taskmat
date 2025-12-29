from pydantic import BaseModel
from datetime import datetime

class TaskProofBase(BaseModel):
    kind: str
    storage_key: str

class TaskProofCreate(TaskProofBase):
    pass

class TaskProofResponse(TaskProofBase):
    id: int
    task_id: int
    uploader_id: int
    created_at: datetime

    class Config:
        from_attributes = True
