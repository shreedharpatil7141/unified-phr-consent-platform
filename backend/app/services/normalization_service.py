from __future__ import annotations

from datetime import datetime
from typing import Any


CATEGORY_MAP = {
    "lab reports": "lab_report",
    "lab_report": "lab_report",
    "lab reports ": "lab_report",
    "prescriptions": "prescription",
    "prescription": "prescription",
    "vaccines": "vaccination",
    "vaccine": "vaccination",
    "vaccination": "vaccination",
    "vitals": "vitals",
}

RECORD_TYPE_MAP = {
    "heart rate": "heart_rate",
    "pulse rate": "pulse_rate",
    "calories burned": "calories_burned",
    "lab report": "lab_report",
    "lab reports": "lab_report",
}

DOMAIN_MAP = {
    "cardiology": "cardiac",
    "cardiac": "cardiac",
    "general wellness": "wellness",
}

SOURCE_MAP = {
    "watch": "wearable",
    "smartwatch": "wearable",
    "health connect": "wearable",
    "manual": "manual",
    "file": "file",
}

UNIT_MAP = {
    "bpm": "bpm",
    "steps": "steps",
    "km": "km",
    "cal": "kcal",
    "kcal": "kcal",
    "hrs": "hours",
    "hours": "hours",
}


def _normalized_key(value: Any) -> str:
    return str(value or "").strip().lower().replace("-", " ").replace("_", " ")


def normalize_category(value: Any) -> str:
    key = _normalized_key(value)
    return CATEGORY_MAP.get(key, key.replace(" ", "_") if key else "general")


def normalize_record_type(value: Any) -> str:
    key = _normalized_key(value)
    return RECORD_TYPE_MAP.get(key, key.replace(" ", "_") if key else "unknown")


def normalize_domain(value: Any) -> str:
    key = _normalized_key(value)
    return DOMAIN_MAP.get(key, key.replace(" ", "_") if key else "general")


def normalize_source(value: Any) -> str:
    key = _normalized_key(value)
    return SOURCE_MAP.get(key, key.replace(" ", "_") if key else "unknown")


def normalize_unit(value: Any) -> str:
    key = _normalized_key(value)
    return UNIT_MAP.get(key, key)


def normalize_timestamp(value: Any) -> datetime | None:
    if isinstance(value, datetime):
        return value
    if isinstance(value, str) and value:
        try:
            return datetime.fromisoformat(value)
        except ValueError:
            return None
    return None


def normalize_numeric_value(value: Any) -> float | None:
    if value is None or value == "":
        return None
    try:
        return float(value)
    except (TypeError, ValueError):
        return None


def normalize_health_record_payload(record: dict) -> dict:
    normalized = dict(record)

    normalized["source"] = normalize_source(record.get("source"))
    normalized["category"] = normalize_category(record.get("category"))
    normalized["record_type"] = normalize_record_type(
        record.get("record_type") or record.get("type")
    )
    normalized["type"] = normalized["record_type"]
    normalized["domain"] = normalize_domain(record.get("domain"))
    normalized["unit"] = normalize_unit(record.get("unit"))

    timestamp = normalize_timestamp(record.get("timestamp"))
    if timestamp:
      normalized["timestamp"] = timestamp

    numeric_value = normalize_numeric_value(record.get("value"))
    if numeric_value is not None:
        normalized["value"] = numeric_value

    return normalized
