import os
from pymongo import MongoClient
from dotenv import load_dotenv
from pathlib import Path
from pymongo.errors import ServerSelectionTimeoutError

# Explicit path to .env file
BASE_DIR = Path(__file__).resolve().parent.parent.parent
env_path = BASE_DIR / ".env"

load_dotenv(dotenv_path=env_path)

MONGO_URI = os.getenv("MONGO_URI", "mongodb://127.0.0.1:27017")
DB_NAME = os.getenv("DB_NAME", "unified_phr")

print("ENV PATH:", env_path)
print("MONGO_URI configured:", bool(MONGO_URI))
print("DB_NAME:", DB_NAME)

client = MongoClient(MONGO_URI)
if MONGO_URI.startswith("mongodb+srv://"):
    try:
        import certifi  # type: ignore
        client = MongoClient(
            MONGO_URI,
            tls=True,
            tlsCAFile=certifi.where(),
            serverSelectionTimeoutMS=10000,
        )
    except Exception:
        client = MongoClient(MONGO_URI, serverSelectionTimeoutMS=10000)
else:
    client = MongoClient(MONGO_URI, serverSelectionTimeoutMS=10000)

db = client[DB_NAME]
