from fastapi import APIRouter, Depends, HTTPException
from datetime import datetime
from uuid import uuid4

from app.config.database import db
from app.models.health_record_model import HealthRecord
from app.core.role_checker import require_role

router = APIRouter(prefix="/health", tags=["Health Records"])

health_collection = db["health_records"]

@router.post("/add")
def add_health_record(
    record: HealthRecord,
    current_user: dict = Depends(require_role("patient"))
):
    if record.patient_id != current_user["email"]:
        raise HTTPException(status_code=403, detail="Cannot add record for another patient")

    record_data = record.dict()
    record_data["record_id"] = str(uuid4())
    record_data["created_at"] = datetime.utcnow()

    health_collection.insert_one(record_data)

    return {
        "message": "Health record added successfully",
        "record_id": record_data["record_id"]
    }