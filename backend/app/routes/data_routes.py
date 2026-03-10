from fastapi import APIRouter, Depends, HTTPException
from datetime import datetime
from app.config.database import db
from app.core.dependencies import require_role

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

    if consent["status"] != "approved":
        raise HTTPException(status_code=403, detail="Consent not approved")

    if consent.get("expires_at") and consent["expires_at"] < datetime.utcnow():
        raise HTTPException(status_code=403, detail="Consent expired")

    patient_id = consent["patient_id"]
    allowed_categories = consent["categories"]

    query = {
        "patient_id": patient_id,
        "category": {"$in": allowed_categories}
    }

    records = list(
        health_collection.find(query, {"_id": 0}).sort("timestamp", 1)
    )

    # Attach file URL if record contains uploaded file
    for r in records:
        if r.get("file_name"):
            r["file_url"] = f"http://10.63.72.14:8000/uploads/{r['file_name']}"

    return {
        "patient_id": patient_id,
        "allowed_categories": allowed_categories,
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
        ).sort("timestamp", 1)
    )

    # attach file URL for patient view also
    for r in records:
        if r.get("file_name"):
            r["file_url"] = f"http://10.63.72.14:8000/uploads/{r['file_name']}"

    return records