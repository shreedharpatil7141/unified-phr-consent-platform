from fastapi import APIRouter, Depends, HTTPException, UploadFile, File, Form
from datetime import datetime
from uuid import uuid4
import os
from typing import Optional

from pydantic import BaseModel

from app.config.database import db
from app.models.health_record_model import HealthRecord
from app.core.dependencies import require_role
from app.services.audit_service import log_audit_event
from app.services.normalization_service import (
    normalize_category,
    normalize_domain,
    normalize_health_record_payload,
    normalize_record_type,
    normalize_source,
    normalize_unit,
)
from app.services.report_intelligence_service import infer_report_intelligence
from app.services.trend_monitor_service import (
    compute_three_month_metric_summary,
    evaluate_three_month_increasing_trend,
)

router = APIRouter(prefix="/health", tags=["Health Records"])

health_collection = db["health_records"]

from app.services.data_orchestrator import ingest_wearable_data, ingest_fhir_bundle, ingest_pdf_report


class WearableSyncItem(BaseModel):
    source: str
    category: str
    record_type: str
    domain: str
    value: str
    unit: Optional[str] = ""
    timestamp: datetime
    provider: Optional[str] = None


class WearableSyncRequest(BaseModel):
    records: list[WearableSyncItem]


SYNCED_VITAL_TYPES = {
    "heart rate",
    "heart_rate",
    "pulse rate",
    "pulse_rate",
    "steps",
    "distance",
    "sleep",
    "calories burned",
    "calories_burned",
}


def _maybe_create_three_month_alert(patient_id: str, metric_name: str, now: datetime | None = None) -> dict | None:
    now = now or datetime.utcnow()
    summary = compute_three_month_metric_summary(
        health_collection,
        patient_id=patient_id,
        metric_name=metric_name,
        now=now,
    )
    evaluation = evaluate_three_month_increasing_trend(summary)
    if not evaluation["alert"]:
        return None

    metric_key = (metric_name or "").strip().lower().replace("-", "_").replace(" ", "_")
    existing_alert = db["alerts"].find_one(
        {
            "patient_id": patient_id,
            "metric": metric_key,
            "status": "active",
            "created_at": {"$gte": now.replace(hour=0, minute=0, second=0, microsecond=0)},
        }
    )
    if existing_alert:
        return None

    alert_data = {
        "alert_id": str(uuid4()),
        "patient_id": patient_id,
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
        "status": "active",
    }
    db["alerts"].insert_one(alert_data)
    db["notifications"].insert_one({
        "notification_id": str(uuid4()),
        "user_id": patient_id,
        "message": alert_data["message"],
        "created_at": datetime.utcnow(),
        "read": False
    })
    return alert_data


def _prepare_record_data(record: HealthRecord):
    record_data = record.dict()
    record_data["source"] = normalize_source(record_data.get("source"))
    record_data["category"] = normalize_category(record_data.get("category"))
    record_data["record_type"] = normalize_record_type(record.record_type)
    record_data["type"] = record_data["record_type"]
    record_data["domain"] = normalize_domain(record_data.get("domain"))

    if record.metrics:
        primary_metric = record.metrics[0]
        record_data["value"] = primary_metric.value
        record_data["unit"] = normalize_unit(primary_metric.unit)
    elif record.value is not None:
        record_data["value"] = record.value
        record_data["unit"] = normalize_unit(record.unit or "")

    return normalize_health_record_payload(record_data)


def _find_duplicate_record(record_data: dict):
    duplicate_query = {
        "patient_id": record_data["patient_id"],
        "source": record_data["source"],
        "category": record_data["category"],
        "record_type": record_data["record_type"],
        "timestamp": record_data["timestamp"],
    }

    if record_data.get("value") is not None:
        duplicate_query["value"] = record_data.get("value")

    return health_collection.find_one(duplicate_query, {"_id": 0, "record_id": 1})


def _build_vitals_sync_summary(patient_id: str):
    records = list(
        health_collection.find(
            {
                "patient_id": patient_id,
                "$or": [
                    {"category": "vitals"},
                    {"source": {"$in": ["smartwatch", "wearable", "manual"]}},
                ],
            },
            {"_id": 0, "record_type": 1, "type": 1, "timestamp": 1, "source": 1},
        ).sort("timestamp", 1)
    )

    by_type = {}
    total_records = 0

    last_sync_at = None

    for record in records:
        metric_type = (record.get("record_type") or record.get("type") or "").strip().lower()
        if metric_type not in SYNCED_VITAL_TYPES:
            continue

        total_records += 1
        bucket = by_type.setdefault(
            metric_type,
            {
                "count": 0,
                "latest_timestamp": None,
                "sources": set(),
            },
        )
        bucket["count"] += 1
        bucket["sources"].add(record.get("source") or "unknown")

        timestamp = record.get("timestamp")
        if isinstance(timestamp, datetime):
            bucket["latest_timestamp"] = timestamp.isoformat()
            if last_sync_at is None or timestamp > last_sync_at:
                last_sync_at = timestamp
        elif timestamp:
            bucket["latest_timestamp"] = str(timestamp)

    formatted = {
        metric_type: {
            "count": values["count"],
            "latest_timestamp": values["latest_timestamp"],
            "sources": sorted(values["sources"]),
        }
        for metric_type, values in by_type.items()
    }

    return {
        "patient_id": patient_id,
        "total_vital_records": total_records,
        "last_sync_at": last_sync_at.isoformat() if last_sync_at else None,
        "types": formatted,
    }

@router.post("/add")
def add_health_record(
    record: HealthRecord,
    current_user: dict = Depends(require_role("patient"))
):
    if record.patient_id != current_user["email"]:
        raise HTTPException(status_code=403, detail="Cannot add record for another patient")

    record_data = _prepare_record_data(record)
    existing = _find_duplicate_record(record_data)
    if existing:
        return {
            "message": "Health record already exists",
            "record_id": existing["record_id"],
        }

    record_data["record_id"] = str(uuid4())
    record_data["created_at"] = datetime.utcnow()

    health_collection.insert_one(record_data)
    log_audit_event(
        event_type="health_record_added",
        actor_email=current_user["email"],
        actor_role="patient",
        target_patient_id=record.patient_id,
        metadata={
            "record_id": record_data["record_id"],
            "category": record_data.get("category"),
            "record_type": record_data.get("record_type"),
            "source": record_data.get("source"),
        },
    )

    # after insertion, run 3-month trend check and generate alert/notification if needed
    if record.metrics:
        now = datetime.utcnow()
        for metric in record.metrics:
            _maybe_create_three_month_alert(record.patient_id, metric.name, now=now)

    return {
        "message": "Health record added successfully",
        "record_id": record_data["record_id"]
    }


@router.post("/sync-wearables")
def sync_wearables(
    payload: WearableSyncRequest,
    current_user: dict = Depends(require_role("patient"))
):
    inserted = 0
    skipped = 0

    for item in payload.records:
        record = HealthRecord(
            patient_id=current_user["email"],
            source=item.source,
            category=normalize_category(item.category),
            record_type=normalize_record_type(item.record_type),
            type=item.record_type,
            domain=normalize_domain(item.domain),
            provider=item.provider,
            timestamp=item.timestamp,
            metrics=[
                {
                    "name": normalize_record_type(item.record_type),
                    "value": float(item.value),
                    "unit": normalize_unit(item.unit or ""),
                }
            ],
            value=item.value,
            unit=normalize_unit(item.unit or ""),
        )

        record_data = _prepare_record_data(record)
        existing = _find_duplicate_record(record_data)
        if existing:
            skipped += 1
            continue

        record_data["record_id"] = str(uuid4())
        record_data["created_at"] = datetime.utcnow()
        health_collection.insert_one(record_data)
        inserted += 1

    log_audit_event(
        event_type="wearable_sync_completed",
        actor_email=current_user["email"],
        actor_role="patient",
        target_patient_id=current_user["email"],
        metadata={
            "inserted": inserted,
            "skipped": skipped,
            "record_count": len(payload.records),
        },
    )

    now = datetime.utcnow()
    _maybe_create_three_month_alert(current_user["email"], "heart_rate", now=now)
    _maybe_create_three_month_alert(current_user["email"], "pulse_rate", now=now)

    return {
        "message": "Wearable sync complete",
        "inserted": inserted,
        "skipped": skipped,
    }


@router.get("/vitals-sync-summary")
def get_vitals_sync_summary(
    current_user: dict = Depends(require_role("patient"))
):
    return _build_vitals_sync_summary(current_user["email"])


@router.post("/upload")
def upload_health_file(
    file: UploadFile = File(...),
    patient_id: str = Form(...),
    category: str = Form(...),
    record_type: str = Form(...),
    domain: str = Form("general"),
    provider: str = Form(None),
    record_name: str = Form(None),
    doctor: str = Form(None),
    hospital: str = Form(None),
    notes: str = Form(None),
    current_user: dict = Depends(require_role("patient"))
):
    # only allowed if patient matches
    if patient_id != current_user["email"]:
        raise HTTPException(status_code=403, detail="Cannot upload for another patient")

    # save file
    upload_dir = "uploads"
    os.makedirs(upload_dir, exist_ok=True)
    filename = f"{str(uuid4())}_{file.filename}"
    filepath = os.path.join(upload_dir, filename)
    with open(filepath, "wb") as f:
        f.write(file.file.read())

    report_intelligence = infer_report_intelligence(
        filename=file.filename,
        record_name=record_name,
        notes=notes,
    )
    normalized_domain = normalize_domain(domain or report_intelligence["report_intelligence"]["inferred_domain"])
    normalized_record_type = normalize_record_type(
        record_type or report_intelligence["report_intelligence"]["inferred_type"]
    )

    record = HealthRecord(
        patient_id=patient_id,
        source="file",
        category=normalize_category(category),
        record_type=normalized_record_type,
        domain=normalized_domain,
        provider=provider,
        timestamp=datetime.utcnow(),
        metrics=None,
        notes=notes,
        file_name=filename,
        record_name=record_name or file.filename,
        file_url=f"/uploads/{filename}",
        doctor=doctor,
        hospital=hospital,
    )

    # reuse add logic by inserting directly
    record_data = record.dict()
    record_data.update(report_intelligence)
    record_data["record_id"] = str(uuid4())
    record_data["created_at"] = datetime.utcnow()
    record_data = normalize_health_record_payload(record_data)
    health_collection.insert_one(record_data)
    log_audit_event(
        event_type="health_document_uploaded",
        actor_email=current_user["email"],
        actor_role="patient",
        target_patient_id=patient_id,
        metadata={
            "record_id": record_data["record_id"],
            "category": record_data.get("category"),
            "record_type": record_data.get("record_type"),
            "domain": record_data.get("domain"),
            "ocr_status": record_data.get("ocr_status"),
        },
    )

    return {
        "message": "File uploaded",
        "record_id": record_data["record_id"],
        "file_url": record_data["file_url"],
        "report_intelligence": record_data.get("report_intelligence"),
        "ocr_status": record_data.get("ocr_status"),
    }


@router.delete("/record/{record_id}")
def delete_health_record(
    record_id: str,
    current_user: dict = Depends(require_role("patient"))
):
    record = health_collection.find_one({"record_id": record_id})

    if not record:
        raise HTTPException(status_code=404, detail="Record not found")

    if record.get("patient_id") != current_user["email"]:
        raise HTTPException(status_code=403, detail="Cannot delete another patient's record")

    file_name = record.get("file_name")
    if file_name:
        file_path = os.path.join("uploads", file_name)
        if os.path.exists(file_path):
            os.remove(file_path)

    health_collection.delete_one({"record_id": record_id})
    log_audit_event(
        event_type="health_record_deleted",
        actor_email=current_user["email"],
        actor_role="patient",
        target_patient_id=current_user["email"],
        metadata={
            "record_id": record_id,
            "category": record.get("category"),
            "record_type": record.get("record_type"),
        },
    )
    return {"message": "Record deleted", "record_id": record_id}


@router.post("/import")
def import_records(
    patient_id: str,
    source: str,
    payload: dict,
    current_user: dict = Depends(require_role("patient"))
):
    """Generic import endpoint; payload structure depends on source type"""
    if patient_id != current_user["email"]:
        raise HTTPException(status_code=403, detail="Cannot import for another patient")

    if source == "wearable":
        records = ingest_wearable_data(patient_id, payload.get("device", "unknown"), payload.get("data", []))
    elif source == "fhir":
        records = ingest_fhir_bundle(patient_id, payload)
    elif source == "pdf":
        # expect payload {"pdf_path":..., "category":...}
        rec = ingest_pdf_report(patient_id, payload.get("pdf_path"), payload.get("category", "general"))
        records = [rec]
    else:
        raise HTTPException(status_code=400, detail="Unsupported source")

    return {"imported": len(records), "records": records}
@router.get("/my-records")
def get_my_records(
    current_user: dict = Depends(require_role("patient"))
):
    raw = health_collection.find(
            {"patient_id": current_user["email"]},
            {"_id": 0}
        ).sort("timestamp", 1)
    
    # convert to list and ensure file_url is present for old file records
    records = []
    for r in raw:
        if "file_name" in r and "file_url" not in r:
            r["file_url"] = f"/uploads/{r['file_name']}"
        records.append(r)

    return records
