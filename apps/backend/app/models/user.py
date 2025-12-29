from sqlalchemy import Column, Integer, String, Boolean, Float, Text, JSON
from sqlalchemy.orm import relationship
from app.core.database import Base

class User(Base):
    __tablename__ = "users"

    id = Column(Integer, primary_key=True, index=True)
    email = Column(String, unique=True, index=True, nullable=False)
    hashed_password = Column(String, nullable=False)
    role = Column(String, nullable=False) # 'client' or 'helper'
    
    # Profile Info
    name = Column(String, nullable=True)
    phone = Column(String, nullable=True)
    bio = Column(Text, nullable=True)
    
    # Helper Specific
    hourly_rate = Column(Float, nullable=True)
    is_available = Column(Boolean, default=False)
    skills = Column(JSON, default=[]) # List of skill strings
    document_status = Column(String, default="unverified") # unverified, pending, verified, rejected
    
    # JSON Fields for Flexibility
    # { 'radius': 15.0, 'categories': [], 'min_price': 0, 'urgency': [], 'notifications': {} }
    preferences = Column(JSON, default={})
    
    # { 'stripe': bool, 'profile': bool }
    readiness_status = Column(JSON, default={})

    # Relationships (to match old model expectations)
    tasks_created = relationship("Task", back_populates="client")
    reviews_received = relationship("Review", foreign_keys="Review.to_user_id", back_populates="to_user")
    
    addresses = relationship("Address", back_populates="user", cascade="all, delete-orphan")
    payment_methods = relationship("PaymentMethod", back_populates="user", cascade="all, delete-orphan")
    documents = relationship("UserDocument", back_populates="user", cascade="all, delete-orphan")
