from fastapi import APIRouter, Depends, HTTPException, status

from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from typing import List

from app.api import deps
from app.core import database
from app.models.user import User
from app.models.user_document import UserDocument
from app.schemas.user import UserResponse, UserUpdate
from app.schemas.user_document import UserDocumentCreate, UserDocumentResponse

router = APIRouter()

@router.post("/documents", response_model=UserDocumentResponse)
async def upload_document(
    doc_in: UserDocumentCreate,
    current_user: User = Depends(deps.get_current_user),
    db: AsyncSession = Depends(database.get_db),
):
    # Mock upload: in real scenario, we'd handle file upload here or get signed URL
    new_doc = UserDocument(
        user_id=current_user.id,
        type=doc_in.type,
        file_url=doc_in.file_url,
        status="pending"
    )
    db.add(new_doc)
    await db.commit()
    await db.refresh(new_doc)
    return new_doc

@router.get("/documents", response_model=List[UserDocumentResponse])
async def list_documents(
    current_user: User = Depends(deps.get_current_user),
    db: AsyncSession = Depends(database.get_db),
):
    result = await db.execute(select(UserDocument).where(UserDocument.user_id == current_user.id))
    return result.scalars().all()

@router.patch("/profile")
async def update_helper_profile(
    profile_in: UserUpdate,
    current_user: User = Depends(deps.get_current_user),
    db: AsyncSession = Depends(database.get_db),
):
    # This reuses UserUpdate schema but focused on helper fields
    # We could restrict valid fields here if needed
    
    if profile_in.is_available is not None:
        current_user.is_available = profile_in.is_available
    if profile_in.hourly_rate is not None:
        current_user.hourly_rate = profile_in.hourly_rate
    if profile_in.bio is not None:
        current_user.bio = profile_in.bio
    if profile_in.skills is not None:
        current_user.skills = profile_in.skills
        
    db.add(current_user)
    await db.commit()
    await db.refresh(current_user)
    return UserResponse(
        id=current_user.id,
        email=current_user.email,
        role=current_user.role,
        name=current_user.name,
        phone=current_user.phone,
        bio=current_user.bio,
        hourly_rate=current_user.hourly_rate,
        is_available=current_user.is_available,
        skills=current_user.skills,
        document_status=current_user.document_status,
        preferences=current_user.preferences if current_user.preferences else {},
        readiness_status=current_user.readiness_status if current_user.readiness_status else {},
        addresses=[],
        payment_methods=[]
    )

@router.post("/verify")
async def request_verification(
    current_user: User = Depends(deps.get_current_user),
    db: AsyncSession = Depends(database.get_db),
):
    # Check if docs exist
    result = await db.execute(select(UserDocument).where(UserDocument.user_id == current_user.id))
    docs = result.scalars().all()
    
    if not docs:
         raise HTTPException(status_code=400, detail="Please upload at least one document before requesting verification.")
         
    current_user.document_status = "pending"
    db.add(current_user)
    await db.commit()
    
    return {"status": "pending", "message": "Verification request submitted"}
