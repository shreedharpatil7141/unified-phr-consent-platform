from __future__ import annotations

from datetime import datetime
from typing import Any
from uuid import uuid4

from app.config.database import db


audit_collection = db["audit_logs"]
access_logs_collection = db["access_logs"]


def log_audit_event(
    event_type: str,
    actor_email: str,
    actor_role: str,
    target_patient_id: str | None = None,
    consent_id: str | None = None,
    metadata: dict[str, Any] | None = None,
):
    """
    Log audit events (general)
    event_type: "consent_request", "consent_approve", "consent_revoke", etc.
    """
    audit_collection.insert_one(
        {
            "audit_id": str(uuid4()),
            "event_type": event_type,
            "actor_email": actor_email,
            "actor_role": actor_role,
            "target_patient_id": target_patient_id,
            "consent_id": consent_id,
            "metadata": metadata or {},
            "created_at": datetime.utcnow(),
        }
    )


def log_data_access(
    doctor_id: str,
    patient_id: str,
    consent_id: str,
    action: str,
    data_accessed: str,
    ip_address: str | None = None,
    status: str = "success",
    reason: str | None = None,
    duration_seconds: float | None = None,
):
    """
    Log data access for ABDM compliance.
    Every time a doctor views patient data, this is recorded.
    
    action: "view_data", "view_vitals", "view_reports", etc.
    data_accessed: "cardiology_reports", "all_vitals", "prescriptions", etc.
    status: "success" or "denied"
    reason: If denied, explain why (e.g., "consent_expired")
    """
    access_logs_collection.insert_one(
        {
            "log_id": str(uuid4()),
            "doctor_id": doctor_id,
            "patient_id": patient_id,
            "consent_id": consent_id,
            "action": action,
            "data_accessed": data_accessed,
            "timestamp": datetime.utcnow(),
            "ip_address": ip_address,
            "status": status,
            "reason": reason,
            "duration_seconds": duration_seconds,
        }
    )


def get_access_logs(
    doctor_id: str | None = None,
    patient_id: str | None = None,
    consent_id: str | None = None,
    days_back: int = 30,
) -> list[dict]:
    """
    Retrieve access logs for compliance review.
    Can filter by doctor, patient, or consent.
    """
    query = {}
    if doctor_id:
        query["doctor_id"] = doctor_id
    if patient_id:
        query["patient_id"] = patient_id
    if consent_id:
        query["consent_id"] = consent_id
    
    if days_back > 0:
        from datetime import timedelta
        start_date = datetime.utcnow() - timedelta(days=days_back)
        query["timestamp"] = {"$gte": start_date}
    
    return list(
        access_logs_collection.find(query, {"_id": 0}).sort("timestamp", -1)
    )


def get_access_summary(
    doctor_id: str | None = None,
    patient_id: str | None = None,
    days_back: int = 30,
) -> dict:
    """
    Get summary of accesses for compliance reporting.
    """
    logs = get_access_logs(doctor_id, patient_id, days_back=days_back)
    
    serialized_logs = []
    for log in logs:
        sanitized = {k: v for k, v in log.items() if k != "_id"}
        timestamp = sanitized.get("timestamp")
        if isinstance(timestamp, datetime):
            sanitized["timestamp"] = timestamp.isoformat()
        serialized_logs.append(sanitized)

    summary = {
        "total_accesses": len(logs),
        "successful_accesses": len([log for log in logs if log["status"] == "success"]),
        "denied_accesses": len([log for log in logs if log["status"] == "denied"]),
        "by_doctor": {},
        "by_patient": {},
        "by_action": {},
        "logs": serialized_logs,
    }
    
    for log in logs:
        doctor = log.get("doctor_id")
        patient = log.get("patient_id")
        action = log.get("action")
        
        summary["by_doctor"][doctor] = summary["by_doctor"].get(doctor, 0) + 1
        summary["by_patient"][patient] = summary["by_patient"].get(patient, 0) + 1
        summary["by_action"][action] = summary["by_action"].get(action, 0) + 1
    
    return summary
