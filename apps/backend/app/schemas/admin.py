from pydantic import BaseModel, Field, field_validator
from typing import Optional, List
from datetime import datetime
from decimal import Decimal


# ============================================
# CATEGORY SETTINGS SCHEMAS
# ============================================

class CategorySettingsBase(BaseModel):
    """Base schema for category settings"""
    display_name: str = Field(..., min_length=1, max_length=100)
    enabled: bool = True
    fee_percent: Decimal = Field(..., ge=0, le=100)
    fee_min_cents: int = Field(100, ge=0)
    fee_max_cents: Optional[int] = Field(None, ge=0)
    service_floor_cents: int = Field(1000, ge=0)
    is_variable_cost: bool = False
    expense_cap_min_cents: Optional[int] = Field(None, ge=0)
    expense_cap_max_cents: Optional[int] = Field(None, ge=0)
    expense_receipt_required: bool = True

    @field_validator('fee_max_cents')
    @classmethod
    def fee_max_gte_min(cls, v, info):
        if v is not None and 'fee_min_cents' in info.data:
            if v < info.data['fee_min_cents']:
                raise ValueError('fee_max_cents must be >= fee_min_cents')
        return v

    @field_validator('expense_cap_max_cents')
    @classmethod
    def expense_max_gte_min(cls, v, info):
        if v is not None and info.data.get('expense_cap_min_cents') is not None:
            if v < info.data['expense_cap_min_cents']:
                raise ValueError('expense_cap_max_cents must be >= expense_cap_min_cents')
        return v


class CategorySettingsCreate(CategorySettingsBase):
    """Schema for creating a new category"""
    slug: str = Field(..., min_length=1, max_length=50, pattern=r'^[a-z0-9-]+$')


class CategorySettingsUpdate(BaseModel):
    """Schema for updating category settings - all fields optional"""
    display_name: Optional[str] = Field(None, min_length=1, max_length=100)
    enabled: Optional[bool] = None
    fee_percent: Optional[Decimal] = Field(None, ge=0, le=100)
    fee_min_cents: Optional[int] = Field(None, ge=0)
    fee_max_cents: Optional[int] = Field(None, ge=0)
    service_floor_cents: Optional[int] = Field(None, ge=0)
    is_variable_cost: Optional[bool] = None
    expense_cap_min_cents: Optional[int] = Field(None, ge=0)
    expense_cap_max_cents: Optional[int] = Field(None, ge=0)
    expense_receipt_required: Optional[bool] = None
    
    # Required for audit
    reason: str = Field(..., min_length=5, max_length=500)


class CategorySettingsResponse(BaseModel):
    """Response schema for category settings"""
    id: int
    slug: str
    display_name: str
    enabled: bool
    fee_percent: Decimal
    fee_min_cents: int
    fee_max_cents: Optional[int]
    service_floor_cents: int
    is_variable_cost: bool
    expense_cap_min_cents: Optional[int]
    expense_cap_max_cents: Optional[int]
    expense_receipt_required: bool
    created_at: datetime
    updated_at: Optional[datetime]

    class Config:
        from_attributes = True


class CategorySettingsVersionResponse(BaseModel):
    """Response for category settings history"""
    id: int
    category_id: int
    value_json: dict
    changed_by: int
    reason: str
    created_at: datetime

    class Config:
        from_attributes = True


# ============================================
# GLOBAL SETTINGS SCHEMAS
# ============================================

class GlobalSettingUpdate(BaseModel):
    """Schema for updating a global setting"""
    value: dict | str | int | bool | float
    reason: str = Field(..., min_length=5, max_length=500)


class GlobalSettingResponse(BaseModel):
    """Response schema for global setting"""
    key: str
    value: dict | str | int | bool | float
    description: Optional[str]

    class Config:
        from_attributes = True


class GlobalSettingsVersionResponse(BaseModel):
    """Response for global settings history"""
    id: int
    key: str
    old_value: Optional[dict | str | int | bool | float]
    new_value: dict | str | int | bool | float
    changed_by: int
    reason: str
    created_at: datetime

    class Config:
        from_attributes = True


# ============================================
# ADMIN USER SCHEMAS
# ============================================

class AdminUserResponse(BaseModel):
    """Admin user info"""
    id: int
    email: str
    name: Optional[str]
    is_admin: bool
    admin_role: Optional[str]

    class Config:
        from_attributes = True
