import mysql.connector

from .database import get_db_connection


def insert_transaction(
    transaction_id,
    user_id,
    amount,
    merchant,
    location,
    device_id
):
    connection = None
    cursor = None

    try:
        connection = get_db_connection()
        cursor = connection.cursor()

        query = """
            INSERT INTO transactions (
                transaction_id,
                user_id,
                amount,
                merchant,
                location,
                device_id
            )
            VALUES (%s, %s, %s, %s, %s, %s)
        """

        values = (
            transaction_id,
            user_id,
            amount,
            merchant,
            location,
            device_id
        )

        cursor.execute(query, values)
        connection.commit()

    finally:
        if cursor:
            cursor.close()

        if connection:
            connection.close()


def get_transaction_by_id(transaction_id):
    connection = None
    cursor = None

    try:
        connection = get_db_connection()
        cursor = connection.cursor(dictionary=True)

        query = """
            SELECT
                transaction_id,
                user_id,
                amount,
                merchant,
                location,
                device_id,
                timestamp,
                status
            FROM transactions
            WHERE transaction_id = %s
        """

        cursor.execute(query, (transaction_id,))
        return cursor.fetchone()

    finally:
        if cursor:
            cursor.close()

        if connection:
            connection.close()