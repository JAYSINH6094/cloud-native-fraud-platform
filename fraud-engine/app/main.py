import json
import os

from kafka import KafkaConsumer

from .database import update_transaction_status
from .rules import evaluate_transaction


KAFKA_BOOTSTRAP_SERVERS = os.getenv(
    "KAFKA_BOOTSTRAP_SERVERS",
    "kafka:9092",
)

KAFKA_TOPIC = os.getenv(
    "KAFKA_TOPIC",
    "transactions",
)

KAFKA_GROUP_ID = os.getenv(
    "KAFKA_GROUP_ID",
    "fraud-engine",
)


def deserialize_transaction(data):
    return json.loads(
        data.decode("utf-8")
    )


consumer = KafkaConsumer(
    KAFKA_TOPIC,
    bootstrap_servers=[KAFKA_BOOTSTRAP_SERVERS],
    group_id=KAFKA_GROUP_ID,
    value_deserializer=deserialize_transaction,
)


def process_transaction(transaction: dict) -> str:
    return evaluate_transaction(
        amount=float(transaction["amount"]),
        location=transaction["location"],
        device_id=transaction["device_id"],
    )


if __name__ == "__main__":
    print("Fraud Engine started...")

    for message in consumer:
        transaction = message.value

        result = process_transaction(transaction)

        update_transaction_status(
            transaction["transaction_id"],
            result,
        )

        print(
            f"Transaction: {transaction['transaction_id']} | "
            f"Result: {result}"
        )
