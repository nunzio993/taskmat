from pydantic import BaseModel, EmailStr, field_validator
from typing import Optional, List, Dict, Any
from app.schemas.address import AddressResponse
from app.schemas.payment_method import PaymentMethodResponse
import re

class UserBase(BaseModel):
    email: EmailStr
    role: str
    name: Optional[str] = None

class UserCreate(UserBase):
    password: str
    first_name: str
    last_name: str
    
    @field_validator('password')
    @classmethod
    def validate_password(cls, v: str) -> str:
        if len(v) < 8:
            raise ValueError('Password must be at least 8 characters')
        if not re.search(r'[a-zA-Z]', v):
            raise ValueError('Password must contain at least one letter')
        if not re.search(r'\d', v):
            raise ValueError('Password must contain at least one number')
        return v

class UserLogin(BaseModel):
    email: EmailStr
    password: str

class UserUpdate(BaseModel):
    name: Optional[str] = None
    phone: Optional[str] = None
    bio: Optional[str] = None
    languages: Optional[List[str]] = None
    hourly_rate: Optional[float] = None
    is_available: Optional[bool] = None
    skills: Optional[List[str]] = None
    preferences: Optional[Dict[str, Any]] = None
    readiness_status: Optional[Dict[str, bool]] = None

class UserResponse(UserBase):
    id: int
    phone: Optional[str] = None
    bio: Optional[str] = None
    avatar_url: Optional[str] = None
    languages: List[str] = ['Italiano']
    hourly_rate: Optional[float] = None
    is_available: bool
    skills: Optional[List[str]] = []
    document_status: Optional[str] = "unverified"
    preferences: Dict[str, Any] = {}
    readiness_status: Dict[str, bool] = {}
    
    # We might not want to return these always, but for /profile/me it's fine
    addresses: List[AddressResponse] = []
    payment_methods: List[PaymentMethodResponse] = []

    class Config:
        from_attributes = True
