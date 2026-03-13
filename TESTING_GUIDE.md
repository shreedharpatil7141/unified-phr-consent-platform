# Testing Guide (Updated)

## 1) Start Services

### Backend

```bash
cd backend
uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload
```

### Doctor Dashboard

```bash
cd doctor-dashboard
npm start
```

### Patient App

```bash
cd frontend/patient-app
flutter run
```

## 2) Smoke Tests

- Open backend docs: `http://localhost:8000/docs`
- Open doctor dashboard: `http://localhost:3000`
- Login works for doctor and patient users

## 3) Consent Scenario Test

1. Doctor sends consent request with scope + year/custom range + access window.
2. Patient approves in app.
3. Doctor opens patient dashboard from active consent.
4. Verify only scoped records are visible.
5. Wait past expiry and verify access is blocked.

## 4) 3-Month Heart Rate Alert Test

Precondition: at least 3 heart-rate readings in each 30-day bucket across last 90 days with increasing monthly averages.

Flow:
1. Sync wearables (`/health/sync-wearables`) or add records (`/health/add`).
2. Check patient notifications and `/alerts/my-alerts`.
3. Verify message suggests booking doctor appointment.

## 5) Appointment Test

1. Patient requests appointment.
2. Doctor confirms slot with start/end.
3. Try confirming overlapping slot for another patient; expect rejection.
4. Complete or cancel appointment.
5. Delete closed/expired appointment.

## 6) Audit Test

- Doctor audit page should show:
  - data access summary
  - appointment activity summary
- Patient audit page should show:
  - doctor access summary
  - appointment activity summary

## 7) Useful Health Endpoints

- `GET /admin/health`
- `GET /admin/security-status`

## 8) Known Preconditions

- MongoDB reachable and whitelisted
- Correct backend URL configured in patient app and doctor dashboard
- Valid JWT token in app sessions
