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
    min_price_cents: int  # service_floor_cents - minimum task price for this category

    class Config:
        from_attributes = True


@router.get("", response_model=List[CategoryPublic])
async def list_enabled_categories(
    db: AsyncSession = Depends(database.get_db)
):
    """
    List all enabled categories with their minimum price.
    Public endpoint - no auth required.
    Used for task creation and helper registration.
    """
    result = await db.execute(
        select(CategorySettings)
        .where(CategorySettings.enabled == True)
        .order_by(CategorySettings.display_name)
    )
    categories = result.scalars().all()
    
    # Map to response with min_price_cents
    return [
        CategoryPublic(
            slug=c.slug,
            display_name=c.display_name,
            min_price_cents=c.service_floor_cents
        )
        for c in categories
    ]

