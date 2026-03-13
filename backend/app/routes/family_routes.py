from datetime import datetime
from uuid import uuid4

from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel, EmailStr

from app.config.database import db
from app.core.dependencies import require_role


router = APIRouter(prefix="/family", tags=["Family Profiles"])

users_collection = db["users"]
family_links_collection = db["family_links"]
health_collection = db["health_records"]
appointments_collection = db["appointments"]
notifications_collection = db["notifications"]


class FamilyLinkRequest(BaseModel):
    member_email: EmailStr
    relation: str = "Family"


class FamilyLinkResponse(BaseModel):
    action: str  # accept | reject


def _sanitize_user_profile(user: dict | None) -> dict:
    if not user:
        return {}
    return {
        "name": user.get("name", ""),
        "email": user.get("email", ""),
        "height_cm": user.get("height_cm"),
        "weight_kg": user.get("weight_kg"),
        "blood_group": user.get("blood_group"),
        "allergies": user.get("allergies"),
        "gender": user.get("gender"),
        "age": user.get("age"),
    }


def _latest_heart_rate(patient_email: str):
    heart = health_collection.find_one(
        {
            "patient_id": patient_email,
            "$or": [
                {"record_type": {"$in": ["heart_rate", "heart rate", "pulse_rate", "pulse rate"]}},
                {"type": {"$in": ["heart_rate", "heart rate", "pulse_rate", "pulse rate"]}},
            ],
        },
        {"_id": 0, "value": 1, "unit": 1, "timestamp": 1},
        sort=[("timestamp", -1)],
    )
    if not heart:
        return None
    timestamp = heart.get("timestamp")
    if hasattr(timestamp, "isoformat"):
        timestamp = timestamp.isoformat()
    return {
        "value": heart.get("value"),
        "unit": heart.get("unit") or "bpm",
        "timestamp": timestamp,
    }


def _last_doctor_visit(patient_email: str):
    visit = appointments_collection.find_one(
        {
            "patient_email": patient_email,
            "status": {"$in": ["confirmed", "completed"]},
        },
        {"_id": 0, "doctor_email": 1, "scheduled_for": 1, "confirmed_at": 1, "status": 1},
        sort=[("scheduled_for", -1)],
    )
    if not visit:
        return None
    for key in ("scheduled_for", "confirmed_at"):
        val = visit.get(key)
        if hasattr(val, "isoformat"):
            visit[key] = val.isoformat()
    return visit


@router.post("/request-link")
def request_family_link(
    payload: FamilyLinkRequest,
    current_user: dict = Depends(require_role("patient")),
):
    requester = current_user["email"]
    member_email = payload.member_email.lower()
    relation = (payload.relation or "Family").strip() or "Family"

    if requester == member_email:
        raise HTTPException(status_code=400, detail="You cannot add yourself as family member")

    member_user = users_collection.find_one(
        {"email": member_email, "role": "patient"},
        {"_id": 0, "email": 1},
    )
    if not member_user:
        raise HTTPException(status_code=404, detail="Family member account not found")

    existing = family_links_collection.find_one(
        {
            "$or": [
                {"requester_email": requester, "member_email": member_email},
                {"requester_email": member_email, "member_email": requester},
            ],
            "status": {"$in": ["pending", "accepted"]},
        },
        {"_id": 0, "link_id": 1, "status": 1},
    )
    if existing:
        raise HTTPException(status_code=400, detail=f"Link already {existing['status']}")

    link_id = str(uuid4())
    family_links_collection.insert_one(
        {
            "link_id": link_id,
            "requester_email": requester,
            "member_email": member_email,
            "relation": relation,
            "status": "pending",
            "requested_at": datetime.utcnow(),
            "responded_at": None,
        }
    )

    notifications_collection.insert_one(
        {
            "notification_id": str(uuid4()),
            "user_id": member_email,
            "message": f"{requester} requested to link you as family ({relation}).",
            "created_at": datetime.utcnow(),
            "read": False,
        }
    )

    return {"message": "Family link request sent", "link_id": link_id, "status": "pending"}


@router.get("/requests/incoming")
def get_incoming_family_requests(
    current_user: dict = Depends(require_role("patient")),
):
    rows = list(
        family_links_collection.find(
            {"member_email": current_user["email"], "status": "pending"},
            {"_id": 0},
        ).sort("requested_at", -1)
    )
    for row in rows:
        if hasattr(row.get("requested_at"), "isoformat"):
            row["requested_at"] = row["requested_at"].isoformat()
    return rows


@router.get("/requests/outgoing")
def get_outgoing_family_requests(
    current_user: dict = Depends(require_role("patient")),
):
    rows = list(
        family_links_collection.find(
            {"requester_email": current_user["email"]},
            {"_id": 0},
        ).sort("requested_at", -1)
    )
    for row in rows:
        for key in ("requested_at", "responded_at"):
            if hasattr(row.get(key), "isoformat"):
                row[key] = row[key].isoformat()
    return rows


@router.post("/requests/{link_id}/respond")
def respond_family_link(
    link_id: str,
    payload: FamilyLinkResponse,
    current_user: dict = Depends(require_role("patient")),
):
    action = (payload.action or "").strip().lower()
    if action not in {"accept", "reject"}:
        raise HTTPException(status_code=400, detail="action must be accept or reject")

    link = family_links_collection.find_one(
        {"link_id": link_id, "member_email": current_user["email"]},
        {"_id": 0},
    )
    if not link:
        raise HTTPException(status_code=404, detail="Family request not found")
    if link.get("status") != "pending":
        raise HTTPException(status_code=400, detail="Request already handled")

    new_status = "accepted" if action == "accept" else "rejected"
    family_links_collection.update_one(
        {"link_id": link_id},
        {"$set": {"status": new_status, "responded_at": datetime.utcnow()}},
    )

    notifications_collection.insert_one(
        {
            "notification_id": str(uuid4()),
            "user_id": link["requester_email"],
            "message": f"{current_user['email']} has {new_status} your family link request.",
            "created_at": datetime.utcnow(),
            "read": False,
        }
    )

    return {"message": f"Request {new_status}", "link_id": link_id, "status": new_status}


@router.get("/linked-profiles")
def get_linked_family_profiles(
    current_user: dict = Depends(require_role("patient")),
):
    my_email = current_user["email"]
    links = list(
        family_links_collection.find(
            {
                "status": "accepted",
                "$or": [{"requester_email": my_email}, {"member_email": my_email}],
            },
            {"_id": 0},
        ).sort("responded_at", -1)
    )

    profiles = []
    for link in links:
        is_requester = link.get("requester_email") == my_email
        other_email = link.get("member_email") if is_requester else link.get("requester_email")
        relation = link.get("relation") if is_requester else "Family"
        user = users_collection.find_one(
            {"email": other_email},
            {"_id": 0, "password": 0},
        )
        profiles.append(
            {
                "link_id": link.get("link_id"),
                "relation": relation,
                "linked_at": link.get("responded_at").isoformat() if hasattr(link.get("responded_at"), "isoformat") else None,
                "profile": _sanitize_user_profile(user),
                "overview": {
                    "last_doctor_visit": _last_doctor_visit(other_email),
                    "latest_heart_rate": _latest_heart_rate(other_email),
                },
            }
        )

    return {"count": len(profiles), "profiles": profiles}
