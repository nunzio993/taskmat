from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from typing import List
from pydantic import BaseModel

from app.core import database
from app.models.category_settings import CategorySettings

router = APIRouter(prefix="/categories", tags=["categories"])


class CategoryPublic(BaseModel):
    """Public category info for clients/helpers"""
    slug: str
    display_name: str

    class Config:
        from_attributes = True


@router.get("", response_model=List[CategoryPublic])
async def list_enabled_categories(
    db: AsyncSession = Depends(database.get_db)
):
    """
    List all enabled categories.
    Public endpoint - no auth required.
    Used for task creation and helper registration.
    """
    result = await db.execute(
        select(CategorySettings)
        .where(CategorySettings.enabled == True)
        .order_by(CategorySettings.display_name)
    )
    return result.scalars().all()
