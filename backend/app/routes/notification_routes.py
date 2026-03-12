from fastapi import APIRouter, Depends, HTTPException
from datetime import datetime
from uuid import uuid4

from app.config.database import db
from app.core.dependencies import require_role, get_current_user

router = APIRouter(prefix="/notifications", tags=["Notifications"])

notification_collection = db["notifications"]


@router.post("/create")
def create_notification(
    user_id: str,
    message: str,
):
    """Internal helper route; usually called from other endpoints"""
    notif = {
        "notification_id": str(uuid4()),
        "user_id": user_id,
        "message": message,
        "created_at": datetime.utcnow(),
        "read": False,
    }
    notification_collection.insert_one(notif)
    return {"message": "notification created"}


@router.get("/my")
def get_my_notifications(
    current_user: dict = Depends(get_current_user)
):
    # we call require_role("patient") for now but doctors can also subscribe to notifications by role check
    docs = list(
        notification_collection.find(
            {"user_id": current_user["email"]}, {"_id": 0}
        ).sort("created_at", -1)
    )
    return docs


@router.post("/mark-read/{notification_id}")
def mark_read(
    notification_id: str,
    current_user: dict = Depends(get_current_user)
):
    notification_collection.update_one(
        {"notification_id": notification_id, "user_id": current_user["email"]},
        {"$set": {"read": True}}
    )
    return {"message": "marked read"}


@router.delete("/{notification_id}")
def delete_notification(
    notification_id: str,
    current_user: dict = Depends(get_current_user)
):
    result = notification_collection.delete_one(
        {"notification_id": notification_id, "user_id": current_user["email"]}
    )

    if result.deleted_count == 0:
        raise HTTPException(status_code=404, detail="Notification not found")

    return {"message": "notification deleted", "notification_id": notification_id}
