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
    provider: Optional[str] = None
    timestamp: datetime
    metrics: Optional[List[HealthMetric]] = None
    notes: Optional[str] = None