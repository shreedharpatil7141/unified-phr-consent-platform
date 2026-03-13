# Quick Checklist (Updated)

Use this as a pre-demo sanity list.

## Backend

- [ ] Server starts without env/db errors
- [ ] `/docs` opens
- [ ] `/admin/health` returns healthy

## Auth

- [ ] Patient register/login works
- [ ] Doctor register/login works

## Consent

- [ ] Doctor can create consent request with:
  - [ ] Year/custom record range
  - [ ] Access from/to window
  - [ ] Scope categories/domains
- [ ] Patient can approve/reject request
- [ ] Doctor sees only consented data
- [ ] Expired/revoked consent blocks access

## Data and Timeline

- [ ] Wearable sync inserts vitals
- [ ] Lab/prescription/vaccine upload works
- [ ] Patient timeline shows combined records
- [ ] Doctor timeline shows consent-filtered records

## Alerts and AI

- [ ] 3-month heart-rate trend alert appears (with enough data)
- [ ] Notification text asks to book doctor appointment
- [ ] AI insight endpoints return content or valid fallback

## Appointments

- [ ] Patient can request appointment
- [ ] Doctor can confirm slot
- [ ] Overlapping slot is rejected
- [ ] Cancel/complete flows work
- [ ] Closed/expired appointment delete works

## Audit

- [ ] Doctor audit page loads data access + appointment activity
- [ ] Patient audit page loads data access + appointment activity

## UI Quality

- [ ] Doctor name visible in dashboard sidebar
- [ ] Patient dashboard/doctor dashboard timestamps look correct
- [ ] Radiology option visible in patient lab domain selector
