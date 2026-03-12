# Unified PHR

This repository implements a **Unified Personal Health Record (PHR)** application featuring data orchestration, consent management (ABDM artefact), analytics, and notifications.  The system is composed of:

- **Backend** (FastAPI + MongoDB) providing APIs for authentication, health data ingestion, consent flows, analytics, alerts, and notifications.
- **Doctor dashboard** (React) allowing clinicians to request consents, view patient timelines, and receive notifications.
- **Patient app** (Flutter) enabling users to upload records, manage consents, view health timelines, and see alerts/notifications.

## Highlights

* **Data orchestration** – ingest wearable JSON, FHIR bundles, labs (PDFs), manual entries.
* **Normalization** – common health record schema with categories, metrics, timestamps.
* **ABDM consent artefact** – granular/time‑bound access; doctors request, patients approve/reject, automatic expiry and revocation.
* **Proactive analytics** – trend detection (e.g., rising resting heart rate) triggers alerts and notifications.
* **Notifications** – users and doctors receive in‑app alerts about consent requests, approvals, revocations, and health warnings.
* **File upload support** – PDF reports and documents stored and made available via secure URLs.

## Getting Started

Backend:

```bash
cd backend
python -m venv venv
venv\Scripts\activate  # Windows
pip install -r requirements.txt
uvicorn app.main:app --reload
```

Frontend (doctor dashboard):

```bash
cd doctor-dashboard
npm install
npm start
```

Mobile (patient app):

```bash
cd frontend/patient-app
flutter pub get
flutter run
```

The above instructions are an overview; see each subproject's README for more details.
 
