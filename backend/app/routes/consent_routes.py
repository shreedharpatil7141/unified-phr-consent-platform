from fastapi import APIRouter, Depends, HTTPException, status
from datetime import datetime, timedelta
from uuid import uuid4

from app.config.database import db
from app.models.consent_model import ConsentRequest
from app.core.dependencies import require_role

router = APIRouter(prefix="/consent", tags=["Consent"])

consent_collection = db["consents"]

@router.post("/request")
def request_consent(
    consent: ConsentRequest,
    current_user: dict = Depends(require_role("doctor"))
):
    consent_id = str(uuid4())

    consent_data = {
        "consent_id": consent_id,
        "patient_id": consent.patient_id,
        "doctor_id": current_user["email"],
        "categories": consent.categories,
        "date_from": consent.date_from,
        "date_to": consent.date_to,
        "access_duration_minutes": consent.access_duration_minutes,
        "status": "pending",
        "requested_at": datetime.utcnow(),
        "approved_at": None,
        "expires_at": None
    }

    consent_collection.insert_one(consent_data)

    return {
        "message": "Consent request sent",
        "consent_id": consent_id,
        "status": "pending"
    }
@router.post("/{consent_id}/approve")
def approve_consent(
    consent_id: str,
    current_user: dict = Depends(require_role("patient"))
):
    consent = consent_collection.find_one({"consent_id": consent_id})

    if not consent:
        raise HTTPException(status_code=404, detail="Consent not found")

    if consent["patient_id"] != current_user["email"]:
        raise HTTPException(status_code=403, detail="Not your consent request")

    if consent["status"] != "pending":
        raise HTTPException(status_code=400, detail="Consent already processed")

    approved_at = datetime.utcnow()
    expires_at = approved_at + timedelta(
        minutes=consent["access_duration_minutes"]
    )

    consent_collection.update_one(
        {"consent_id": consent_id},
        {
            "$set": {
                "status": "approved",
                "approved_at": approved_at,
                "expires_at": expires_at
            }
        }
    )

    return {
        "message": "Consent approved",
        "consent_id": consent_id,
        "expires_at": expires_at,
        "status": "approved"
    }
@router.post("/{consent_id}/reject")
def reject_consent(
    consent_id: str,
    current_user: dict = Depends(require_role("patient"))
):
    consent = consent_collection.find_one({"consent_id": consent_id})

    if not consent:
        raise HTTPException(status_code=404, detail="Consent not found")

    if consent["patient_id"] != current_user["email"]:
        raise HTTPException(status_code=403, detail="Not your consent request")

    if consent["status"] != "pending":
        raise HTTPException(status_code=400, detail="Consent already processed")

    consent_collection.update_one(
        {"consent_id": consent_id},
        {"$set": {"status": "rejected"}}
    )

    return {
        "message": "Consent rejected",
        "consent_id": consent_id,
        "status": "rejected"
    }
@router.get("/my-requests")
def get_my_requests(
    current_user: dict = Depends(require_role("patient"))
):
    consents = list(
        consent_collection.find(
            {"patient_id": current_user["email"]},
            {"_id": 0}
        )
    )

    return consents
@router.get("/sent")
def get_sent_requests(
    current_user: dict = Depends(require_role("doctor"))
):
    consents = list(
        consent_collection.find(
            {"doctor_id": current_user["email"]},
            {"_id": 0}
        )
    )

    return consents
@router.post("/{consent_id}/revoke")
def revoke_consent(
    consent_id: str,
    current_user: dict = Depends(require_role("patient"))
):
    consent = consent_collection.find_one({"consent_id": consent_id})

    if not consent:
        raise HTTPException(status_code=404, detail="Consent not found")

    if consent["patient_id"] != current_user["email"]:
        raise HTTPException(status_code=403, detail="Not your consent")

    if consent["status"] != "approved":
        raise HTTPException(status_code=400, detail="Only approved consent can be revoked")

    consent_collection.update_one(
        {"consent_id": consent_id},
        {"$set": {"status": "revoked"}}
    )

    return {
        "message": "Consent revoked successfully",
        "consent_id": consent_id,
        "status": "revoked"
    }
def validate_active_consent(consent: dict):
    if consent["status"] != "approved":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Consent not approved"
        )

    if consent["expires_at"] and consent["expires_at"] < datetime.utcnow():
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Consent expired"
        )