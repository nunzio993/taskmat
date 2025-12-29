from sqlalchemy import Column, Integer, String, ForeignKey, Boolean
from sqlalchemy.dialects.postgresql import JSONB
from sqlalchemy.orm import relationship
from app.core.database import Base

class Address(Base):
    __tablename__ = "addresses"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    name = Column(String, nullable=False)  # "Home", "Work"
    address_line = Column(String, nullable=False)
    city = Column(String, nullable=False)
    postal_code = Column(String, nullable=False)
    country = Column(String, default="IT")
    latitude = Column(String, nullable=True) # Keeping string for simplicity or Float
    longitude = Column(String, nullable=True) 
    is_default = Column(Boolean, default=False)
    
    # Extra details (floor, intercom, etc)
    details = Column(JSONB, default={})

    user = relationship("User", back_populates="addresses")
