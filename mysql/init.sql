USE fraud_db;

CREATE TABLE IF NOT EXISTS transactions (
    transaction_id VARCHAR(36) PRIMARY KEY,
    user_id VARCHAR(100) NOT NULL,
    amount DECIMAL(15,2) NOT NULL,
    merchant VARCHAR(255) NOT NULL,
    location VARCHAR(255) NOT NULL,
    device_id VARCHAR(255) NOT NULL,
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    status VARCHAR(50) DEFAULT 'PENDING'
);

CREATE INDEX idx_transactions_user_id ON transactions(user_id);
CREATE INDEX idx_transactions_status ON transactions(status);
CREATE INDEX idx_transactions_timestamp ON transactions(timestamp);
