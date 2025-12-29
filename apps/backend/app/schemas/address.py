from pydantic import BaseModel
from typing import Optional, Dict, Any

class AddressBase(BaseModel):
    name: str 
    address_line: str
    city: str
    postal_code: str
    country: str = "IT"
    latitude: Optional[str] = None
    longitude: Optional[str] = None
    is_default: bool = False
    details: Optional[Dict[str, Any]] = {}

class AddressCreate(AddressBase):
    pass

class AddressUpdate(BaseModel):
    name: Optional[str] = None
    address_line: Optional[str] = None
    city: Optional[str] = None
    postal_code: Optional[str] = None
    country: Optional[str] = None
    is_default: Optional[bool] = None
    details: Optional[Dict[str, Any]] = None

class AddressResponse(AddressBase):
    id: int
    user_id: int

    class Config:
        from_attributes = True
