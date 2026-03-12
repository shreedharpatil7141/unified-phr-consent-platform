from pydantic import BaseModel
from typing import Optional, List
from datetime import datetime


class HealthMetric(BaseModel):
    name: str
    value: float
    unit: str


class HealthRecord(BaseModel):
    patient_id: str
    source: str  # wearable | lab | hospital | manual
    category: str  # cardiology | diabetes | general | etc
    record_type: str  # ecg | lab_report | prescription | vital
    type: Optional[str] = None
    domain: Optional[str] = None
    provider: Optional[str] = None
    timestamp: datetime
    metrics: Optional[List[HealthMetric]] = None
    value: Optional[str] = None
    unit: Optional[str] = None
    notes: Optional[str] = None
    file_name: Optional[str] = None
    record_name: Optional[str] = None
    file_url: Optional[str] = None  # accessible path to download/view
    doctor: Optional[str] = None
    hospital: Optional[str] = None
