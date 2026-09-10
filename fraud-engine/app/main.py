from .rules import evaluate_transaction


def process_transaction(transaction: dict) -> str:
    """
    Process a transaction through the fraud detection rules.
    """

    return evaluate_transaction(
        amount=transaction["amount"],
        location=transaction["location"],
        device_id=transaction["device_id"]
    )


if __name__ == "__main__":
    transaction = {
        "amount": 3000,
        "location": "Ahmedabad",
        "device_id": "DEVICE003"
    }

    result = process_transaction(transaction)

    print("Fraud Detection Result:", result)