import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "fraud-engine"))

from app.rules import evaluate_transaction


def test_normal_transaction_is_approved():
    result = evaluate_transaction(
        amount=5000,
        location="Mumbai",
        device_id="device123",
    )
    assert result == "APPROVED"


def test_high_amount_is_fraud():
    result = evaluate_transaction(
        amount=150000,
        location="Mumbai",
        device_id="device123",
    )
    assert result == "FRAUD"


def test_unknown_location_is_fraud():
    result = evaluate_transaction(
        amount=5000,
        location="Unknown",
        device_id="device123",
    )
    assert result == "FRAUD"


def test_blacklisted_device_is_fraud():
    result = evaluate_transaction(
        amount=5000,
        location="Mumbai",
        device_id="BLACKLISTED",
    )
    assert result == "FRAUD"
