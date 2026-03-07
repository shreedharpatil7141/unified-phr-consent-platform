from fastapi import APIRouter, Depends, HTTPException
from datetime import datetime
from app.config.database import db
from app.core.role_checker import require_role

router = APIRouter(prefix="/data", tags=["Data Access"])

consent_collection = db["consents"]
health_collection = db["health_records"]


# --------------------------------------------
# Doctor views patient data using consent
# --------------------------------------------

@router.get("/view/{consent_id}")
def view_patient_data(
    consent_id: str,
    current_user: dict = Depends(require_role("doctor"))
):

    consent = consent_collection.find_one({"consent_id": consent_id})

    if not consent:
        raise HTTPException(status_code=404, detail="Consent not found")

    if consent["doctor_id"] != current_user["email"]:
        raise HTTPException(status_code=403, detail="Not authorized")

    if consent["status"] == "revoked":
        raise HTTPException(status_code=403, detail="Consent revoked")

    query = {
        "patient_id": consent["patient_id"]
    }

    records = list(health_collection.find(query, {"_id": 0}))

    return {
        "message": "Access granted",
        "records": records
    }


# --------------------------------------------
# Patient views their own records
# --------------------------------------------

@router.get("/my-records")
def get_my_records(
    current_user: dict = Depends(require_role("patient"))
):

    records = list(
        health_collection.find(
            {"patient_id": current_user["email"]},
            {"_id": 0}
        )
    )

    return records