# API Endpoints Reference (Updated)

Base URL: `http://localhost:8000`

All protected routes require:

```http
Authorization: Bearer <access_token>
```

## Auth

- `POST /auth/register` - Register patient/doctor
- `POST /auth/login` - Login (OAuth2 form body)

## User

- `GET /user/me` - Get own profile
- `PUT /user/me` - Update own profile

## Health Records

- `POST /health/add` - Add normalized health record
- `POST /health/sync-wearables` - Bulk wearable sync
- `GET /health/vitals-sync-summary` - Vitals sync stats
- `POST /health/upload` - Upload report file + metadata
- `POST /health/import` - Generic import helper
- `GET /health/my-records` - Patient records
- `DELETE /health/record/{record_id}` - Delete record

## Data Access (Consent-filtered)

- `GET /data/view/{consent_id}` - Doctor consent-scoped patient data
- `GET /data/my-records` - Patient unified records

## Consent

- `POST /consent/request` - Doctor creates consent request
- `POST /consent/{consent_id}/approve` - Patient approves
- `POST /consent/{consent_id}/reject` - Patient rejects
- `POST /consent/{consent_id}/revoke` - Patient revokes active consent
- `GET /consent/my-requests` - Patient-side consent list
- `GET /consent/sent` - Doctor-side consent list
- `DELETE /consent/{consent_id}` - Delete expired/rejected/revoked consent
- `DELETE /consent/expired/cleanup` - Doctor cleanup of expired consents

## Notifications

- `POST /notifications/create` - Internal notification helper
- `GET /notifications/my` - My notifications
- `POST /notifications/mark-read/{notification_id}` - Mark read
- `DELETE /notifications/{notification_id}` - Delete notification

## Alerts / Analytics / AI

- `GET /analytics/trend/{metric_name}` - 3-bucket trend analytics
- `POST /alerts/generate/{metric_name}` - Generate trend alert
- `GET /alerts/my-alerts` - Patient alerts
- `POST /ai/insight` - Patient AI insight
- `GET /ai/doctor-consent-insight/{consent_id}` - Doctor AI summary for consent dataset

## Appointments

- `POST /appointments/request` - Patient requests appointment
- `GET /appointments/my` - Patient appointments
- `GET /appointments/doctor` - Doctor appointments
- `POST /appointments/{appointment_id}/confirm` - Doctor confirms slot
- `POST /appointments/{appointment_id}/complete` - Doctor completes
- `POST /appointments/{appointment_id}/cancel` - Patient/doctor cancels
- `DELETE /appointments/{appointment_id}` - Delete closed/expired appointment

## Family Profiles

- `POST /family/request-link` - Send family link request
- `GET /family/requests/incoming` - Incoming requests
- `GET /family/requests/outgoing` - Outgoing requests
- `POST /family/requests/{link_id}/respond` - Accept/reject request
- `GET /family/linked-profiles` - Linked profile overview

## Admin / Operational

- `GET /admin/health` - Service health probe
- `GET /admin/security-status` - Security and compliance summary

## Notes

- Consent filtering supports category/domain aliases (e.g., cardiac/cardiology, lab report categories, wellness scopes).
- Heart-rate 3-month trend alert logic now applies to both manual adds and wearable sync flow.
