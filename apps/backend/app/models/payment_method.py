from sqlalchemy import Column, Integer, String, ForeignKey, Boolean
from sqlalchemy.orm import relationship
from app.core.database import Base

class PaymentMethod(Base):
    __tablename__ = "payment_methods"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    
    # For MVP we might just store a token or masked info
    card_brand = Column(String, nullable=False) # visa, mastercard
    last4 = Column(String, nullable=False)
    exp_month = Column(Integer, nullable=False)
    exp_year = Column(Integer, nullable=False)
    
    # Token from Stripe/PayPal
    provider_token_id = Column(String, unique=True, nullable=False)
    is_default = Column(Boolean, default=False)

    user = relationship("User", back_populates="payment_methods")
