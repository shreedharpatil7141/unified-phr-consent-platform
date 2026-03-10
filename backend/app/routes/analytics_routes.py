from fastapi import APIRouter, Depends, HTTPException
from datetime import datetime, timedelta
from app.config.database import db
from app.core.dependencies import require_role

router = APIRouter(prefix="/analytics", tags=["Analytics"])

health_collection = db["health_records"]

@router.get("/trend/{metric_name}")
def detect_trend(
    metric_name: str,
    current_user: dict = Depends(require_role("patient"))
):
    now = datetime.utcnow()

    last_30_days = now - timedelta(days=30)
    previous_60_days = now - timedelta(days=60)

    # Fetch last 30 days data
    recent_records = list(
        health_collection.find(
            {
                "patient_id": current_user["email"],
                "timestamp": {"$gte": last_30_days},
                "metrics.name": metric_name
            },
            {"_id": 0}
        )
    )

    # Fetch previous 30–60 days data
    older_records = list(
        health_collection.find(
            {
                "patient_id": current_user["email"],
                "timestamp": {
                    "$gte": previous_60_days,
                    "$lt": last_30_days
                },
                "metrics.name": metric_name
            },
            {"_id": 0}
        )
    )

    if not recent_records or not older_records:
        raise HTTPException(status_code=404, detail="Not enough data")

    def extract_values(records):
        values = []
        for record in records:
            for metric in record.get("metrics", []):
                if metric["name"] == metric_name:
                    values.append(metric["value"])
        return values

    recent_values = extract_values(recent_records)
    older_values = extract_values(older_records)

    if not recent_values or not older_values:
        raise HTTPException(status_code=404, detail="Metric data missing")

    recent_avg = sum(recent_values) / len(recent_values)
    older_avg = sum(older_values) / len(older_values)

    if recent_avg > older_avg:
        trend = "increasing"
    elif recent_avg < older_avg:
        trend = "decreasing"
    else:
        trend = "stable"

    return {
        "metric": metric_name,
        "previous_avg": older_avg,
        "recent_avg": recent_avg,
        "trend": trend
    }
