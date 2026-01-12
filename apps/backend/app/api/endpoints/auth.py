from fastapi import APIRouter, Depends, HTTPException, status

from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select
from sqlalchemy.orm import joinedload
from app.api import deps
from app.core import security, database
from app.models.user import User
from app.schemas.user import UserCreate, UserLogin, UserResponse
from pydantic import BaseModel

router = APIRouter()

class RefreshTokenRequest(BaseModel):
    refresh_token: str

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
    
    if not user:
        raise HTTPException(status_code=400, detail="Incorrect email or password")
    
    # Use async password verification to avoid blocking
    password_valid = await security.verify_password_async(user_in.password, user.hashed_password)
    
    if not password_valid:
        raise HTTPException(status_code=400, detail="Incorrect email or password")
    
    access_token = security.create_access_token(data={"sub": user.email})
    refresh_token = security.create_refresh_token(data={"sub": user.email})
    
    return {
        "access_token": access_token,
        "refresh_token": refresh_token,
        "token_type": "bearer",
        "user": user
    }

@router.post("/refresh")
async def refresh_token(request: RefreshTokenRequest, db: AsyncSession = Depends(database.get_db)):
    """
    Exchange a valid refresh token for a new access token.
    """
    try:
        payload = security.decode_token(request.refresh_token)
        
        # Verify it's a refresh token
        if payload.get("type") != "refresh":
            raise HTTPException(status_code=401, detail="Invalid token type")
        
        email = payload.get("sub")
        if not email:
            raise HTTPException(status_code=401, detail="Invalid token")
        
        # Verify user still exists
        result = await db.execute(select(User).where(User.email == email))
        user = result.scalars().first()
        if not user:
            raise HTTPException(status_code=401, detail="User not found")
        
        # Issue new access token
        new_access_token = security.create_access_token(data={"sub": email})
        
        return {
            "access_token": new_access_token,
            "token_type": "bearer"
        }
    except Exception as e:
        raise HTTPException(status_code=401, detail="Invalid or expired refresh token")

