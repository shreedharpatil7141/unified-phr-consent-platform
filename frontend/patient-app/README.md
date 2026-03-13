# Patient App (Flutter)

Flutter app for patient-facing Unified PHR flows.

## Key Modules

- Home dashboard with vitals overview
- Health Connect / wearable sync to backend
- Health timeline and vitals history graphs
- Health locker:
  - Lab reports
  - Prescriptions
  - Vaccines
- Consent request handling (approve/reject/revoke)
- Alerts and notifications
- Appointments (request/cancel/delete closed)
- Family profile link management
- Patient audit visibility (data access + appointment activity)

## Run Locally

```bash
flutter pub get
flutter run
```

## Backend URL

Configured in:

- `lib/services/api_service.dart` via `API_BASE_URL` compile-time variable
- default fallback points to local backend

Example:

```bash
flutter run --dart-define=API_BASE_URL=http://192.168.0.102:8000
```
