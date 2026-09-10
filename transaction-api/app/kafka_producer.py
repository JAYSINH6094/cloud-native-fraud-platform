import json
from kafka import KafkaProducer


def serialize_transaction(transaction):
    return json.dumps(transaction, default=str).encode("utf-8")


producer = KafkaProducer(
    bootstrap_servers=["kafka:9092"],
    value_serializer=serialize_transaction
)


def publish_transaction(transaction: dict):
    producer.send("transactions", value=transaction)
    producer.flush()