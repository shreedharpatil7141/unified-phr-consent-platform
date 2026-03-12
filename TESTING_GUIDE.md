# Quick Testing Guide - ABDM Audit Logging

## Start Backend Server

```bash
cd backend
python -m uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

---

## Test Endpoints

### 1. Health Check (No Authentication Required)
```bash
curl http://localhost:8000/admin/health
```
**Expected Response:**
```json
{
  "status": "healthy",
  "api_version": "1.0",
  "timestamp": "2026-03-11",
  "services": {
    "authentication": "✅ operational",
    "authorization": "✅ operational",
    "audit_logging": "✅ operational",
    "database": "✅ operational",
    "encryption": "✅ operational"
  },
  "message": "Unified PHR System is operational and ABDM-compliant"
}
```

---

### 2. Security Status (Doctor Authentication Required)

First, login as a doctor to get a token:
```bash
curl -X POST http://localhost:8000/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email": "doctor@example.com", "password": "password123"}'
```

Then use the token to get security status:
```bash
curl -H "Authorization: Bearer <TOKEN_FROM_LOGIN>" \
  http://localhost:8000/admin/security-status
```

**Expected Response:**
```json
{
  "status": "Security Configuration Report",
  "generated_by": "doctor@example.com",
  "generated_at": "2026-03-11T10:30:45Z",
  "security_features": {
    "authentication": "✅ JWT with 24h expiry",
    "authorization": "✅ Role-based access control",
    "audit_logging": "✅ All data accesses logged",
    "password_security": "✅ bcrypt with saltround=10",
    "data_in_transit": "✅ HTTPS/TLS required"
  },
  "compliance": {
    "abdm_consent_framework": "✅ Implemented",
    "access_transparency": "✅ Patients can see who accessed their data",
    "audit_trail": "✅ Complete access history available"
  },
  "production_recommendations": [
    "HIGH: Field-level encryption for SSN, DOB, diagnosis",
    "MEDIUM: Database backup and retention policies",
    "MEDIUM: Log aggregation and monitoring setup"
  ],
  "message": "This report confirms ABDM-compliant encryption and audit practices."
}
```

---

### 3. View Who Accessed Your Data (Patient View)

Patient logs in and requests access logs for themselves:
```bash
curl -X GET "http://localhost:8000/consent/audit-logs/patient-accesses?days_back=30" \
  -H "Authorization: Bearer <PATIENT_TOKEN>"
```

**Expected Response:**
```json
{
  "patient_id": "patient@example.com",
  "audit_summary": {
    "total_accesses": 5,
    "access_count_by_doctor": {
      "dr_john@hospital.com": 3,
      "dr_smith@clinic.com": 2
    },
    "access_count_by_action": {
      "view_filtered_data": 5
    },
    "date_range": {
      "from": "2026-02-09",
      "to": "2026-03-11"
    },
    "last_accessed": "2026-03-11T09:15:30Z",
    "generated_at": "2026-03-11T10:30:45Z"
  }
}
```

**What This Tells You:**
- 5 total data accesses in the last 30 days
- 2 doctors accessed your data
- Dr. John accessed 3 times, Dr. Smith accessed 2 times
- Patient can verify consent is being used appropriately

---

### 4. View Your Access History (Doctor View)

Doctor logs in and views all accesses they've made:
```bash
curl -X GET "http://localhost:8000/consent/audit-logs/my-accesses?days_back=30" \
  -H "Authorization: Bearer <DOCTOR_TOKEN>"
```

**Expected Response:**
```json
{
  "doctor_id": "dr_john@hospital.com",
  "audit_summary": {
    "total_accesses": 15,
    "access_count_by_patient": {
      "patient1@example.com": 5,
      "patient2@example.com": 4,
      "patient3@example.com": 6
    },
    "access_count_by_action": {
      "view_filtered_data": 15
    },
    "date_range": {
      "from": "2026-02-09",
      "to": "2026-03-11"
    },
    "last_accessed": "2026-03-11T09:15:30Z",
    "generated_at": "2026-03-11T10:30:45Z"
  }
}
```

**What This Tells You:**
- Doctor accessed data from 3 patients
- Total 15 accesses in the past 30 days
- Doctor can self-audit their compliance

---

### 5. Full Audit Trail for Specific Consent

Get detailed access history for a specific consent:
```bash
curl -X GET "http://localhost:8000/consent/audit-logs/consent-audit/<CONSENT_ID>" \
  -H "Authorization: Bearer <DOCTOR_OR_PATIENT_TOKEN>"
```

**Expected Response:**
```json
{
  "consent_id": "phr_consent_12345",
  "patient_id": "patient@example.com",
  "doctor_id": "dr_john@hospital.com",
  "consent_lifecycle": {
    "requested_at": "2026-03-01T10:00:00Z",
    "approved_at": "2026-03-01T11:30:00Z",
    "revoked_at": null,
    "expires_at": "2026-04-01T10:00:00Z",
    "status": "active"
  },
  "access_logs": [
    {
      "log_id": "log_001",
      "action": "view_filtered_data",
      "data_accessed": "VitalSigns, BloodPressure",
      "timestamp": "2026-03-01T14:20:30Z",
      "status": "success",
      "duration_seconds": 2.5
    },
    {
      "log_id": "log_002",
      "action": "view_filtered_data",
      "data_accessed": "VitalSigns, BloodPressure, LabReports",
      "timestamp": "2026-03-05T09:15:45Z",
      "status": "success",
      "duration_seconds": 3.1
    }
  ],
  "summary": {
    "total_accesses": 2,
    "first_accessed": "2026-03-01T14:20:30Z",
    "last_accessed": "2026-03-05T09:15:45Z",
    "categories_accessed": ["VitalSigns", "BloodPressure", "LabReports"]
  }
}
```

**What This Tells You:**
- Consent was requested and approved on March 1st
- Still valid (expires April 1st)
- Accessed 2 times
- Each access logged with timestamp and categories accessed

---

## Verification Steps

### ✅ Step 1: Verify Routes Are Registered
```bash
cd backend
python -c "from app.main import app; routes = [r.path for r in app.routes if 'admin' in r.path or 'audit' in r.path]; print('Registered Routes:', routes)"
```

Expected output:
```
Registered Routes: ['/admin/security-status', '/admin/health', '/consent/audit-logs/my-accesses', '/consent/audit-logs/patient-accesses', '/consent/audit-logs/consent-audit/{consent_id}']
```

### ✅ Step 2: Check Database Connection
When you access an endpoint, check MongoDB for new collections:
```bash
# In MongoDB Atlas dashboard or mongosh CLI:
db.access_logs.find().limit(1)
```

### ✅ Step 3: Verify Complete Data Flow

**Scenario: Doctor accesses patient data**
1. Doctor logs in → Gets JWT token
2. Doctor views consent for patient
3. Doctor accesses `/data/view/{consent_id}` → Data returned
4. Backend automatically logs to `access_logs` collection
5. Patient can verify access via `/consent/audit-logs/patient-accesses`

---

## Common Issues & Solutions

### Issue: 401 Unauthorized
**Cause:** Invalid or expired token
**Solution:** Login again and use new token

### Issue: 404 Not Found
**Cause:** Route not registered
**Solution:** Check admin_routes.py is imported in main.py

### Issue: No audit logs appearing
**Cause:** Database connection issue
**Solution:** Verify MongoDB URI in .env file, check connection

### Issue: CORS errors
**Cause:** Requests from different origin
**Solution:** CORS is configured to allow all origins in main.py

---

## Production Deployment Checklist

- [ ] Test all 5 endpoints with real user data
- [ ] Verify audit logs in MongoDB persist correctly
- [ ] Test patient access log visibility
- [ ] Test doctor access history
- [ ] Verify security status report shows correct info
- [ ] Configure log retention policy (e.g., 90 days)
- [ ] Set up log backup and archival
- [ ] Test audit trail immutability
- [ ] Configure monitoring/alerting for access logs
- [ ] Get security certification for production

---

## Endpoint Summary

| Endpoint | Method | Auth | Purpose |
|----------|--------|------|---------|
| `/admin/health` | GET | None | System health check |
| `/admin/security-status` | GET | Doctor | Security configuration report |
| `/consent/audit-logs/my-accesses` | GET | Doctor | Doctor's access history |
| `/consent/audit-logs/patient-accesses` | GET | Patient | See who accessed your data |
| `/consent/audit-logs/consent-audit/{id}` | GET | Both | Detailed consent audit trail |

---

## Next Steps

1. **Start the backend server** and test health endpoint (5 mins)
2. **Login as doctor** and test security status (5 mins)
3. **Verify audit logs** being created in MongoDB (5 mins)
4. **Test patient visibility** of access logs (5 mins)
5. **Review audit trail** for specific consent (5 mins)

**Total testing time:** ~25 minutes
