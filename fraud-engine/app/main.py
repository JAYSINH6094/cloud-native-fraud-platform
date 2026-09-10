import json

from kafka import KafkaConsumer

from .rules import evaluate_transaction


consumer = KafkaConsumer(
    "transactions",
    bootstrap_servers=["kafka:9092"],
    group_id="fraud-engine",
    value_deserializer=lambda value: json.loads(value.decode("utf-8"))
)


def process_transaction(transaction: dict) -> str:
    return evaluate_transaction(
        amount=float(transaction["amount"]),
        location=transaction["location"],
        device_id=transaction["device_id"]
    )


if __name__ == "__main__":
    print("Fraud Engine started...")

    for message in consumer:
        transaction = message.value

        result = process_transaction(transaction)

        print(
            f"Transaction: {transaction['transaction_id']} | "
            f"Result: {result}"
        )