import json
import os
from pathlib import Path
from urllib import error, request

from dotenv import load_dotenv
from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel, Field

from app.core.dependencies import require_role
from app.services.audit_service import log_audit_event
from app.config.database import db
from app.routes.data_routes import _filter_records_for_consent

BASE_DIR = Path(__file__).resolve().parent.parent.parent
PROJECT_ROOT = BASE_DIR.parent
load_dotenv(BASE_DIR / ".env")
load_dotenv(PROJECT_ROOT / ".env")

router = APIRouter(prefix="/ai", tags=["AI"])

OPENAI_API_URL = "https://api.openai.com/v1/responses"


class InsightRequest(BaseModel):
    metric: str = Field(..., min_length=1)
    values: list[float] = Field(default_factory=list)
    unit: str = ""
    range_label: str = ""


def _get_openai_settings() -> tuple[str, str]:
    api_key = (
        os.getenv("OPENAI_API_KEY")
        or os.getenv("OPENAI_APIKEY")
        or os.getenv("OPENAI_KEY")
        or ""
    ).strip()
    model = (os.getenv("OPENAI_MODEL") or "gpt-5-mini").strip() or "gpt-5-mini"
    return api_key, model


def _extract_heart_rate_values(records: list[dict]) -> list[float]:
    values: list[float] = []
    for record in records:
        record_type = str(record.get("record_type") or record.get("type") or "").lower()
        if record_type in {"heart rate", "heart_rate", "pulse rate", "pulse_rate"}:
            try:
                values.append(float(record.get("value")))
            except (TypeError, ValueError):
                continue
            continue

        metrics = record.get("metrics") or []
        if not isinstance(metrics, list):
            metrics = []

        for metric in metrics:
            name = str(metric.get("name") or "").lower()
            if name in {"heart rate", "heart_rate", "pulse rate", "pulse_rate"}:
                try:
                    values.append(float(metric.get("value")))
                except (TypeError, ValueError):
                    continue
    return values


def _compute_risk(values: list[float]) -> tuple[int, str]:
    if not values:
        return 0, "none"
    avg = sum(values) / len(values)
    max_v = max(values)
    min_v = min(values)
    score = 100
    if avg > 95:
        score -= 15
    if max_v > 110:
        score -= 12
    if max_v - min_v > 35:
        score -= 8
    score = max(30, min(99, score))
    tone = "safe" if score >= 80 else "warning" if score >= 65 else "critical"
    return score, tone


def _build_prompt(payload: InsightRequest) -> str:
    values = payload.values[-30:]
    average = sum(values) / len(values) if values else 0
    minimum = min(values) if values else 0
    maximum = max(values) if values else 0

    return (
        "You are a preventive health assistant inside a personal health record app. "
        "Provide a short, patient-friendly insight in 2 sentences max. "
        "Do not diagnose. Mention patterns only if supported by the readings. "
        "If the data is too sparse, say that clearly.\n\n"
        f"Metric: {payload.metric}\n"
        f"Unit: {payload.unit or 'unknown'}\n"
        f"Selected range: {payload.range_label or 'recent period'}\n"
        f"Readings count: {len(values)}\n"
        f"Average: {average:.2f}\n"
        f"Minimum: {minimum:.2f}\n"
        f"Maximum: {maximum:.2f}\n"
        f"Readings: {values}\n"
    )


def _extract_output_text(response_data: dict) -> str:
    output_text = response_data.get("output_text")
    if isinstance(output_text, str) and output_text.strip():
        return output_text.strip()

    for output_item in response_data.get("output", []):
        for content in output_item.get("content", []):
            text = content.get("text")
            if isinstance(text, str) and text.strip():
                return text.strip()

    return ""


def _build_fallback_insight(payload: InsightRequest) -> str:
    values = payload.values[-30:]
    if not values:
        return f"No data available for {payload.metric}."

    average = sum(values) / len(values)
    minimum = min(values)
    maximum = max(values)
    latest = values[-1]
    unit = payload.unit or ""
    range_text = payload.range_label or "the selected range"

    if payload.metric.lower() == "heart rate":
        spread = maximum - minimum
        if spread >= 25:
            return (
                f"Across {range_text}, your heart rate averaged {average:.0f} {unit} "
                f"with noticeable variation between {minimum:.0f} and {maximum:.0f} {unit}. "
                f"Keep tracking trends over the next few days."
            )
        return (
            f"Across {range_text}, your heart rate is fairly steady with a latest reading of "
            f"{latest:.0f} {unit} and an average of {average:.0f} {unit}."
        )

    return (
        f"For {payload.metric}, the latest value is {latest:.2f} {unit} and the average across "
        f"{range_text} is {average:.2f} {unit}, ranging from {minimum:.2f} to {maximum:.2f} {unit}."
    )


@router.post("/insight")
def generate_insight(
    payload: InsightRequest,
    current_user: dict = Depends(require_role("patient")),
):
    openai_api_key, openai_model = _get_openai_settings()

    if not payload.values:
        return {
            "insight": f"No data available for {payload.metric}.",
            "source": "local",
            "patient_id": current_user["email"],
            "clinical_safety": "insufficient_data",
        }

    if not openai_api_key:
        return {
            "insight": _build_fallback_insight(payload),
            "source": "local",
            "patient_id": current_user["email"],
            "clinical_safety": "fallback_summary",
            "warning": "OPENAI_API_KEY is not configured.",
        }

    body = {
        "model": openai_model,
        "input": _build_prompt(payload),
    }

    req = request.Request(
        OPENAI_API_URL,
        data=json.dumps(body).encode("utf-8"),
        headers={
            "Authorization": f"Bearer {openai_api_key}",
            "Content-Type": "application/json",
        },
        method="POST",
    )

    try:
        with request.urlopen(req, timeout=25) as response:
            response_data = json.loads(response.read().decode("utf-8"))
    except error.HTTPError as exc:
        detail = exc.read().decode("utf-8", errors="ignore")
        response = {
            "insight": _build_fallback_insight(payload),
            "source": "local",
            "warning": f"OpenAI request failed: {detail or exc.reason}",
            "patient_id": current_user["email"],
            "clinical_safety": "fallback_summary",
        }
        log_audit_event(
            event_type="ai_insight_generated",
            actor_email=current_user["email"],
            actor_role="patient",
            target_patient_id=current_user["email"],
            metadata={"source": response["source"], "metric": payload.metric},
        )
        return response
    except Exception as exc:
        response = {
            "insight": _build_fallback_insight(payload),
            "source": "local",
            "warning": "Failed to generate AI insight from OpenAI.",
            "patient_id": current_user["email"],
            "clinical_safety": "fallback_summary",
        }
        log_audit_event(
            event_type="ai_insight_generated",
            actor_email=current_user["email"],
            actor_role="patient",
            target_patient_id=current_user["email"],
            metadata={"source": response["source"], "metric": payload.metric},
        )
        return response

    insight = _extract_output_text(response_data)
    if not insight:
        response = {
            "insight": _build_fallback_insight(payload),
            "source": "local",
            "warning": "OpenAI returned an empty insight.",
            "patient_id": current_user["email"],
            "clinical_safety": "fallback_summary",
        }
        log_audit_event(
            event_type="ai_insight_generated",
            actor_email=current_user["email"],
            actor_role="patient",
            target_patient_id=current_user["email"],
            metadata={"source": response["source"], "metric": payload.metric},
        )
        return response

    response = {
        "insight": insight,
        "source": "openai",
        "model": openai_model,
        "patient_id": current_user["email"],
        "clinical_safety": "ai_assisted_non_diagnostic",
    }
    log_audit_event(
        event_type="ai_insight_generated",
        actor_email=current_user["email"],
        actor_role="patient",
        target_patient_id=current_user["email"],
        metadata={"source": response["source"], "metric": payload.metric},
    )
    return response


@router.get("/doctor-consent-insight/{consent_id}")
def doctor_consent_insight(
    consent_id: str,
    current_user: dict = Depends(require_role("doctor")),
):
    consents = db["consents"]
    records_collection = db["health_records"]

    consent = consents.find_one({"consent_id": consent_id})
    if not consent:
        raise HTTPException(status_code=404, detail="Consent not found")
    if consent.get("doctor_id") != current_user["email"]:
        raise HTTPException(status_code=403, detail="Not authorized for this consent")
    if consent.get("status") != "approved":
        raise HTTPException(status_code=403, detail="Consent not approved")

    patient_id = consent.get("patient_id")
    all_patient_records = list(
        records_collection.find({"patient_id": patient_id}, {"_id": 0}).sort("timestamp", 1)
    )
    shared_records = _filter_records_for_consent(all_patient_records, consent)
    heart_values = _extract_heart_rate_values(shared_records)

    if not heart_values:
        return {
            "source": "no_vitals",
            "insight": "No shared vitals are available in this consent scope, so AI trend analysis is not available.",
            "risk_score": None,
            "risk_tone": "none",
            "sample_size": 0,
            "metric": "heart_rate",
        }

    payload = InsightRequest(
        metric="heart rate",
        values=heart_values[-60:],
        unit="bpm",
        range_label="the consented dataset",
    )
    openai_api_key, openai_model = _get_openai_settings()
    risk_score, risk_tone = _compute_risk(heart_values)

    if not openai_api_key:
        return {
            "source": "local",
            "insight": _build_fallback_insight(payload),
            "risk_score": risk_score,
            "risk_tone": risk_tone,
            "sample_size": len(heart_values),
            "metric": "heart_rate",
            "warning": "OPENAI_API_KEY is not configured.",
        }

    body = {
        "model": openai_model,
        "input": _build_prompt(payload),
    }
    req = request.Request(
        OPENAI_API_URL,
        data=json.dumps(body).encode("utf-8"),
        headers={
            "Authorization": f"Bearer {openai_api_key}",
            "Content-Type": "application/json",
        },
        method="POST",
    )

    try:
        with request.urlopen(req, timeout=25) as response:
            response_data = json.loads(response.read().decode("utf-8"))
        insight = _extract_output_text(response_data) or _build_fallback_insight(payload)
        return {
            "source": "openai",
            "model": openai_model,
            "insight": insight,
            "risk_score": risk_score,
            "risk_tone": risk_tone,
            "sample_size": len(heart_values),
            "metric": "heart_rate",
        }
    except Exception:
        return {
            "source": "local",
            "insight": _build_fallback_insight(payload),
            "risk_score": risk_score,
            "risk_tone": risk_tone,
            "sample_size": len(heart_values),
            "metric": "heart_rate",
            "warning": "OpenAI insight generation failed; local fallback used.",
        }
