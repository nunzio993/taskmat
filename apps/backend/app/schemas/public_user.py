from pydantic import BaseModel
from typing import Optional, List, Dict, Any

class PublicUserStats(BaseModel):
    tasks_completed: int = 0 # Helper: jobs done, Client: tasks posted & done
    reviews_count: int = 0
    average_rating: float = 0.0
    cancel_rate_label: str = "Reliable" # Simple bucket: Reliable, High, etc.

class PublicUserResponse(BaseModel):
    id: int
    name: Optional[str] = None
    role: str
    bio: Optional[str] = None
    languages: List[str] = []
    
    # Helper specifics (conditionally hidden if not helper, but schema can hold them)
    hourly_rate: Optional[float] = None
    skills: List[str] = []
    
    # Stats
    stats: PublicUserStats
    
    # Explicit privacy handling:
    # No email, phone, location, address, payment_methods
    
    class Config:
        from_attributes = True
