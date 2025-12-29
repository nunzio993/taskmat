from fastapi import APIRouter, Depends, HTTPException, status

from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select
from sqlalchemy.orm import joinedload
from app.api import deps
from app.core import security, database
from app.models.user import User
from app.schemas.user import UserCreate, UserLogin, UserResponse

router = APIRouter()

@router.post("/register")
async def register(user_in: UserCreate, db: AsyncSession = Depends(database.get_db)):
    # Check if user exists
    result = await db.execute(select(User).where(User.email == user_in.email))
    if result.scalars().first():
        raise HTTPException(
            status_code=400,
            detail="The user with this email already exists in the system.",
        )
    
    user = User(
        email=user_in.email,
        hashed_password=security.get_password_hash(user_in.password),
        role=user_in.role,
        name=f"{user_in.first_name} {user_in.last_name}",
        is_available=False,
        preferences={},
        readiness_status={}
    )
    db.add(user)
    await db.commit()
    await db.refresh(user)
    
    # Manually construct response to avoid lazy loading issues with async ORM
    # response_model removed to avoid secondary validation error
    return UserResponse(
        id=user.id,
        email=user.email,
        role=user.role,
        name=user.name,
        phone=user.phone,
        bio=user.bio,
        hourly_rate=user.hourly_rate,
        is_available=user.is_available,
        skills=user.skills,
        document_status=user.document_status,
        preferences=user.preferences if user.preferences else {},
        readiness_status=user.readiness_status if user.readiness_status else {},
        addresses=[],
        payment_methods=[]
    )

@router.post("/login")
async def login(user_in: UserLogin, db: AsyncSession = Depends(database.get_db)):
    # Authenticate
    result = await db.execute(select(User).where(User.email == user_in.email))
    user = result.scalars().first()
    if not user or not security.verify_password(user_in.password, user.hashed_password):
        raise HTTPException(status_code=400, detail="Incorrect email or password")
    
    access_token = security.create_access_token(data={"sub": user.email})
    return {
        "access_token": access_token,
        "token_type": "bearer",
        "user": user # Simple return, usually sanitized via response_model
    }
