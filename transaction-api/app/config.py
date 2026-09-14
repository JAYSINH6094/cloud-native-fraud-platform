import os

from dotenv import load_dotenv


load_dotenv()


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
