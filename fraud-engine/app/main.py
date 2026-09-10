import json
from kafka.serializer import Deserializer
from kafka import KafkaConsumer
from .database import update_transaction_status
from .rules import evaluate_transaction

class TransactionDeserializer(Deserializer):
    def deserialize(self, data):
        return json.loads(data.decode("utf-8"))


consumer = KafkaConsumer(
    "transactions",
    bootstrap_servers=["kafka:9092"],
    group_id="fraud-engine",
    value_deserializer=TransactionDeserializer()
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

        update_transaction_status(
            transaction["transaction_id"],
            result
        )

        print(
            f"Transaction: {transaction['transaction_id']} | "
            f"Result: {result}"
        )