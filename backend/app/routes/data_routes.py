from fastapi import APIRouter, Depends, HTTPException
from datetime import datetime, timedelta
from app.config.database import db
from app.core.dependencies import require_role
from app.services.audit_service import log_audit_event, log_data_access, get_access_summary
from app.services.normalization_service import (
    normalize_category,
    normalize_domain,
    normalize_record_type,
    normalize_source,
)
import re

router = APIRouter(prefix="/data", tags=["Data Access"])

consent_collection = db["consents"]
health_collection = db["health_records"]
users_collection = db["users"]


REQUEST_TERM_ALIASES = {
    "documents": {
        "categories": ["lab_report", "lab_reports", "prescription", "prescriptions", "vaccination", "vaccines"],
        "domains": [],
    },
    "document": {
        "categories": ["lab_report", "lab_reports", "prescription", "prescriptions", "vaccination", "vaccines"],
        "domains": [],
    },
    "lab_reports": {
        "categories": ["lab_reports", "lab_report"],
        "domains": [],
    },
    "lab_report": {
        "categories": ["lab_report", "lab_reports"],
        "domains": [],
    },
    "prescriptions": {
        "categories": ["prescriptions", "prescription"],
        "domains": [],
    },
    "prescription": {
        "categories": ["prescription", "prescriptions"],
        "domains": [],
    },
    "vaccines": {
        "categories": ["vaccines", "vaccination"],
        "domains": ["wellness"],
    },
    "vaccination": {
        "categories": ["vaccination", "vaccines"],
        "domains": ["wellness"],
    },
    "cardiology": {
        "categories": ["lab_report", "lab_reports", "vitals"],
        "domains": ["cardiology", "cardiac"],
    },
    "cardiac": {
        "categories": ["lab_report", "lab_reports", "vitals"],
        "domains": ["cardiac", "cardiology"],
    },
    "hematology": {
        "categories": ["lab_report", "lab_reports"],
        "domains": ["hematology"],
    },
    "hemotology": {
        "categories": ["lab_report", "lab_reports"],
        "domains": ["hematology"],
    },
    "radiology": {
        "categories": ["lab_report", "lab_reports", "other"],
        "domains": ["radiology"],
    },
    "metabolic": {
        "categories": ["lab_report", "lab_reports", "vitals"],
        "domains": ["metabolic"],
    },
    "renal": {
        "categories": ["lab_report", "lab_reports"],
        "domains": ["renal"],
    },
    "hepatic": {
        "categories": ["lab_report", "lab_reports"],
        "domains": ["hepatic"],
    },
    "respiratory": {
        "categories": ["lab_report", "lab_reports", "vitals"],
        "domains": ["respiratory"],
    },
    "wellness": {
        "categories": ["lab_report", "lab_reports", "vitals", "vaccination", "vaccines"],
        "domains": ["wellness", "general"],
    },
    "general_wellness": {
        "categories": ["lab_report", "lab_reports", "vitals", "vaccination", "vaccines"],
        "domains": ["wellness", "general"],
    },
    "vitals": {
        "categories": ["vitals"],
        "domains": ["cardiac", "cardiology", "metabolic", "respiratory", "general", "wellness"],
    },
}


def expand_request_terms(request_terms):
    categories = []
    domains = []
    for term in request_terms:
        alias = REQUEST_TERM_ALIASES.get(term, {"categories": [term], "domains": [term]})
        categories.extend(alias["categories"])
        domains.extend(alias["domains"])

    return {
        "categories": list(dict.fromkeys(categories)),
        "domains": list(dict.fromkeys(domains)),
    }


def _record_timestamp(record):
    timestamp = record.get("timestamp")
    if isinstance(timestamp, str):
        return datetime.fromisoformat(timestamp)
    return timestamp


def _infer_document_year(record) -> int | None:
    for key in ("record_name", "file_name", "notes"):
        value = str(record.get(key) or "")
        match = re.search(r"(19|20)\d{2}", value)
        if match:
            try:
                return int(match.group(0))
            except ValueError:
                continue
    return None


def _matches_requested_term(record, term: str) -> bool:
    category = normalize_category(record.get("category"))
    domain = normalize_domain(record.get("domain"))
    record_type = normalize_record_type(record.get("record_type") or record.get("type"))
    source = normalize_source(record.get("source"))
    has_file = bool(record.get("file_name") or record.get("file_url"))

    if term in {"lab_report", "lab_reports"}:
        return category == "lab_report"

    if term in {"prescription", "prescriptions"}:
        return category == "prescription"

    if term in {"vaccination", "vaccines", "vaccine"}:
        return category in {"vaccination", "vaccine"}

    if term in {"document", "documents"}:
        return category in {"lab_report", "prescription", "vaccination", "vaccine"} or has_file

    if term == "vitals":
        return (
            category == "vitals"
            or source in {"wearable", "manual"}
            or record_type in {"heart rate", "heart_rate", "steps", "distance", "sleep", "calories burned", "pulse rate", "pulse_rate"}
        ) and not has_file

    if term in {"cardiac", "cardiology"}:
        searchable = " ".join(
            [
                str(record.get("record_type") or ""),
                str(record.get("record_name") or ""),
                str(record.get("notes") or ""),
            ]
        ).lower()
        return (
            domain in {"cardiac", "cardiology"}
            or ("ecg" in searchable or "echo" in searchable or "cholesterol" in searchable or "lipid" in searchable or "troponin" in searchable)
            or (
                not has_file and (
                    category == "vitals"
                    or source in {"wearable", "manual"}
                    or record_type in {"heart rate", "heart_rate", "ecg", "pulse rate", "pulse_rate"}
                )
            )
        )

    if term in {"hematology", "radiology", "metabolic", "renal", "hepatic", "respiratory"}:
        return domain == term

    if term in {"wellness", "general_wellness", "general"}:
        if domain in {"wellness", "general"}:
            return True
        if term == "wellness" and category in {"vaccination", "vaccine"}:
            return True
        return domain == term

    return category == term or domain == term or record_type == term


def _record_is_within_consent(record, consent) -> bool:
    if _uses_legacy_access_window(consent):
        return True

    timestamp = _record_timestamp(record)
    if not timestamp:
        return False

    date_from = consent.get("date_from")
    date_to = consent.get("date_to")

    if date_from and timestamp < date_from:
        if record.get("file_name") or record.get("file_url"):
            inferred_year = _infer_document_year(record)
            if inferred_year is not None and date_from.year <= inferred_year <= (date_to.year if date_to else inferred_year):
                return True
        return False
    if date_to and timestamp > date_to:
        if record.get("file_name") or record.get("file_url"):
            inferred_year = _infer_document_year(record)
            if inferred_year is not None and (date_from.year if date_from else inferred_year) <= inferred_year <= date_to.year:
                return True
        return False
    return True


def _uses_legacy_access_window(consent) -> bool:
    date_from = consent.get("date_from")
    date_to = consent.get("date_to")
    access_duration_minutes = consent.get("access_duration_minutes")

    if not date_from or not date_to or not access_duration_minutes:
        return False

    try:
        requested_minutes = int((date_to - date_from).total_seconds() / 60)
    except Exception:
        return False

    # Older doctor dashboard requests used the selected date range to also compute
    # access duration, which unintentionally filtered out historical vitals. When the
    # two values match exactly, treat that consent as a legacy access-window request.
    return abs(requested_minutes - access_duration_minutes) <= 1


def _filter_records_for_consent(records, consent):
    requested_terms = [term.lower() for term in consent.get("categories", [])]
    filtered_records = []

    for record in records:
        matched = any(_matches_requested_term(record, term) for term in requested_terms)
        if not matched:
            continue

        if _record_is_within_consent(record, consent):
            filtered_records.append(record)

    return filtered_records


def build_doctor_summary(records):
    if not records:
        return "No shared records are available for this consent."

    summary_parts = [f"{len(records)} shared records available"]

    heart_values = []
    for record in records:
        record_type = (record.get("record_type") or record.get("type") or "").lower()
        if record_type in {"heart rate", "heart_rate", "pulse rate", "pulse_rate"}:
            try:
                heart_values.append(float(record.get("value", 0)))
            except (TypeError, ValueError):
                continue

    if heart_values:
        avg = sum(heart_values) / len(heart_values)
        summary_parts.append(
            f"heart rate ranges from {min(heart_values):.0f} to {max(heart_values):.0f} bpm with an average of {avg:.0f} bpm"
        )

    document_count = sum(1 for record in records if record.get("file_name") or record.get("file_url"))
    if document_count:
        summary_parts.append(f"{document_count} uploaded document(s) are included")

    domains = [
        record.get("domain")
        for record in records
        if record.get("domain")
    ]
    unique_domains = list(dict.fromkeys(domains))
    if unique_domains:
        summary_parts.append(f"domains covered: {', '.join(unique_domains[:4])}")

    return ". ".join(summary_parts) + "."


def build_backend_vitals_summary(records):
    vital_types = {
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

    summary = {
        "total_vitals": 0,
        "heart_rate_count": 0,
        "latest_heart_rate_timestamp": None,
        "types": {},
        "sources": {},
    }

    for record in records:
        if record.get("file_name") or record.get("file_url"):
            continue

        record_type = (record.get("record_type") or record.get("type") or "").lower()
        source = (record.get("source") or "").lower()
        category = (record.get("category") or "").lower()

        is_vital = (
            category == "vitals"
            or source in {"smartwatch", "manual", "wearable"}
            or record_type in vital_types
        )

        if not is_vital:
            continue

        summary["total_vitals"] += 1
        summary["types"][record_type or "unknown"] = summary["types"].get(record_type or "unknown", 0) + 1
        summary["sources"][source or "unknown"] = summary["sources"].get(source or "unknown", 0) + 1

        if record_type in {"heart rate", "heart_rate", "pulse rate", "pulse_rate"}:
            summary["heart_rate_count"] += 1
            timestamp = _record_timestamp(record)
            if timestamp:
                summary["latest_heart_rate_timestamp"] = timestamp.isoformat()

    return summary


# --------------------------------------------
# Doctor views patient data using consent
# --------------------------------------------

@router.get("/view/{consent_id}")
def view_patient_data(
    consent_id: str,
    current_user: dict = Depends(require_role("doctor"))
):

    consent = consent_collection.find_one({"consent_id": consent_id})

    if not consent:
        raise HTTPException(status_code=404, detail="Consent not found")

    if consent["doctor_id"] != current_user["email"]:
        raise HTTPException(status_code=403, detail="Not authorized")

    if consent["status"] != "approved":
        raise HTTPException(status_code=403, detail="Consent not approved")

    # Auto-correct future access windows that drift due to timezone/UI mismatch:
    # align to approved_at + configured duration so approved consents are usable immediately.
    if (
        consent.get("access_from")
        and consent["access_from"] > datetime.utcnow()
        and consent.get("approved_at")
        and consent.get("access_duration_minutes")
    ):
        corrected_from = consent["approved_at"]
        corrected_to = corrected_from + timedelta(minutes=int(consent["access_duration_minutes"]))
        if corrected_to > datetime.utcnow():
            consent_collection.update_one(
                {"consent_id": consent_id},
                {
                    "$set": {
                        "access_from": corrected_from,
                        "access_to": corrected_to,
                        "expires_at": corrected_to,
                    }
                },
            )
            consent["access_from"] = corrected_from
            consent["access_to"] = corrected_to
            consent["expires_at"] = corrected_to

    if consent.get("access_from") and consent["access_from"] > datetime.utcnow():
        raise HTTPException(
            status_code=403,
            detail=f"Consent access window not started yet. Starts at {consent['access_from'].isoformat()} UTC"
        )

    if consent.get("expires_at") and consent["expires_at"] < datetime.utcnow():
        raise HTTPException(status_code=403, detail="Consent expired")

    patient_id = consent["patient_id"]
    allowed_categories = consent["categories"]
    patient_profile = users_collection.find_one(
        {"email": patient_id},
        {"_id": 0, "password": 0},
    ) or {}

    all_patient_records = list(
        health_collection.find({"patient_id": patient_id}, {"_id": 0}).sort("timestamp", 1)
    )
    backend_vitals_summary = build_backend_vitals_summary(all_patient_records)
    records = _filter_records_for_consent(all_patient_records, consent)

    # Keep file URLs relative so mobile/web clients can resolve them from their API base URL.
    for r in records:
        if r.get("file_name"):
            r["file_url"] = f"/uploads/{r['file_name']}"
        r["normalized_category"] = normalize_category(r.get("category"))
        r["normalized_record_type"] = normalize_record_type(r.get("record_type") or r.get("type"))
        r["normalized_source"] = normalize_source(r.get("source"))
        r["normalized_domain"] = normalize_domain(r.get("domain"))

    log_audit_event(
        event_type="consented_patient_data_viewed",
        actor_email=current_user["email"],
        actor_role="doctor",
        target_patient_id=patient_id,
        consent_id=consent_id,
        metadata={
            "shared_record_count": len(records),
            "allowed_categories": allowed_categories,
        },
    )

    # Log detailed data access for ABDM compliance
    log_data_access(
        doctor_id=current_user["email"],
        patient_id=patient_id,
        consent_id=consent_id,
        action="view_filtered_data",
        data_accessed=", ".join(allowed_categories),
        status="success",
        duration_seconds=None,
    )

    return {
        "patient_id": patient_id,
        "patient_profile": patient_profile,
        "allowed_categories": allowed_categories,
        "consent_status": consent["status"],
        "consent_expires_at": consent.get("expires_at"),
        "consent_approved_at": consent.get("approved_at"),
        "records": records,
        "insight_summary": build_doctor_summary(records),
        "backend_vitals_summary": backend_vitals_summary,
    }


# --------------------------------------------
# Patient views their own records
# --------------------------------------------

@router.get("/my-records")
def get_my_records(
    current_user: dict = Depends(require_role("patient"))
):

    records = list(
        health_collection.find(
            {"patient_id": current_user["email"]},
            {"_id": 0}
        ).sort("timestamp", 1)
    )

    # Keep file URLs relative so mobile/web clients can resolve them from their API base URL.
    for r in records:
        if r.get("file_name"):
            r["file_url"] = f"/uploads/{r['file_name']}"
        r["normalized_category"] = normalize_category(r.get("category"))
        r["normalized_record_type"] = normalize_record_type(r.get("record_type") or r.get("type"))
        r["normalized_source"] = normalize_source(r.get("source"))
        r["normalized_domain"] = normalize_domain(r.get("domain"))

    return records
