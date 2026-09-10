from datetime import datetime

from pydantic import BaseModel


class TransactionCreate(BaseModel):
    user_id: str
    amount: float
    merchant: str
    location: str
    device_id: str


class TransactionResponse(BaseModel):
    transaction_id: str
    user_id: str
    amount: float
    merchant: str
    location: str
    device_id: str
    timestamp: datetime
    status: str