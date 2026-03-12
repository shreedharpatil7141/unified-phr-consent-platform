from fastapi import APIRouter, Depends
from datetime import datetime
from uuid import uuid4

from app.config.database import db
from app.core.dependencies import require_role

router = APIRouter(prefix="/alerts", tags=["Alerts"])

alert_collection = db["alerts"]
health_collection = db["health_records"]

@router.post("/generate/{metric_name}")
def generate_alert(
    metric_name: str,
    current_user: dict = Depends(require_role("patient"))
):
    from datetime import timedelta

    now = datetime.utcnow()
    last_30 = now - timedelta(days=30)
    prev_60 = now - timedelta(days=60)

    recent = list(
        health_collection.find(
            {
                "patient_id": current_user["email"],
                "timestamp": {"$gte": last_30},
                "metrics.name": metric_name
            },
            {"_id": 0}
        )
    )

    older = list(
        health_collection.find(
            {
                "patient_id": current_user["email"],
                "timestamp": {"$gte": prev_60, "$lt": last_30},
                "metrics.name": metric_name
            },
            {"_id": 0}
        )
    )

    def extract(records):
        values = []
        for r in records:
            for m in r.get("metrics", []):
                if m["name"] == metric_name:
                    values.append(m["value"])
        return values

    recent_vals = extract(recent)
    older_vals = extract(older)

    if not recent_vals or not older_vals:
        return {"message": "Not enough data to generate alert"}

    recent_avg = sum(recent_vals) / len(recent_vals)
    older_avg = sum(older_vals) / len(older_vals)

    if recent_avg <= older_avg:
        return {"message": "No concerning trend detected"}

    alert_data = {
        "alert_id": str(uuid4()),
        "patient_id": current_user["email"],
        "metric": metric_name,
        "previous_avg": older_avg,
        "recent_avg": recent_avg,
        "message": f"{metric_name} is increasing. Consider consulting a doctor.",
        "created_at": datetime.utcnow(),
        "status": "active"
    }

    # notify patient of alert
    db["notifications"].insert_one({
        "notification_id": str(uuid4()),
        "user_id": current_user["email"],
        "message": alert_data["message"],
        "created_at": datetime.utcnow(),
        "read": False
    })

    alert_collection.insert_one(alert_data)

    return {
        "message": "Alert generated",
        "alert_id": alert_data["alert_id"]
    }
@router.get("/my-alerts")
def get_my_alerts(
    current_user: dict = Depends(require_role("patient"))
):
    alerts = list(
        alert_collection.find(
            {"patient_id": current_user["email"]},
            {"_id": 0}
        ).sort("created_at", -1)
    )

    return alerts