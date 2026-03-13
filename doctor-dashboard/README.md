# Doctor Dashboard

React dashboard for doctor workflows in the Unified PHR platform.

## Key Modules

- Dashboard overview (active consents, pending requests, alerts)
- Consent orchestration with:
  - Category/domain scope selection
  - Year/custom record range
  - Access start/end time window
- Patients list and consent-linked patient dashboard
- Consent-aware vitals chart, documents, AI insight card
- Appointment management (request queue, slot confirmation, overlap-safe allocation)
- Notifications and audit logs
- JSON snapshot export/copy from patient dashboard

## Run Locally

```bash
npm install
npm start
```

Default dev URL: `http://localhost:3000`

## Build

```bash
npm run build
```

## Backend Requirement

Set API base URL in service config to backend server (default project backend on port `8000`).
