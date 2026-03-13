# Unified Personal Health Record (PHR)

This repository contains a multi-app implementation of a Unified PHR platform aligned to ABDM-style consent workflows.

## Project Structure

- `backend/` - FastAPI + MongoDB APIs
- `doctor-dashboard/` - React web app for doctors
- `frontend/patient-app/` - Flutter app for patients

## Current Feature Coverage

- Unified health records from wearables, uploaded reports, and manual inputs
- Normalized categories/domains/types across all data sources
- Consent request/approve/reject/revoke flows with date range + access window controls
- Doctor view with consent-filtered timeline/documents/vitals
- 3-month trend alerts for sustained increasing heart-rate patterns
- Appointment workflows (request, confirm slot, complete/cancel/delete closed)
- Family profile linking and overview APIs
- Patient and doctor audit visibility for data access activity
- Notifications for consent, appointments, and alert events

## Quick Start

### Backend

```bash
cd backend
python -m venv venv
venv\Scripts\activate
pip install -r requirements.txt
uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload
```

### Doctor Dashboard

```bash
cd doctor-dashboard
npm install
npm start
```

### Patient App

```bash
cd frontend/patient-app
flutter pub get
flutter run
```

## API Docs

- Interactive docs: `http://localhost:8000/docs`
- See also:
  - `API_ENDPOINTS.md`
  - `API_DOCUMENTATION.md`
  - `TESTING_GUIDE.md`
