from __future__ import annotations

from datetime import datetime, timedelta
from typing import Any


def _to_datetime(value: Any) -> datetime | None:
    if isinstance(value, datetime):
        return value
    if isinstance(value, str):
        try:
            return datetime.fromisoformat(value)
        except ValueError:
            return None
    return None


def _bucket_index(timestamp: datetime, start_90: datetime, start_60: datetime, start_30: datetime) -> int | None:
    if timestamp < start_90 or timestamp > datetime.utcnow():
        return None
    if timestamp < start_60:
        return 0
    if timestamp < start_30:
        return 1
    return 2


def _metric_aliases(metric_name: str) -> list[str]:
    key = (metric_name or "").strip().lower().replace("-", "_").replace(" ", "_")
    aliases = {
        "heart_rate": ["heart_rate", "heart rate", "pulse_rate", "pulse rate"],
        "pulse_rate": ["pulse_rate", "pulse rate", "heart_rate", "heart rate"],
    }
    return aliases.get(key, [metric_name, key, key.replace("_", " ")])


def compute_three_month_metric_summary(
    health_collection,
    patient_id: str,
    metric_name: str,
    now: datetime | None = None,
) -> dict:
    now = now or datetime.utcnow()
    metric_names = _metric_aliases(metric_name)
    start_30 = now - timedelta(days=30)
    start_60 = now - timedelta(days=60)
    start_90 = now - timedelta(days=90)

    records = list(
        health_collection.find(
            {
                "patient_id": patient_id,
                "timestamp": {"$gte": start_90, "$lte": now},
                "metrics.name": {"$in": metric_names},
            },
            {"_id": 0, "timestamp": 1, "metrics": 1},
        )
    )

    buckets: list[list[float]] = [[], [], []]
    for record in records:
        timestamp = _to_datetime(record.get("timestamp"))
        if not timestamp:
            continue

        index = _bucket_index(timestamp, start_90, start_60, start_30)
        if index is None:
            continue

        for metric in record.get("metrics", []):
            metric_name_in_record = (metric.get("name") or "").strip().lower()
            if metric_name_in_record not in [name.lower() for name in metric_names]:
                continue
            try:
                buckets[index].append(float(metric.get("value")))
            except (TypeError, ValueError):
                continue

    averages = [
        (sum(bucket) / len(bucket)) if bucket else None
        for bucket in buckets
    ]

    return {
        "metric": metric_name,
        "window_days": 90,
        "bucket_ranges": [
            {"from": start_90, "to": start_60},
            {"from": start_60, "to": start_30},
            {"from": start_30, "to": now},
        ],
        "bucket_counts": [len(bucket) for bucket in buckets],
        "bucket_averages": averages,
    }


def evaluate_three_month_increasing_trend(
    summary: dict,
    min_points_per_month: int = 3,
    min_delta: float = 3.0,
) -> dict:
    counts = summary.get("bucket_counts", [0, 0, 0])
    averages = summary.get("bucket_averages", [None, None, None])

    if any(count < min_points_per_month for count in counts):
        return {
            "alert": False,
            "trend": "insufficient_data",
            "reason": "Need at least 3 readings in each month over the last 3 months.",
        }

    month1, month2, month3 = averages
    if month1 is None or month2 is None or month3 is None:
        return {
            "alert": False,
            "trend": "insufficient_data",
            "reason": "Missing monthly averages.",
        }

    total_delta = month3 - month1
    rising = month1 < month2 < month3
    alert = rising and total_delta >= min_delta

    return {
        "alert": alert,
        "trend": "increasing" if rising else "not_increasing",
        "reason": (
            f"3-month averages: {month1:.2f} -> {month2:.2f} -> {month3:.2f}; "
            f"delta={total_delta:.2f}"
        ),
        "total_delta": total_delta,
    }
