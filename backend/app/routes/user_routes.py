from fastapi import APIRouter, Depends

from app.config.database import db
from app.core.dependencies import get_current_user, require_role
from app.schemas.user_schema import UserProfileUpdate
from app.services.audit_service import log_audit_event

router = APIRouter(prefix="/user", tags=["User"])

users_collection = db["users"]


def _sanitize_user(user: dict) -> dict:
    return {
        "name": user.get("name", ""),
        "email": user.get("email", ""),
        "role": user.get("role", ""),
        "height_cm": user.get("height_cm"),
        "weight_kg": user.get("weight_kg"),
        "allergies": user.get("allergies"),
        "blood_group": user.get("blood_group"),
        "chronic_conditions": user.get("chronic_conditions"),
        "emergency_contact": user.get("emergency_contact"),
        "gender": user.get("gender"),
        "age": user.get("age"),
        "profile_complete": user.get("profile_complete", False),
    }


@router.get("/me")
def get_me(current_user: dict = Depends(get_current_user)):
    db_user = users_collection.find_one({"email": current_user["email"]}, {"_id": 0, "password": 0})
    return _sanitize_user(db_user or current_user)


@router.put("/me")
def update_me(
    payload: UserProfileUpdate,
    current_user: dict = Depends(require_role("patient")),
):
    updates = {key: value for key, value in payload.dict().items() if value is not None}
    updates["profile_complete"] = any(value != "" for value in updates.values()) or True

    users_collection.update_one(
        {"email": current_user["email"]},
        {"$set": updates},
    )
    db_user = users_collection.find_one({"email": current_user["email"]}, {"_id": 0, "password": 0}) or {}
    log_audit_event(
        event_type="user_profile_updated",
        actor_email=current_user["email"],
        actor_role="patient",
        target_patient_id=current_user["email"],
        metadata={"updated_fields": list(updates.keys())},
    )
    return _sanitize_user(db_user)
