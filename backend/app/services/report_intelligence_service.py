from __future__ import annotations

import os
import re
from typing import Any

from app.services.normalization_service import normalize_domain, normalize_record_type


REPORT_PATTERNS = {
    "cardiac": ["ecg", "echo", "cardiac", "cholesterol", "lipid", "troponin"],
    "hematology": ["cbc", "hemoglobin", "platelet", "hematology", "blood count"],
    "radiology": ["xray", "ct", "mri", "ultrasound", "scan", "radiology"],
    "renal": ["creatinine", "urea", "kidney", "renal"],
    "hepatic": ["liver", "hepatic", "bilirubin", "sgpt", "sgot"],
    "metabolic": ["glucose", "hba1c", "diabetes", "metabolic", "sugar"],
}


def infer_report_intelligence(
    filename: str,
    record_name: str | None = None,
    notes: str | None = None,
) -> dict[str, Any]:
    searchable = " ".join(
        part for part in [filename, record_name or "", notes or ""] if part
    ).lower()
    cleaned_text = re.sub(r"[_\-]+", " ", searchable)

    inferred_domain = "general"
    inferred_tags: list[str] = []
    confidence = 0.2

    for domain, patterns in REPORT_PATTERNS.items():
        matches = [pattern for pattern in patterns if pattern in cleaned_text]
        if matches:
            inferred_domain = domain
            inferred_tags = matches
            confidence = min(0.35 + 0.12 * len(matches), 0.92)
            break

    extension = os.path.splitext(filename)[1].lower().replace(".", "")
    inferred_type = "lab_report"
    if "ecg" in cleaned_text:
        inferred_type = "ecg"

    return {
        "ocr_status": "heuristic_metadata_only",
        "report_intelligence": {
            "inferred_domain": normalize_domain(inferred_domain),
            "inferred_type": normalize_record_type(inferred_type),
            "confidence": round(confidence, 2),
            "tags": inferred_tags,
            "keywords": cleaned_text.split()[:20],
        },
    }
