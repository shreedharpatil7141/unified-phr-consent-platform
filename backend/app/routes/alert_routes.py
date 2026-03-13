from fastapi import APIRouter, Depends
from datetime import datetime
from uuid import uuid4

from app.config.database import db
from app.core.dependencies import require_role
from app.services.trend_monitor_service import (
    compute_three_month_metric_summary,
    evaluate_three_month_increasing_trend,
)

router = APIRouter(prefix="/alerts", tags=["Alerts"])

alert_collection = db["alerts"]
health_collection = db["health_records"]

@router.post("/generate/{metric_name}")
def generate_alert(
    metric_name: str,
    current_user: dict = Depends(require_role("patient"))
):
    metric_key = (metric_name or "").strip().lower().replace("-", "_").replace(" ", "_")
    summary = compute_three_month_metric_summary(
        health_collection,
        patient_id=current_user["email"],
        metric_name=metric_key,
    )
    evaluation = evaluate_three_month_increasing_trend(summary)

    if evaluation["trend"] == "insufficient_data":
        return {
            "message": "Not enough data to generate alert. 3 months of data is required.",
            "trend_summary": summary,
        }

    if not evaluation["alert"]:
        return {
            "message": "No sustained 3-month increasing trend detected",
            "trend_summary": summary,
        }

    now = datetime.utcnow()
    existing_alert = alert_collection.find_one(
        {
            "patient_id": current_user["email"],
            "metric": metric_key,
            "status": "active",
            "created_at": {"$gte": now.replace(hour=0, minute=0, second=0, microsecond=0)},
        }
    )
    if existing_alert:
        return {
            "message": "Alert already generated today for this metric",
            "alert_id": existing_alert.get("alert_id"),
            "trend_summary": summary,
        }

    alert_data = {
        "alert_id": str(uuid4()),
        "patient_id": current_user["email"],
        "metric": metric_key,
        "monthly_averages": summary["bucket_averages"],
        "monthly_counts": summary["bucket_counts"],
        "message": (
            "Your heart-rate trend has increased consistently over the last 3 months. "
            "Please book a doctor appointment."
            if metric_key in {"heart_rate", "pulse_rate"}
            else f"{metric_name} shows a sustained increase over the last 3 months. Please book a doctor appointment."
        ),
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
