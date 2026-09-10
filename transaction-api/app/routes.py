import uuid

from fastapi import APIRouter, HTTPException

from .schemas import TransactionCreate, TransactionResponse
from .crud import insert_transaction, get_transaction_by_id

router = APIRouter()


@router.post("/transactions", response_model=TransactionResponse)
def create_transaction(transaction: TransactionCreate):

    transaction_id = str(uuid.uuid4())

    insert_transaction(
        transaction_id=transaction_id,
        user_id=transaction.user_id,
        amount=transaction.amount,
        merchant=transaction.merchant,
        location=transaction.location,
        device_id=transaction.device_id
    )

    saved_transaction = get_transaction_by_id(transaction_id)

    return saved_transaction


@router.get("/transactions/{transaction_id}")
def get_transaction(transaction_id: str):

    transaction = get_transaction_by_id(transaction_id)

    if transaction is None:
        raise HTTPException(
            status_code=404,
            detail="Transaction not found"
        )

    return transaction