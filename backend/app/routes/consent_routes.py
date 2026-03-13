from fastapi import APIRouter, Depends, HTTPException, status
from datetime import datetime, timedelta
from uuid import uuid4

from app.config.database import db
from app.models.consent_model import ConsentRequest
from app.core.dependencies import require_role, get_current_user
from app.services.audit_service import log_audit_event, log_data_access, get_access_summary

router = APIRouter(prefix="/consent", tags=["Consent"])

consent_collection = db["consents"]


CATEGORY_ALIASES = {
    "documents": "documents",
    "document": "documents",
    "lab_reports": "lab_report",
    "lab_report": "lab_report",
    "prescriptions": "prescription",
    "prescription": "prescription",
    "vaccines": "vaccination",
    "vaccination": "vaccination",
    "cardiology": "cardiac",
    "cardiac": "cardiac",
    "metabolic": "metabolic",
    "renal": "renal",
    "hepatic": "hepatic",
    "hemotology": "hematology",
    "hematology": "hematology",
    "respiratory": "respiratory",
    "general_wellness": "wellness",
    "general wellness": "wellness",
    "wellness": "wellness",
    "radiology": "radiology",
    "vitals": "vitals",
}


def normalize_categories(categories: list[str]) -> list[str]:
    normalized = []
    for category in categories:
        normalized.append(CATEGORY_ALIASES.get(category, category))
    return list(dict.fromkeys(normalized))


def expire_stale_consents():
    now = datetime.utcnow()
    consent_collection.update_many(
        {
            "status": "approved",
            "expires_at": {"$lt": now},
        },
        {
            "$set": {"status": "expired"}
        }
    )


def ensure_current_status(consent: dict) -> dict:
    if (
        consent.get("status") == "approved"
        and consent.get("expires_at")
        and consent["expires_at"] < datetime.utcnow()
    ):
        consent_collection.update_one(
            {"consent_id": consent["consent_id"]},
            {"$set": {"status": "expired"}}
        )
        consent["status"] = "expired"
    return consent

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
        "categories": normalize_categories(consent.categories),
        "date_from": consent.date_from,
        "date_to": consent.date_to,
        "access_duration_minutes": consent.access_duration_minutes,
        "access_from": consent.access_from,
        "access_to": consent.access_to,
        "status": "pending",
        "requested_at": datetime.utcnow(),
        "approved_at": None,
        "expires_at": None
    }

    consent_collection.insert_one(consent_data)
    log_audit_event(
        event_type="consent_requested",
        actor_email=current_user["email"],
        actor_role="doctor",
        target_patient_id=consent.patient_id,
        consent_id=consent_id,
        metadata={
            "categories": consent_data["categories"],
            "date_from": consent.date_from.isoformat(),
            "date_to": consent.date_to.isoformat(),
            "access_duration_minutes": consent.access_duration_minutes,
            "access_from": consent.access_from.isoformat() if consent.access_from else None,
            "access_to": consent.access_to.isoformat() if consent.access_to else None,
        },
    )

    # notify patient about incoming request
    db["notifications"].insert_one({
        "notification_id": str(uuid4()),
        "user_id": consent.patient_id,
        "message": f"Dr. {current_user['email']} is requesting access to your {', '.join(consent.categories)} records for {consent.access_duration_minutes} minutes.",
        "created_at": datetime.utcnow(),
        "read": False
    })

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
    access_from = consent.get("access_from") or approved_at
    access_to = consent.get("access_to") or (
        approved_at + timedelta(minutes=consent["access_duration_minutes"])
    )

    # Prevent timezone/input drift from creating a future-start consent after approval.
    if access_from > approved_at:
        access_from = approved_at
        access_to = approved_at + timedelta(minutes=consent["access_duration_minutes"])

    if access_to <= access_from:
        raise HTTPException(status_code=400, detail="Invalid access window")

    consent_collection.update_one(
        {"consent_id": consent_id},
        {
            "$set": {
                "status": "approved",
                "approved_at": approved_at,
                "access_from": access_from,
                "access_to": access_to,
                "expires_at": access_to
            }
        }
    )
    log_audit_event(
        event_type="consent_approved",
        actor_email=current_user["email"],
        actor_role="patient",
        target_patient_id=current_user["email"],
        consent_id=consent_id,
        metadata={
            "doctor_id": consent["doctor_id"],
            "approved_at": approved_at.isoformat(),
            "access_from": access_from.isoformat(),
            "access_to": access_to.isoformat(),
            "expires_at": access_to.isoformat(),
        },
    )

    # notify doctor of approval
    db["notifications"].insert_one({
        "notification_id": str(uuid4()),
        "user_id": consent["doctor_id"],
        "message": f"Patient has approved your access request (consent_id={consent_id}).",
        "created_at": datetime.utcnow(),
        "read": False
    })

    return {
        "message": "Consent approved",
        "consent_id": consent_id,
        "access_from": access_from,
        "access_to": access_to,
        "expires_at": access_to,
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
    log_audit_event(
        event_type="consent_rejected",
        actor_email=current_user["email"],
        actor_role="patient",
        target_patient_id=current_user["email"],
        consent_id=consent_id,
        metadata={"doctor_id": consent["doctor_id"]},
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
    expire_stale_consents()
    consents = [
        ensure_current_status(consent)
        for consent in list(
        consent_collection.find(
            {"patient_id": current_user["email"]},
            {"_id": 0}
        ).sort("requested_at", -1)
        )
    ]

    return consents
@router.get("/sent")
def get_sent_requests(
    current_user: dict = Depends(require_role("doctor"))
):
    expire_stale_consents()
    consents = [
        ensure_current_status(consent)
        for consent in list(
        consent_collection.find(
            {"doctor_id": current_user["email"]},
            {"_id": 0}
        ).sort("requested_at", -1)
        )
    ]

    return consents


@router.delete("/{consent_id}")
def delete_consent(
    consent_id: str,
    current_user: dict = Depends(get_current_user)
):
    consent = consent_collection.find_one({"consent_id": consent_id})

    if not consent:
        raise HTTPException(status_code=404, detail="Consent not found")

    if current_user["email"] not in {consent.get("doctor_id"), consent.get("patient_id")}:
        raise HTTPException(status_code=403, detail="Not allowed to delete this consent")

    effective_status = ensure_current_status(consent).get("status")
    if effective_status not in {"expired", "rejected", "revoked"}:
        raise HTTPException(
            status_code=400,
            detail="Only expired, rejected, or revoked consents can be deleted"
        )

    consent_collection.delete_one({"consent_id": consent_id})
    log_audit_event(
        event_type="consent_deleted",
        actor_email=current_user["email"],
        actor_role=current_user.get("role", "user"),
        target_patient_id=consent.get("patient_id"),
        consent_id=consent_id,
        metadata={"status": effective_status},
    )
    return {"message": "Consent deleted", "consent_id": consent_id}


@router.delete("/expired/cleanup")
def delete_expired_consents(
    current_user: dict = Depends(require_role("doctor"))
):
    expire_stale_consents()
    result = consent_collection.delete_many(
        {"doctor_id": current_user["email"], "status": "expired"}
    )
    log_audit_event(
        event_type="expired_consents_deleted",
        actor_email=current_user["email"],
        actor_role="doctor",
        metadata={"deleted_count": result.deleted_count},
    )
    return {"message": "Expired consents deleted", "deleted_count": result.deleted_count}
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
    log_audit_event(
        event_type="consent_revoked",
        actor_email=current_user["email"],
        actor_role="patient",
        target_patient_id=current_user["email"],
        consent_id=consent_id,
        metadata={"doctor_id": consent["doctor_id"]},
    )

    # notify doctor that consent has been revoked
    db["notifications"].insert_one({
        "notification_id": str(uuid4()),
        "user_id": consent["doctor_id"],
        "message": f"Patient has revoked consent {consent_id}.",
        "created_at": datetime.utcnow(),
        "read": False
    })

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


# ============================================
# AUDIT & COMPLIANCE ENDPOINTS
# ============================================

@router.get("/audit-logs/my-accesses")
def get_my_access_logs(
    current_user: dict = Depends(require_role("doctor")),
    days_back: int = 30
):
    """
    Doctor can view a summary of their data accesses.
    Shows: how many patients they accessed, when, and what data.
    ABDM Compliance: Doctors can see audit trail of their own accesses.
    """
    summary = get_access_summary(doctor_id=current_user["email"], days_back=days_back)
    return {
        "doctor_id": current_user["email"],
        "audit_summary": summary,
        "generated_at": datetime.utcnow().isoformat(),
        "compliance_note": "This audit log tracks all data accesses by this doctor."
    }


@router.get("/audit-logs/patient-accesses")
def get_patient_access_logs(
    current_user: dict = Depends(require_role("patient")),
    days_back: int = 30
):
    """
    Patient can view who accessed their data and when.
    Shows: which doctors accessed, when, and what data was accessed.
    ABDM Compliance: Patients have right to know who accessed their data.
    """
    summary = get_access_summary(patient_id=current_user["email"], days_back=days_back)
    return {
        "patient_id": current_user["email"],
        "audit_summary": summary,
        "generated_at": datetime.utcnow().isoformat(),
        "compliance_note": "This audit log shows all doctors who have accessed your data."
    }


@router.get("/audit-logs/consent-audit/{consent_id}")
def get_consent_audit_trail(
    consent_id: str,
    current_user: dict = Depends(require_role("patient"))
):
    """
    Patient can view the complete audit trail of a single consent.
    Shows: who requested, when approved, when revoked, all accesses.
    ABDM Compliance: Full transparency on consent usage.
    """
    consent = consent_collection.find_one(
        {"consent_id": consent_id, "patient_id": current_user["email"]}
    )
    
    if not consent:
        raise HTTPException(status_code=404, detail="Consent not found")
    
    # Get all accesses under this consent
    from app.services.audit_service import db as audit_db
    access_logs = list(
        audit_db["access_logs"].find(
            {"consent_id": consent_id}
        ).sort("timestamp", -1)
    )
    
    return {
        "consent_id": consent_id,
        "doctor_id": consent["doctor_id"],
        "status": consent["status"],
        "requested_at": consent.get("requested_at"),
        "approved_at": consent.get("approved_at"),
        "expires_at": consent.get("expires_at"),
        "revoked_at": consent.get("revoked_at"),
        "access_logs": [
            {
                "timestamp": log.get("timestamp"),
                "action": log.get("action"),
                "data_accessed": log.get("data_accessed"),
                "status": log.get("status"),
            }
            for log in access_logs
        ],
        "generated_at": datetime.utcnow().isoformat(),
        "compliance_note": "This is the complete audit trail for this consent."
    }
