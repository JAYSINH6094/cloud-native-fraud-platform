import json
import os

from kafka import KafkaProducer


KAFKA_BOOTSTRAP_SERVERS = os.getenv(
    "KAFKA_BOOTSTRAP_SERVERS",
    "kafka:9092",
)

KAFKA_TOPIC = os.getenv(
    "KAFKA_TOPIC",
    "transactions",
)


def serialize_transaction(transaction):
    return json.dumps(
        transaction,
        default=str,
    ).encode("utf-8")


producer = KafkaProducer(
    bootstrap_servers=[KAFKA_BOOTSTRAP_SERVERS],
    value_serializer=serialize_transaction,
)


def publish_transaction(transaction: dict):
    producer.send(
        KAFKA_TOPIC,
        value=transaction,
    )

    producer.flush()
