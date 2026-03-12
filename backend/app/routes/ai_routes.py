import json
import os
from pathlib import Path
from urllib import error, request

from dotenv import load_dotenv
from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel, Field

from app.core.dependencies import require_role
from app.services.audit_service import log_audit_event

BASE_DIR = Path(__file__).resolve().parent.parent.parent
load_dotenv(BASE_DIR / ".env")

router = APIRouter(prefix="/ai", tags=["AI"])

OPENAI_API_KEY = os.getenv("OPENAI_API_KEY", "")
OPENAI_MODEL = os.getenv("OPENAI_MODEL", "gpt-5-mini")
OPENAI_API_URL = "https://api.openai.com/v1/responses"


class InsightRequest(BaseModel):
    metric: str = Field(..., min_length=1)
    values: list[float] = Field(default_factory=list)
    unit: str = ""
    range_label: str = ""


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
    if not payload.values:
        return {
            "insight": f"No data available for {payload.metric}.",
            "source": "local",
            "patient_id": current_user["email"],
            "clinical_safety": "insufficient_data",
        }

    if not OPENAI_API_KEY:
        return {
            "insight": _build_fallback_insight(payload),
            "source": "local",
            "patient_id": current_user["email"],
            "clinical_safety": "fallback_summary",
        }

    body = {
        "model": OPENAI_MODEL,
        "input": _build_prompt(payload),
    }

    req = request.Request(
        OPENAI_API_URL,
        data=json.dumps(body).encode("utf-8"),
        headers={
            "Authorization": f"Bearer {OPENAI_API_KEY}",
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
        "model": OPENAI_MODEL,
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
