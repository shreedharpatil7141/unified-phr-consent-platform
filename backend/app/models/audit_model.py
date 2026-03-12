from pydantic import BaseModel
from datetime import datetime
from typing import Optional


class AccessLog(BaseModel):
    """
    Audit log for tracking all data access.
    ABDM Compliance: Every data access must be logged and traceable.
    """
    log_id: Optional[str] = None
    doctor_id: str
    patient_id: str
    consent_id: str
    action: str  # "view_data", "create_consent", "approve_consent", "revoke_consent"
    data_accessed: str  # "cardiology_reports", "vitals", "prescriptions", "lab_reports"
    timestamp: datetime
    ip_address: Optional[str] = None
    status: str = "success"  # "success" or "denied"
    reason: Optional[str] = None  # If denied, why?
    duration_seconds: Optional[float] = None  # How long did the access take?


class AuditSummary(BaseModel):
    """Summary of access logs for compliance reporting"""
    total_accesses: int
    successful_accesses: int
    denied_accesses: int
    by_doctor: dict  # doctor_id -> count
    by_patient: dict  # patient_id -> count
    by_action: dict  # action -> count
    date_range: dict  # from, to
