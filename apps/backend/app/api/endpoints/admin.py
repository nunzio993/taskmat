from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, func
from typing import List

from app.core import database
from app.models.user import User
from app.models.models import SystemSetting, Task, Payment, TaskStatus
from app.models.category_settings import CategorySettings, CategorySettingsVersion, GlobalSettingsVersion
from app.schemas.admin import (
    CategorySettingsCreate,
    CategorySettingsUpdate,
    CategorySettingsResponse,
    CategorySettingsVersionResponse,
    GlobalSettingUpdate,
    GlobalSettingResponse,
    GlobalSettingsVersionResponse,
    AdminUserResponse,
)
from app.api.deps import get_current_user

router = APIRouter(prefix="/admin", tags=["admin"])


# ============================================
# ACCESS CONTROL
# ============================================

async def require_admin(
    current_user: User = Depends(get_current_user)
) -> User:
    """Require user to be an admin"""
    if not current_user.is_admin:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Admin access required"
        )
    return current_user


async def require_super_admin(
    current_user: User = Depends(require_admin)
) -> User:
    """Require user to be a super admin"""
    if current_user.admin_role != "SUPER_ADMIN":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Super Admin access required"
        )
    return current_user


# ============================================
# CATEGORY SETTINGS ENDPOINTS
# ============================================

@router.get("/categories", response_model=List[CategorySettingsResponse])
async def list_categories(
    admin: User = Depends(require_admin),
    db: AsyncSession = Depends(database.get_db)
):
    """List all category settings"""
    result = await db.execute(
        select(CategorySettings).order_by(CategorySettings.display_name)
    )
    return result.scalars().all()


@router.get("/categories/{slug}", response_model=CategorySettingsResponse)
async def get_category(
    slug: str,
    admin: User = Depends(require_admin),
    db: AsyncSession = Depends(database.get_db)
):
    """Get a single category by slug"""
    result = await db.execute(
        select(CategorySettings).where(CategorySettings.slug == slug)
    )
    category = result.scalars().first()
    if not category:
        raise HTTPException(status_code=404, detail="Category not found")
    return category


@router.post("/categories", response_model=CategorySettingsResponse, status_code=201)
async def create_category(
    data: CategorySettingsCreate,
    admin: User = Depends(require_super_admin),
    db: AsyncSession = Depends(database.get_db)
):
    """Create a new category (Super Admin only)"""
    # Check if slug already exists
    existing = await db.execute(
        select(CategorySettings).where(CategorySettings.slug == data.slug)
    )
    if existing.scalars().first():
        raise HTTPException(status_code=400, detail="Category slug already exists")
    
    category = CategorySettings(**data.model_dump())
    db.add(category)
    await db.commit()
    await db.refresh(category)
    return category


@router.put("/categories/{slug}", response_model=CategorySettingsResponse)
async def update_category(
    slug: str,
    data: CategorySettingsUpdate,
    admin: User = Depends(require_admin),
    db: AsyncSession = Depends(database.get_db)
):
    """Update category settings with audit trail"""
    result = await db.execute(
        select(CategorySettings).where(CategorySettings.slug == slug)
    )
    category = result.scalars().first()
    if not category:
        raise HTTPException(status_code=404, detail="Category not found")
    
    # Create version snapshot before update
    snapshot = {
        "slug": category.slug,
        "display_name": category.display_name,
        "enabled": category.enabled,
        "fee_percent": float(category.fee_percent),
        "fee_min_cents": category.fee_min_cents,
        "fee_max_cents": category.fee_max_cents,
        "service_floor_cents": category.service_floor_cents,
        "is_variable_cost": category.is_variable_cost,
        "expense_cap_min_cents": category.expense_cap_min_cents,
        "expense_cap_max_cents": category.expense_cap_max_cents,
        "expense_receipt_required": category.expense_receipt_required,
    }
    
    version = CategorySettingsVersion(
        category_id=category.id,
        value_json=snapshot,
        changed_by=admin.id,
        reason=data.reason
    )
    db.add(version)
    
    # Apply updates
    update_data = data.model_dump(exclude={'reason'}, exclude_unset=True)
    for field, value in update_data.items():
        setattr(category, field, value)
    
    await db.commit()
    await db.refresh(category)
    return category


@router.get("/categories/{slug}/history", response_model=List[CategorySettingsVersionResponse])
async def get_category_history(
    slug: str,
    admin: User = Depends(require_admin),
    db: AsyncSession = Depends(database.get_db)
):
    """Get change history for a category"""
    # Get category first
    cat_result = await db.execute(
        select(CategorySettings).where(CategorySettings.slug == slug)
    )
    category = cat_result.scalars().first()
    if not category:
        raise HTTPException(status_code=404, detail="Category not found")
    
    result = await db.execute(
        select(CategorySettingsVersion)
        .where(CategorySettingsVersion.category_id == category.id)
        .order_by(CategorySettingsVersion.created_at.desc())
        .limit(50)
    )
    return result.scalars().all()


# ============================================
# GLOBAL SETTINGS ENDPOINTS
# ============================================

@router.get("/settings", response_model=List[GlobalSettingResponse])
async def list_global_settings(
    admin: User = Depends(require_admin),
    db: AsyncSession = Depends(database.get_db)
):
    """List all global settings"""
    result = await db.execute(
        select(SystemSetting).order_by(SystemSetting.key)
    )
    return result.scalars().all()


@router.get("/settings/{key}", response_model=GlobalSettingResponse)
async def get_global_setting(
    key: str,
    admin: User = Depends(require_admin),
    db: AsyncSession = Depends(database.get_db)
):
    """Get a single global setting"""
    result = await db.execute(
        select(SystemSetting).where(SystemSetting.key == key)
    )
    setting = result.scalars().first()
    if not setting:
        raise HTTPException(status_code=404, detail="Setting not found")
    return setting


@router.put("/settings/{key}", response_model=GlobalSettingResponse)
async def update_global_setting(
    key: str,
    data: GlobalSettingUpdate,
    admin: User = Depends(require_admin),
    db: AsyncSession = Depends(database.get_db)
):
    """Update a global setting with audit trail"""
    result = await db.execute(
        select(SystemSetting).where(SystemSetting.key == key)
    )
    setting = result.scalars().first()
    if not setting:
        raise HTTPException(status_code=404, detail="Setting not found")
    
    # Create version for audit
    version = GlobalSettingsVersion(
        key=key,
        old_value=setting.value,
        new_value=data.value,
        changed_by=admin.id,
        reason=data.reason
    )
    db.add(version)
    
    # Update value
    setting.value = data.value
    
    await db.commit()
    await db.refresh(setting)
    return setting


@router.get("/settings-history", response_model=List[GlobalSettingsVersionResponse])
async def get_global_settings_history(
    admin: User = Depends(require_admin),
    db: AsyncSession = Depends(database.get_db)
):
    """Get change history for all global settings"""
    result = await db.execute(
        select(GlobalSettingsVersion)
        .order_by(GlobalSettingsVersion.created_at.desc())
        .limit(100)
    )
    return result.scalars().all()


# ============================================
# ADMIN INFO
# ============================================

@router.get("/me", response_model=AdminUserResponse)
async def get_admin_info(
    admin: User = Depends(require_admin)
):
    """Get current admin user info"""
    return admin


# ============================================
# DASHBOARD STATS
# ============================================

@router.get("/stats")
async def get_dashboard_stats(
    admin: User = Depends(require_admin),
    db: AsyncSession = Depends(database.get_db)
):
    """Get dashboard statistics"""
    # Total users
    users_result = await db.execute(select(func.count(User.id)))
    total_users = users_result.scalar() or 0
    
    # Tasks completed
    completed_result = await db.execute(
        select(func.count(Task.id)).where(Task.status == TaskStatus.COMPLETED)
    )
    completed_tasks = completed_result.scalar() or 0
    
    # Total revenue (sum of app_fee_cents from captured payments)
    revenue_result = await db.execute(
        select(func.sum(Payment.app_fee_cents)).where(Payment.captured_at.isnot(None))
    )
    total_revenue_cents = revenue_result.scalar() or 0
    
    # Active categories
    categories_result = await db.execute(
        select(func.count(CategorySettings.id)).where(CategorySettings.enabled == True)
    )
    active_categories = categories_result.scalar() or 0
    
    # Helpers count
    helpers_result = await db.execute(
        select(func.count(User.id)).where(User.role == 'helper')
    )
    total_helpers = helpers_result.scalar() or 0
    
    # Pending tasks
    pending_result = await db.execute(
        select(func.count(Task.id)).where(Task.status == TaskStatus.PENDING)
    )
    pending_tasks = pending_result.scalar() or 0
    
    return {
        "total_users": total_users,
        "total_helpers": total_helpers,
        "completed_tasks": completed_tasks,
        "pending_tasks": pending_tasks,
        "total_revenue_cents": total_revenue_cents,
        "active_categories": active_categories,
    }
