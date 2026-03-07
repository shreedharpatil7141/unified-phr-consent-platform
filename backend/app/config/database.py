import os
from pymongo import MongoClient
from dotenv import load_dotenv
from pathlib import Path

# Explicit path to .env file
BASE_DIR = Path(__file__).resolve().parent.parent.parent
env_path = BASE_DIR / ".env"

load_dotenv(dotenv_path=env_path)

MONGO_URI = os.getenv("MONGO_URI")
DB_NAME = os.getenv("DB_NAME")

print("ENV PATH:", env_path)
print("DEBUG MONGO_URI:", MONGO_URI)
print("DEBUG DB_NAME:", DB_NAME)

if not MONGO_URI:
    raise ValueError("MONGO_URI not found in .env file")

if not DB_NAME:
    raise ValueError("DB_NAME not found in .env file")

client = MongoClient(MONGO_URI)
db = client[DB_NAME]