# API Documentation - ABDM Audit & Compliance Endpoints

## Overview
This document details the new audit logging and compliance endpoints added to support ABDM (Ayushman Bharat Digital Mission) requirements.

---

## Base URL
```
http://localhost:8000
```

## Authentication
All endpoints except `/admin/health` require JWT token in Authorization header:
```
Authorization: Bearer <JWT_TOKEN>
```

---

## Endpoints

### 1. Health Check
**Endpoint:** `GET /admin/health`
**Authentication:** None (Public)
**Rate Limit:** 100 requests/minute
**Purpose:** System health status check for monitoring

#### Request
```bash
curl http://localhost:8000/admin/health
```

#### Response
**Status:** 200 OK
```json
{
  "status": "healthy",
  "api_version": "1.0",
  "timestamp": "2026-03-11T10:30:45.123Z",
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

#### Response Codes
| Code | Meaning |
|------|---------|
| 200 | System is healthy |
| 503 | Database or critical service down |

---

### 2. Security Status Report
**Endpoint:** `GET /admin/security-status`
**Authentication:** Required (Doctor role)
**Rate Limit:** 10 requests/minute
**Purpose:** Comprehensive security and compliance status for audits

#### Request
```bash
curl -H "Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..." \
  http://localhost:8000/admin/security-status
```

#### Response
**Status:** 200 OK
```json
{
  "status": "Security Configuration Report",
  "generated_by": "dr_john@hospital.com",
  "generated_at": "2026-03-11T10:30:45.123Z",
  "security_features": {
    "authentication": "✅ JWT with 24-hour expiry (HS256)",
    "authorization": "✅ Role-based access control (Patient/Doctor)",
    "audit_logging": "✅ All data accesses logged with timestamp",
    "password_security": "✅ bcrypt hashing with saltround=10",
    "password_minimum_length": "✅ 8 characters enforced",
    "data_in_transit": "✅ HTTPS/TLS required",
    "api_rate_limiting": "✅ Configured per endpoint",
    "cors_security": "✅ Origin validation enabled",
    "file_storage_access": "✅ Controlled access to /uploads"
  },
  "compliance": {
    "abdm_consent_framework": {
      "status": "✅ Implemented",
      "details": "Full ABDM Consent Artefact support"
    },
    "granular_access_control": {
      "status": "✅ Implemented",
      "details": "Category + date range filtering per consent"
    },
    "access_transparency": {
      "status": "✅ Implemented",
      "details": "Patients can see all doctor accesses to their data"
    },
    "audit_trail": {
      "status": "✅ Implemented",
      "details": "Immutable access logs for all data views"
    },
    "doctor_audit_trail": {
      "status": "✅ Implemented",
      "details": "Doctors can review their access history"
    }
  },
  "production_recommendations": {
    "HIGH_PRIORITY": [
      "Implement field-level encryption for sensitive fields (SSN, DOB, medical_diagnosis)",
      "Set up encrypted database backups with off-site replication"
    ],
    "MEDIUM_PRIORITY": [
      "Configure audit log retention policy (recommend 90 days for compliance)",
      "Set up log aggregation and centralized monitoring",
      "Implement API request signing for non-repudiation"
    ],
    "NICE_TO_HAVE": [
      "ML-based anomaly detection for suspicious access patterns",
      "Blockchain-based immutable audit log archival",
      "Real-time compliance dashboard"
    ]
  },
  "message": "This report confirms ABDM-compliant encryption and audit practices."
}
```

#### Response Codes
| Code | Meaning |
|------|---------|
| 200 | Report generated successfully |
| 401 | Unauthorized (invalid/missing token) |
| 403 | Forbidden (insufficient permissions - doctor role required) |

---

### 3. Doctor Access History
**Endpoint:** `GET /consent/audit-logs/my-accesses`
**Authentication:** Required (Doctor role)
**Query Parameters:**
- `days_back` (optional, default=30): Number of days to look back
- `patient_id` (optional): Filter by specific patient
- `action` (optional): Filter by action type (e.g., "view_filtered_data")

**Rate Limit:** 50 requests/minute
**Purpose:** Doctors review their own data access history for self-audit compliance

#### Request
```bash
# Get all accesses in past 30 days
curl -H "Authorization: Bearer <TOKEN>" \
  "http://localhost:8000/consent/audit-logs/my-accesses?days_back=30"

# Get accesses for specific patient
curl -H "Authorization: Bearer <TOKEN>" \
  "http://localhost:8000/consent/audit-logs/my-accesses?patient_id=patient@example.com&days_back=60"
```

#### Response
**Status:** 200 OK
```json
{
  "doctor_id": "dr_john@hospital.com",
  "audit_summary": {
    "total_accesses": 24,
    "access_count_by_patient": {
      "patient1@example.com": 8,
      "patient2@example.com": 9,
      "patient3@example.com": 7
    },
    "access_count_by_action": {
      "view_filtered_data": 24
    },
    "access_count_by_category": {
      "VitalSigns": 18,
      "BloodPressure": 15,
      "LabReports": 12,
      "Diagnosis": 10
    },
    "access_count_by_date": {
      "2026-03-11": 4,
      "2026-03-10": 3,
      "2026-03-09": 5,
      "2026-03-08": 2,
      "2026-03-07": 3
    },
    "date_range": {
      "from": "2026-02-09",
      "to": "2026-03-11"
    },
    "earliest_access": "2026-02-09T08:30:15Z",
    "latest_access": "2026-03-11T15:42:30Z",
    "generated_at": "2026-03-11T16:45:30.123Z"
  }
}
```

#### Response Codes
| Code | Meaning |
|------|---------|
| 200 | Access logs retrieved successfully |
| 401 | Unauthorized (invalid/missing token) |
| 403 | Forbidden (doctor role required) |
| 404 | No access logs found for date range |

---

### 4. Patient Access Log Visibility
**Endpoint:** `GET /consent/audit-logs/patient-accesses`
**Authentication:** Required (Patient role)
**Query Parameters:**
- `days_back` (optional, default=30): Number of days to look back
- `doctor_id` (optional): Filter by specific doctor

**Rate Limit:** 50 requests/minute
**Purpose:** Patients see who accessed their data (ABDM transparency requirement)

#### Request
```bash
# See all doctors who accessed your data
curl -H "Authorization: Bearer <PATIENT_TOKEN>" \
  "http://localhost:8000/consent/audit-logs/patient-accesses?days_back=30"

# See accesses by specific doctor
curl -H "Authorization: Bearer <PATIENT_TOKEN>" \
  "http://localhost:8000/consent/audit-logs/patient-accesses?doctor_id=dr_john@hospital.com"
```

#### Response
**Status:** 200 OK
```json
{
  "patient_id": "patient@example.com",
  "audit_summary": {
    "total_accesses": 7,
    "access_count_by_doctor": {
      "dr_john@hospital.com": 4,
      "dr_sarah@clinic.com": 2,
      "dr_mike@hospital.com": 1
    },
    "access_count_by_action": {
      "view_filtered_data": 7
    },
    "access_count_by_category": {
      "VitalSigns": 7,
      "BloodPressure": 5,
      "LabReports": 3
    },
    "access_count_by_date": {
      "2026-03-10": 2,
      "2026-03-08": 3,
      "2026-03-05": 1,
      "2026-03-01": 1
    },
    "date_range": {
      "from": "2026-02-09",
      "to": "2026-03-11"
    },
    "earliest_access": "2026-03-01T14:20:15Z",
    "latest_access": "2026-03-10T09:45:30Z",
    "generated_at": "2026-03-11T16:45:30.123Z"
  },
  "doctors_accessed": [
    {
      "doctor_id": "dr_john@hospital.com",
      "hospital": "City Hospital",
      "accesses": 4,
      "first_access": "2026-03-01T14:20:15Z",
      "last_access": "2026-03-10T09:30:45Z",
      "categories_accessed": ["VitalSigns", "BloodPressure", "LabReports"]
    }
  ]
}
```

#### Response Codes
| Code | Meaning |
|------|---------|
| 200 | Audit log retrieved successfully |
| 401 | Unauthorized (invalid/missing token) |
| 403 | Forbidden (patient role required) |
| 404 | No access logs found |

---

### 5. Detailed Consent Audit Trail
**Endpoint:** `GET /consent/audit-logs/consent-audit/{consent_id}`
**Authentication:** Required (Both patient and doctor can access)
**Path Parameters:**
- `consent_id` (required): The ID of the consent to audit

**Query Parameters:**
- `include_all_logs` (optional, default=false): Include all historical logs

**Rate Limit:** 100 requests/minute
**Purpose:** Detailed audit trail for a specific consent (used by doctors, patients, and regulators)

#### Request
```bash
# Get audit trail for specific consent
curl -H "Authorization: Bearer <TOKEN>" \
  "http://localhost:8000/consent/audit-logs/consent-audit/phr_consent_abc123"

# Include all historical logs
curl -H "Authorization: Bearer <TOKEN>" \
  "http://localhost:8000/consent/audit-logs/consent-audit/phr_consent_abc123?include_all_logs=true"
```

#### Response
**Status:** 200 OK
```json
{
  "consent_id": "phr_consent_abc123",
  "patient_id": "patient@example.com",
  "doctor_id": "dr_john@hospital.com",
  "healthcare_provider": "City Hospital",
  "consent_lifecycle": {
    "requested_at": "2026-03-01T10:00:00Z",
    "requested_by": "dr_john@hospital.com",
    "approved_at": "2026-03-01T11:30:00Z",
    "approved_by": "patient@example.com",
    "revoked_at": null,
    "revoked_by": null,
    "expires_at": "2026-04-01T10:00:00Z",
    "status": "active",
    "categories": ["VitalSigns", "BloodPressure", "LabReports"],
    "date_from": "2026-01-01",
    "date_to": "2026-12-31"
  },
  "access_logs": [
    {
      "log_id": "log_001",
      "doctor_id": "dr_john@hospital.com",
      "patient_id": "patient@example.com",
      "action": "view_filtered_data",
      "data_accessed": "VitalSigns, BloodPressure",
      "timestamp": "2026-03-01T14:20:30Z",
      "status": "success",
      "duration_seconds": 2.5,
      "ip_address": "192.168.1.100",
      "reason": "Patient consultation"
    },
    {
      "log_id": "log_002",
      "doctor_id": "dr_john@hospital.com",
      "patient_id": "patient@example.com",
      "action": "view_filtered_data",
      "data_accessed": "VitalSigns, BloodPressure, LabReports",
      "timestamp": "2026-03-05T09:15:45Z",
      "status": "success",
      "duration_seconds": 3.1,
      "ip_address": "192.168.1.100",
      "reason": "Follow-up check"
    },
    {
      "log_id": "log_003",
      "doctor_id": "dr_john@hospital.com",
      "patient_id": "patient@example.com",
      "action": "view_filtered_data",
      "data_accessed": "LabReports",
      "timestamp": "2026-03-10T16:45:00Z",
      "status": "success",
      "duration_seconds": 1.8,
      "ip_address": "192.168.1.100",
      "reason": "Test results review"
    }
  ],
  "summary": {
    "consent_requested": true,
    "consent_approved": true,
    "consent_active": true,
    "consent_expired": false,
    "total_accesses": 3,
    "first_accessed": "2026-03-01T14:20:30Z",
    "last_accessed": "2026-03-10T16:45:00Z",
    "categories_accessed": ["VitalSigns", "BloodPressure", "LabReports"],
    "unique_access_dates": 3,
    "average_access_duration_seconds": 2.47,
    "compliance_verified": true,
    "compliance_notes": "All accesses within consent categories and date range"
  },
  "generated_at": "2026-03-11T16:45:30.123Z"
}
```

#### Response Codes
| Code | Meaning |
|------|---------|
| 200 | Consent audit trail retrieved successfully |
| 401 | Unauthorized (invalid/missing token) |
| 403 | Forbidden (cannot access other user's consent) |
| 404 | Consent not found |

---

## Database Schema

### AccessLog Collection (MongoDB)
```json
{
  "_id": "ObjectId",
  "log_id": "string (unique)",
  "doctor_id": "string",
  "patient_id": "string",
  "consent_id": "string",
  "action": "view_filtered_data|grant|revoke",
  "data_accessed": "string (comma-separated categories)",
  "timestamp": "ISO 8601 datetime",
  "ip_address": "string",
  "status": "success|failed|denied",
  "reason": "string (optional)",
  "error_message": "string (optional, if status=failed)",
  "duration_seconds": "float",
  "user_agent": "string (optional)"
}
```

**Indexes:**
```
db.access_logs.createIndex({ "doctor_id": 1, "timestamp": -1 })
db.access_logs.createIndex({ "patient_id": 1, "timestamp": -1 })
db.access_logs.createIndex({ "consent_id": 1, "timestamp": -1 })
db.access_logs.createIndex({ "timestamp": -1 })
```

---

## Error Responses

### 401 Unauthorized
```json
{
  "detail": "Not authenticated"
}
```
**Cause:** Missing or invalid JWT token
**Solution:** Login and get valid token

### 403 Forbidden
```json
{
  "detail": "Not enough permissions"
}
```
**Cause:** User role doesn't have access to endpoint
**Solution:** Use correct user role (doctor/patient)

### 404 Not Found
```json
{
  "detail": "Resource not found"
}
```
**Cause:** Invalid consent_id or no logs found
**Solution:** Verify consent_id exists

### 429 Too Many Requests
```json
{
  "detail": "Rate limit exceeded. Max 50 requests per minute."
}
```
**Cause:** Exceeded rate limit
**Solution:** Reduce request frequency

---

## Authentication Flow

1. **Login Endpoint**
   ```bash
   POST /auth/login
   {
     "email": "user@example.com",
     "password": "password123"
   }
   ```

2. **Receive Token**
   ```json
   {
     "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
     "token_type": "bearer",
     "expires_in": 86400
   }
   ```

3. **Use Token in Requests**
   ```bash
   curl -H "Authorization: Bearer <access_token>" \
     http://localhost:8000/admin/security-status
   ```

---

## Rate Limiting

| Endpoint | Limit | Window |
|----------|-------|--------|
| `/admin/health` | 100 | 1 minute |
| `/admin/security-status` | 10 | 1 minute |
| `/consent/audit-logs/my-accesses` | 50 | 1 minute |
| `/consent/audit-logs/patient-accesses` | 50 | 1 minute |
| `/consent/audit-logs/consent-audit/{id}` | 100 | 1 minute |

---

## Compliance & Security

### ABDM Compliance
All endpoints implement ABDM requirements:
- ✅ Consent-based access control
- ✅ Granular data access logging
- ✅ Patient transparency
- ✅ Doctor audit trail
- ✅ Data encryption in transit
- ✅ Secure authentication

### Security Headers
All responses include:
```
X-Content-Type-Options: nosniff
X-Frame-Options: DENY
X-XSS-Protection: 1; mode=block
Strict-Transport-Security: max-age=31536000; includeSubDomains
```

---

## Usage Examples

### Example 1: Patient Checking Who Accessed Their Data
```bash
# Step 1: Patient logs in
TOKEN=$(curl -s -X POST http://localhost:8000/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email": "patient@example.com", "password": "pass"}' \
  | jq -r '.access_token')

# Step 2: Patient checks access logs
curl -H "Authorization: Bearer $TOKEN" \
  "http://localhost:8000/consent/audit-logs/patient-accesses?days_back=30"
```

### Example 2: Doctor Reviewing Audit Trail for Specific Consent
```bash
# Step 1: Doctor gets token
TOKEN=$(curl -s -X POST http://localhost:8000/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email": "dr_john@hospital.com", "password": "pass"}' \
  | jq -r '.access_token')

# Step 2: Doctor views detailed consent audit
curl -H "Authorization: Bearer $TOKEN" \
  "http://localhost:8000/consent/audit-logs/consent-audit/phr_consent_abc123"
```

### Example 3: Regulator Generating Compliance Report
```bash
# Use doctor or admin token to generate security report
curl -H "Authorization: Bearer $TOKEN" \
  http://localhost:8000/admin/security-status | jq '.compliance'
```

---

## Changelog

**Version 1.0** (Released March 2026)
- ✅ Added `/admin/health` endpoint
- ✅ Added `/admin/security-status` endpoint
- ✅ Added `/consent/audit-logs/my-accesses` endpoint
- ✅ Added `/consent/audit-logs/patient-accesses` endpoint
- ✅ Added `/consent/audit-logs/consent-audit/{consent_id}` endpoint
- ✅ Implemented MongoDB audit log collection
- ✅ Added comprehensive audit logging on data access

---

## Support & Documentation

- **API Status:** http://localhost:8000/admin/health
- **Interactive Docs:** http://localhost:8000/docs
- **Security Report:** http://localhost:8000/admin/security-status
- **GitHub Issues:** [Report issues here]
- **Email Support:** support@phr-system.com
