import os

import mysql.connector


def get_required_env(name: str) -> str:
    value = os.getenv(name)

    if not value:
        raise RuntimeError(
            f"Required environment variable is missing: {name}"
        )

    return value


DB_HOST = get_required_env("DB_HOST")
DB_PORT = int(os.getenv("DB_PORT", "3306"))
DB_USER = get_required_env("DB_USER")
DB_PASSWORD = get_required_env("DB_PASSWORD")
DB_NAME = get_required_env("DB_NAME")


def get_db_connection():
    return mysql.connector.connect(
        host=DB_HOST,
        port=DB_PORT,
        user=DB_USER,
        password=DB_PASSWORD,
        database=DB_NAME,
    )


def update_transaction_status(
    transaction_id: str,
    status: str,
):
    connection = None
    cursor = None

    try:
        connection = get_db_connection()
        cursor = connection.cursor()

        query = """
            UPDATE transactions
            SET status = %s
            WHERE transaction_id = %s
        """

        cursor.execute(
            query,
            (status, transaction_id),
        )

        connection.commit()

    finally:
        if cursor:
            cursor.close()

        if connection:
            connection.close()