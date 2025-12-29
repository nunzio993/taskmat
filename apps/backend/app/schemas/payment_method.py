from pydantic import BaseModel
from typing import Optional

class PaymentMethodBase(BaseModel):
    card_brand: str
    last4: str
    exp_month: int
    exp_year: int
    is_default: bool = False

class PaymentMethodCreate(PaymentMethodBase):
    provider_token_id: str

class PaymentMethodResponse(PaymentMethodBase):
    id: int
    user_id: int

    class Config:
        from_attributes = True
