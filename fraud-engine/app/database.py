import mysql.connector

def get_db_connection():
    return mysql.connector.connect(
        host="fraud-mysql.cfey2gic407o.ap-south-1.rds.amazonaws.com",
        port=3306,
        user="fraud_user",
        password="Jaysinh6094",
        database="fraud_db"
    )

def update_transaction_status(transaction_id: str, status: str):
    connection = get_db_connection()
    cursor = connection.cursor()

    query = """
        UPDATE transactions
        SET status = %s
        WHERE transaction_id = %s
    """

    cursor.execute(query, (status, transaction_id))
    connection.commit()

    cursor.close()
    connection.close()