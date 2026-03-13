from datetime import datetime, timedelta, timezone
from uuid import uuid4

from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel, EmailStr

from app.config.database import db
from app.core.dependencies import get_current_user, require_role


router = APIRouter(prefix="/appointments", tags=["Appointments"])

appointments_collection = db["appointments"]
users_collection = db["users"]
notifications_collection = db["notifications"]


class AppointmentRequestPayload(BaseModel):
    doctor_email: EmailStr
    scheduled_for: datetime
    reason: str = "General consultation"
    notes: str | None = None
    patient_email: EmailStr | None = None


class AppointmentConfirmPayload(BaseModel):
    scheduled_for: datetime
    ends_at: datetime
    confirmation_note: str | None = None


class AppointmentStatusPayload(BaseModel):
    note: str | None = None


def _to_utc_naive(value: datetime) -> datetime:
    if value.tzinfo is None:
        return value
    return value.astimezone(timezone.utc).replace(tzinfo=None)


def _resolve_end_time(row: dict) -> datetime | None:
    end = row.get("ends_at")
    if isinstance(end, datetime):
        return _to_utc_naive(end)

    start = row.get("scheduled_for")
    if isinstance(start, datetime):
        # Backward-safe fallback for older records that were confirmed without ends_at.
        return (_to_utc_naive(start).replace(second=0, microsecond=0) + timedelta(minutes=30))
    return None


def _serialize_appointment(row: dict) -> dict:
    out = {k: v for k, v in row.items() if k != "_id"}
    for key in (
        "requested_at",
        "scheduled_for",
        "ends_at",
        "confirmed_at",
        "completed_at",
        "cancelled_at",
    ):
        value = out.get(key)
        if hasattr(value, "isoformat"):
            out[key] = value.isoformat()
    return out


@router.post("/request")
def request_appointment(
    payload: AppointmentRequestPayload,
    current_user: dict = Depends(require_role("patient")),
):
    doctor_email = payload.doctor_email.lower()
    patient_email = (payload.patient_email or current_user["email"]).lower()

    if patient_email != current_user["email"]:
        raise HTTPException(status_code=403, detail="Cannot request appointment for another patient")

    doctor = users_collection.find_one({"email": doctor_email, "role": "doctor"}, {"_id": 0, "email": 1})
    if not doctor:
        raise HTTPException(status_code=404, detail="Doctor account not found")

    scheduled_for = _to_utc_naive(payload.scheduled_for)

    if scheduled_for < datetime.utcnow():
        raise HTTPException(status_code=400, detail="Appointment time must be in the future")

    appointment_id = str(uuid4())
    appointments_collection.insert_one(
        {
            "appointment_id": appointment_id,
            "patient_email": patient_email,
            "doctor_email": doctor_email,
            "reason": (payload.reason or "General consultation").strip() or "General consultation",
            "notes": payload.notes or "",
            "status": "requested",
            "requested_at": datetime.utcnow(),
            "scheduled_for": scheduled_for,
            "ends_at": None,
            "confirmation_note": None,
            "confirmed_at": None,
            "completed_at": None,
            "cancelled_at": None,
        }
    )

    notifications_collection.insert_one(
        {
            "notification_id": str(uuid4()),
            "user_id": doctor_email,
            "message": f"{patient_email} requested an appointment for {scheduled_for.isoformat()} UTC.",
            "created_at": datetime.utcnow(),
            "read": False,
        }
    )

    return {"message": "Appointment request sent", "appointment_id": appointment_id, "status": "requested"}


@router.get("/my")
def get_my_appointments(
    current_user: dict = Depends(require_role("patient")),
):
    rows = list(
        appointments_collection.find(
            {"patient_email": current_user["email"]},
            {"_id": 0},
        ).sort("requested_at", -1)
    )
    return [_serialize_appointment(row) for row in rows]


@router.get("/doctor")
def get_doctor_appointments(
    current_user: dict = Depends(require_role("doctor")),
):
    rows = list(
        appointments_collection.find(
            {"doctor_email": current_user["email"]},
            {"_id": 0},
        ).sort("requested_at", -1)
    )
    return [_serialize_appointment(row) for row in rows]


@router.post("/{appointment_id}/confirm")
def confirm_appointment(
    appointment_id: str,
    payload: AppointmentConfirmPayload,
    current_user: dict = Depends(require_role("doctor")),
):
    appointment = appointments_collection.find_one(
        {"appointment_id": appointment_id, "doctor_email": current_user["email"]},
        {"_id": 0},
    )
    if not appointment:
        raise HTTPException(status_code=404, detail="Appointment not found")

    if appointment.get("status") not in {"requested", "rescheduled"}:
        raise HTTPException(status_code=400, detail="Appointment cannot be confirmed in current state")

    scheduled_for = _to_utc_naive(payload.scheduled_for)
    ends_at = _to_utc_naive(payload.ends_at)

    if ends_at <= scheduled_for:
        raise HTTPException(status_code=400, detail="End time must be after start time")

    overlapping = appointments_collection.find(
        {
            "doctor_email": current_user["email"],
            "status": "confirmed",
            "appointment_id": {"$ne": appointment_id},
        },
        {"_id": 0, "appointment_id": 1, "scheduled_for": 1, "ends_at": 1},
    )
    for other in overlapping:
        other_start = _to_utc_naive(other.get("scheduled_for")) if other.get("scheduled_for") else None
        other_end = _resolve_end_time(other)
        if not other_start or not other_end:
            continue
        # Overlap rule: A starts before B ends and A ends after B starts.
        if scheduled_for < other_end and ends_at > other_start:
            raise HTTPException(
                status_code=409,
                detail="Selected slot overlaps with another confirmed appointment",
            )

    appointments_collection.update_one(
        {"appointment_id": appointment_id},
        {
            "$set": {
                "status": "confirmed",
                "scheduled_for": scheduled_for,
                "ends_at": ends_at,
                "confirmation_note": payload.confirmation_note or "",
                "confirmed_at": datetime.utcnow(),
            }
        },
    )

    notifications_collection.insert_one(
        {
            "notification_id": str(uuid4()),
            "user_id": appointment["patient_email"],
            "message": f"Dr. {current_user['email']} confirmed your appointment for {scheduled_for.isoformat()} UTC.",
            "created_at": datetime.utcnow(),
            "read": False,
        }
    )

    return {"message": "Appointment confirmed", "appointment_id": appointment_id, "status": "confirmed"}


@router.post("/{appointment_id}/complete")
def complete_appointment(
    appointment_id: str,
    payload: AppointmentStatusPayload,
    current_user: dict = Depends(require_role("doctor")),
):
    appointment = appointments_collection.find_one(
        {"appointment_id": appointment_id, "doctor_email": current_user["email"]},
        {"_id": 0},
    )
    if not appointment:
        raise HTTPException(status_code=404, detail="Appointment not found")
    if appointment.get("status") != "confirmed":
        raise HTTPException(status_code=400, detail="Only confirmed appointments can be completed")

    appointments_collection.update_one(
        {"appointment_id": appointment_id},
        {"$set": {"status": "completed", "completed_at": datetime.utcnow(), "confirmation_note": payload.note or appointment.get("confirmation_note", "")}},
    )
    return {"message": "Appointment marked completed", "appointment_id": appointment_id, "status": "completed"}


@router.post("/{appointment_id}/cancel")
def cancel_appointment(
    appointment_id: str,
    payload: AppointmentStatusPayload,
    current_user: dict = Depends(get_current_user),
):
    appointment = appointments_collection.find_one({"appointment_id": appointment_id}, {"_id": 0})
    if not appointment:
        raise HTTPException(status_code=404, detail="Appointment not found")

    if current_user["email"] not in {appointment.get("patient_email"), appointment.get("doctor_email")}:
        raise HTTPException(status_code=403, detail="Not allowed to cancel this appointment")

    if appointment.get("status") in {"cancelled", "completed"}:
        raise HTTPException(status_code=400, detail="Appointment already closed")

    appointments_collection.update_one(
        {"appointment_id": appointment_id},
        {
            "$set": {
                "status": "cancelled",
                "cancelled_at": datetime.utcnow(),
                "confirmation_note": payload.note or appointment.get("confirmation_note", ""),
            }
        },
    )

    other_user = appointment["doctor_email"] if current_user["email"] == appointment["patient_email"] else appointment["patient_email"]
    notifications_collection.insert_one(
        {
            "notification_id": str(uuid4()),
            "user_id": other_user,
            "message": f"{current_user['email']} cancelled appointment {appointment_id}.",
            "created_at": datetime.utcnow(),
            "read": False,
        }
    )

    return {"message": "Appointment cancelled", "appointment_id": appointment_id, "status": "cancelled"}


@router.delete("/{appointment_id}")
def delete_appointment(
    appointment_id: str,
    current_user: dict = Depends(get_current_user),
):
    appointment = appointments_collection.find_one({"appointment_id": appointment_id}, {"_id": 0})
    if not appointment:
        raise HTTPException(status_code=404, detail="Appointment not found")

    if current_user["email"] not in {appointment.get("patient_email"), appointment.get("doctor_email")}:
        raise HTTPException(status_code=403, detail="Not allowed to delete this appointment")

    status = appointment.get("status")
    is_closed = status in {"completed", "cancelled"}
    is_expired_confirmed = status == "confirmed" and isinstance(appointment.get("ends_at"), datetime) and _to_utc_naive(
        appointment["ends_at"]
    ) < datetime.utcnow()
    if not (is_closed or is_expired_confirmed):
        raise HTTPException(status_code=400, detail="Only closed/expired appointments can be deleted")

    appointments_collection.delete_one({"appointment_id": appointment_id})
    return {"message": "Appointment deleted", "appointment_id": appointment_id}
