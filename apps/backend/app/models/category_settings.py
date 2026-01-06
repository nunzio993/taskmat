from sqlalchemy import Column, Integer, String, Boolean, Numeric, Text, ForeignKey, DateTime, JSON
from sqlalchemy.sql import func
from app.core.database import Base


class CategorySettings(Base):
    """Per-category fee and policy settings"""
    __tablename__ = "category_settings"

    id = Column(Integer, primary_key=True, index=True)
    slug = Column(String(50), unique=True, nullable=False, index=True)  # 'pulizie', 'traslochi'
    display_name = Column(String(100), nullable=False)
    enabled = Column(Boolean, default=True)
    
    # Fee structure
    fee_percent = Column(Numeric(5, 2), nullable=False)  # e.g. 15.00 = 15%
    fee_min_cents = Column(Integer, nullable=False, default=100)  # minimum €1
    fee_max_cents = Column(Integer, nullable=True)  # optional cap
    
    # Service constraints
    service_floor_cents = Column(Integer, nullable=False, default=1000)  # min €10
    
    # Variable cost tasks (materials/expenses)
    is_variable_cost = Column(Boolean, default=False)
    expense_cap_min_cents = Column(Integer, nullable=True)
    expense_cap_max_cents = Column(Integer, nullable=True)
    expense_receipt_required = Column(Boolean, default=True)
    
    # Timestamps
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())


class CategorySettingsVersion(Base):
    """Audit trail for category settings changes"""
    __tablename__ = "category_settings_versions"

    id = Column(Integer, primary_key=True, index=True)
    category_id = Column(Integer, ForeignKey("category_settings.id"), nullable=False, index=True)
    value_json = Column(JSON, nullable=False)  # Full snapshot of settings
    changed_by = Column(Integer, ForeignKey("users.id"), nullable=False)
    reason = Column(Text, nullable=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now())


class GlobalSettingsVersion(Base):
    """Audit trail for global settings changes"""
    __tablename__ = "global_settings_versions"

    id = Column(Integer, primary_key=True, index=True)
    key = Column(String, nullable=False, index=True)
    old_value = Column(JSON, nullable=True)
    new_value = Column(JSON, nullable=False)
    changed_by = Column(Integer, ForeignKey("users.id"), nullable=False)
    reason = Column(Text, nullable=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
