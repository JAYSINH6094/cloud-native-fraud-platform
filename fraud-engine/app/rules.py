def check_high_amount(amount: float) -> bool:
    """
    Flag transactions above the high-value threshold.
    """
    return amount > 100000

def check_suspicious_location(location: str) -> bool:
    """
    Flag transactions from suspicious locations.
    """
    suspicious_locations = {
        "Unknown",
        "Blacklisted"
    }

    return location in suspicious_locations


def check_suspicious_device(device_id: str) -> bool:
    """
    Flag transactions from suspicious devices.
    """
    suspicious_devices = {
        "UNKNOWN",
        "BLACKLISTED"
    }

    return device_id in suspicious_devices


def evaluate_transaction(amount: float, location: str, device_id: str) -> str:
    """
    Evaluate a transaction using all fraud rules.
    """

    if check_high_amount(amount):
        return "FRAUD"

    if check_suspicious_location(location):
        return "FRAUD"

    if check_suspicious_device(device_id):
        return "FRAUD"

    return "APPROVED"

