"""Simple orchestration helpers to ingest and normalize external health data sources."""
from datetime import datetime
from app.config.database import db
from app.models.health_record_model import HealthRecord
from uuid import uuid4

health_collection = db["health_records"]


def ingest_wearable_data(patient_id: str, device_type: str, data: list[dict]):
    """Accept JSON data from a wearable, normalize into HealthRecord(s) and store."""
    records = []
    for item in data:
        rec = HealthRecord(
            patient_id=patient_id,
            source=device_type,
            category="vitals",
            record_type=item.get("type", "metric"),
            provider=device_type,
            timestamp=datetime.fromisoformat(item.get("timestamp")),
            metrics=[
                HealthRecord.__fields__["metrics"].type_.__args__[0](
                    name=item.get("name"), value=item.get("value"), unit=item.get("unit", "")
                )
            ],
        )
        record_data = rec.dict()
        record_data["record_id"] = str(uuid4())
        record_data["created_at"] = datetime.utcnow()
        health_collection.insert_one(record_data)
        records.append(record_data)
    return records


def ingest_fhir_bundle(patient_id: str, bundle: dict):
    """Placeholder - convert FHIR bundle to internal records."""
    # For brevity, treat bundle as list of observations
    results = []
    for entry in bundle.get("entry", []):
        resource = entry.get("resource", {})
        if resource.get("resourceType") == "Observation":
            rec = HealthRecord(
                patient_id=patient_id,
                source="fhir",
                category=resource.get("category", [{}])[0].get("coding", [{}])[0].get("display", ""),
                record_type=resource.get("code", {}).get("text", ""),
                provider=resource.get("performer", [{}])[0].get("display"),
                timestamp=datetime.fromisoformat(resource.get("effectiveDateTime")),
                metrics=[
                    HealthRecord.__fields__["metrics"].type_.__args__[0](
                        name=resource.get("code", {}).get("text", ""),
                        value=resource.get("valueQuantity", {}).get("value", 0),
                        unit=resource.get("valueQuantity", {}).get("unit", ""),
                    )
                ],
            )
            record_data = rec.dict()
            record_data["record_id"] = str(uuid4())
            record_data["created_at"] = datetime.utcnow()
            health_collection.insert_one(record_data)
            results.append(record_data)
    return results


def ingest_pdf_report(patient_id: str, pdf_path: str, category: str):
    """Store a PDF file as a health record. Actual text extraction not implemented."""
    # simply place file metadata and treat as record with file attachment
    filename = pdf_path.split("/")[-1]
    rec = HealthRecord(
        patient_id=patient_id,
        source="lab",
        category=category,
        record_type="lab_report",
        provider="external",
        timestamp=datetime.utcnow(),
        metrics=None,
        notes="PDF imported",
        file_name=filename,
    )
    record_data = rec.dict()
    record_data["record_id"] = str(uuid4())
    record_data["created_at"] = datetime.utcnow()
    health_collection.insert_one(record_data)
    return record_data
