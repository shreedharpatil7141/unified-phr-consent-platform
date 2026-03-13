# API Documentation - Compliance and Core Flows (Updated)

This file summarizes the API behavior used in demos and hackathon validation.

## 1) ABDM-style Consent Flow

1. Doctor sends request: `POST /consent/request`
2. Patient acts: `POST /consent/{id}/approve` or `POST /consent/{id}/reject`
3. Doctor accesses scoped data: `GET /data/view/{consent_id}`
4. Patient can revoke anytime: `POST /consent/{id}/revoke`
5. Expired/rejected/revoked records can be deleted.

Consent request supports:

- scoped categories/domains (`cardiac`, `hematology`, `radiology`, etc.)
- data date range (`date_from` / `date_to`)
- explicit access window (`access_from` / `access_to`)

## 2) Audit Visibility

### Doctor

- `GET /consent/audit-logs/my-accesses?days_back=30`

### Patient

- `GET /consent/audit-logs/patient-accesses?days_back=30`

### Consent-specific trail

- `GET /consent/audit-logs/consent-audit/{consent_id}`

## 3) Appointments

- Patient requests: `POST /appointments/request`
- Doctor confirms with slot: `POST /appointments/{id}/confirm`
- Slot conflict protection blocks overlapping confirmed slots per doctor.
- Closed/expired appointments can be deleted: `DELETE /appointments/{id}`

## 4) Preventive Alerts

- Heart-rate trend check uses a 90-day window split into 3 monthly buckets.
- Alert condition:
  - at least 3 readings per month bucket
  - strictly increasing monthly averages
  - total delta >= 3 bpm
- Trigger sources:
  - `POST /health/add`
  - `POST /health/sync-wearables`
- Manual trigger endpoint: `POST /alerts/generate/{metric_name}`

## 5) Notifications

- `GET /notifications/my`
- `POST /notifications/mark-read/{notification_id}`
- `DELETE /notifications/{notification_id}`

Notification events include consent lifecycle, appointment events, and health alerts.

## 6) AI Endpoints

- Patient insight: `POST /ai/insight`
- Doctor consented insight: `GET /ai/doctor-consent-insight/{consent_id}`

If OpenAI key is missing/unavailable, endpoints return a local fallback summary.

## 7) Operational Endpoints

- Health check: `GET /admin/health`
- Security/compliance summary: `GET /admin/security-status`

## Authentication Reminder

Use bearer token on protected routes:

```http
Authorization: Bearer <JWT_TOKEN>
```
