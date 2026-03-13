from fastapi import APIRouter, Depends, HTTPException

from app.config.database import db
from app.core.dependencies import require_role
from app.services.trend_monitor_service import (
    compute_three_month_metric_summary,
    evaluate_three_month_increasing_trend,
)

router = APIRouter(prefix="/analytics", tags=["Analytics"])

health_collection = db["health_records"]


@router.get("/trend/{metric_name}")
def detect_trend(
    metric_name: str,
    current_user: dict = Depends(require_role("patient"))
):
    summary = compute_three_month_metric_summary(
        health_collection,
        patient_id=current_user["email"],
        metric_name=metric_name,
    )
    evaluation = evaluate_three_month_increasing_trend(summary)

    if evaluation["trend"] == "insufficient_data":
        raise HTTPException(status_code=404, detail="Not enough 3-month data")

    averages = summary.get("bucket_averages", [None, None, None])
    month1, month2, month3 = averages
    if month1 is None or month2 is None or month3 is None:
        raise HTTPException(status_code=404, detail="Metric data missing")

    if month1 < month2 < month3:
        trend = "increasing"
    elif month1 > month2 > month3:
        trend = "decreasing"
    else:
        trend = "fluctuating"

    return {
        "metric": metric_name,
        "trend": trend,
        "window_days": summary["window_days"],
        "month1_avg": month1,
        "month2_avg": month2,
        "month3_avg": month3,
        "month1_count": summary["bucket_counts"][0],
        "month2_count": summary["bucket_counts"][1],
        "month3_count": summary["bucket_counts"][2],
        "alert_recommended": evaluation["alert"],
        "evaluation_reason": evaluation["reason"],
    }
