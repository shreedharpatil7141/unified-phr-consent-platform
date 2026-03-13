from pydantic import BaseModel
from typing import List
from datetime import datetime

class ConsentRequest(BaseModel):
    patient_id: str
    categories: List[str]
    date_from: datetime
    date_to: datetime
    access_duration_minutes: int
    access_from: datetime | None = None
    access_to: datetime | None = None


class ConsentResponse(BaseModel):
    consent_id: str
    patient_id: str
    doctor_id: str
    categories: List[str]
    date_from: datetime
    date_to: datetime
    access_duration_minutes: int
    access_from: datetime | None = None
    access_to: datetime | None = None
    status: str
    requested_at: datetime
    approved_at: datetime | None = None
    expires_at: datetime | None = None
