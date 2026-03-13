import { useEffect, useMemo, useState } from "react";
import { CalendarClock, Clock3, FileCheck2, Trash2 } from "lucide-react";

import ConsentTimer from "../components/ConsentTimer";
import {
  deleteConsent,
  deleteExpiredConsents,
  getSentRequests,
  requestConsent,
} from "../services/doctorService";
import "../styles/dashboard.css";
import { formatServerDate, formatServerDateTime, toTimestamp } from "../utils/dateTime";

const CATEGORY_OPTIONS = [
  { label: "Cardiac", value: "cardiac" },
  { label: "Metabolic", value: "metabolic" },
  { label: "Renal", value: "renal" },
  { label: "Hepatic", value: "hepatic" },
  { label: "Hematology", value: "hematology" },
  { label: "Respiratory", value: "respiratory" },
  { label: "General Wellness", value: "wellness" },
  { label: "Radiology", value: "radiology" },
  { label: "Lab Reports", value: "lab_report" },
  { label: "Prescriptions", value: "prescription" },
  { label: "Vaccines", value: "vaccination" },
  { label: "Vitals", value: "vitals" },
];

const EMPTY_COUNTS = { pending: 0, active: 0, expired: 0 };
const CURRENT_YEAR = new Date().getFullYear();
const YEAR_OPTIONS = Array.from({ length: 10 }, (_, index) => CURRENT_YEAR - index);
const toDateTimeLocalValue = (date) => {
  const pad = (n) => n.toString().padStart(2, "0");
  return `${date.getFullYear()}-${pad(date.getMonth() + 1)}-${pad(date.getDate())}T${pad(date.getHours())}:${pad(date.getMinutes())}`;
};

const normalizeStatus = (request) => {
  if (request.status === "approved" && request.expires_at) {
    if (toTimestamp(request.expires_at) <= Date.now()) {
      return "expired";
    }
    return "active";
  }
  if (request.status === "expired") return "expired";
  return request.status;
};

const ConsentRequests = () => {
  const [patientEmail, setPatientEmail] = useState("");
  const [categories, setCategories] = useState([]);
  const [selectedYear, setSelectedYear] = useState("");
  const [dateFrom, setDateFrom] = useState("");
  const [dateTo, setDateTo] = useState("");
  const [accessFrom, setAccessFrom] = useState("");
  const [accessTo, setAccessTo] = useState("");
  const [accessDuration, setAccessDuration] = useState(60);
  const [requests, setRequests] = useState([]);
  const [activeTab, setActiveTab] = useState("pending");
  const [loading, setLoading] = useState(true);
  const [submitting, setSubmitting] = useState(false);
  const [cleaningExpired, setCleaningExpired] = useState(false);

  const loadRequests = async () => {
    setLoading(true);
    try {
      const token = localStorage.getItem("token");
      const data = await getSentRequests(token);
      setRequests(data || []);
    } catch (error) {
      console.error("Error loading consents:", error);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    loadRequests();
  }, []);

  useEffect(() => {
    if (accessFrom && accessTo) return;
    const now = new Date();
    const plusOneHour = new Date(now.getTime() + 60 * 60 * 1000);
    setAccessFrom(toDateTimeLocalValue(now));
    setAccessTo(toDateTimeLocalValue(plusOneHour));
  }, [accessFrom, accessTo]);

  useEffect(() => {
    if (!accessFrom || !accessTo) return;

    const diffMinutes = Math.floor(
      (new Date(accessTo).getTime() - new Date(accessFrom).getTime()) / 60000
    );

    setAccessDuration(diffMinutes > 0 ? diffMinutes : 0);
  }, [accessFrom, accessTo]);

  const requestsByStatus = useMemo(() => {
    return requests.reduce((acc, request) => {
      const status = normalizeStatus(request);
      if (!acc[status]) {
        acc[status] = [];
      }
      acc[status].push(request);
      return acc;
    }, { pending: [], active: [], expired: [], rejected: [], revoked: [] });
  }, [requests]);

  const counts = useMemo(() => ({
    pending: requestsByStatus.pending?.length || 0,
    active: requestsByStatus.active?.length || 0,
    expired: requestsByStatus.expired?.length || 0,
  }), [requestsByStatus]);

  const visibleRequests = useMemo(() => {
    const current = [...(requestsByStatus[activeTab] || [])];

    if (activeTab === "active") {
      return current.sort((left, right) => {
        const leftExpiry = toTimestamp(left.expires_at || 0);
        const rightExpiry = toTimestamp(right.expires_at || 0);
        return leftExpiry - rightExpiry;
      });
    }

    return current.sort((left, right) => {
      const leftTime = toTimestamp(left.requested_at || 0);
      const rightTime = toTimestamp(right.requested_at || 0);
      return rightTime - leftTime;
    });
  }, [activeTab, requestsByStatus]);

  const toggleCategory = (category) => {
    setCategories((current) =>
      current.includes(category)
        ? current.filter((item) => item !== category)
        : [...current, category]
    );
  };

  const sendRequest = async () => {
    const requestDateFrom = selectedYear
      ? `${selectedYear}-01-01T00:00`
      : dateFrom;
    const requestDateTo = selectedYear
      ? `${selectedYear}-12-31T23:59`
      : dateTo;

    if (!patientEmail || categories.length === 0 || !requestDateFrom || !requestDateTo || !accessFrom || !accessTo) {
      alert("Please complete patient, scope, data range, and consent access window.");
      return;
    }

    if (new Date(requestDateTo) <= new Date(requestDateFrom)) {
      alert("Data range end must be after data range start.");
      return;
    }

    if (new Date(accessTo) <= new Date(accessFrom)) {
      alert("Access end time must be after access start time.");
      return;
    }

    if (accessDuration <= 0) {
      alert("Access duration must be greater than zero.");
      return;
    }

    setSubmitting(true);
    try {
      const token = localStorage.getItem("token");
      await requestConsent(
        patientEmail,
        categories,
        requestDateFrom,
        requestDateTo,
        accessDuration,
        accessFrom,
        accessTo,
        token
      );

      setPatientEmail("");
      setCategories([]);
      setSelectedYear("");
      setDateFrom("");
      setDateTo("");
      setAccessFrom("");
      setAccessTo("");
      setAccessDuration(60);
      setActiveTab("pending");
      await loadRequests();
    } catch (error) {
      console.error(error);
      alert("Failed to send request");
    } finally {
      setSubmitting(false);
    }
  };

  const handleDeleteConsent = async (consentId) => {
    try {
      const token = localStorage.getItem("token");
      await deleteConsent(consentId, token);
      setRequests((current) =>
        current.filter((request) => request.consent_id !== consentId)
      );
    } catch (error) {
      console.error("Failed to delete consent", error);
      alert(error?.response?.data?.detail || "Failed to delete consent");
    }
  };

  const handleDeleteExpired = async () => {
    setCleaningExpired(true);
    try {
      const token = localStorage.getItem("token");
      await deleteExpiredConsents(token);
      await loadRequests();
      setActiveTab("active");
    } catch (error) {
      console.error("Failed to delete expired consents", error);
      alert("Failed to delete expired consents");
    } finally {
      setCleaningExpired(false);
    }
  };

  return (
    <div className="dashboard-container">
      <div className="page-header-row">
        <div>
          <div className="section-eyebrow">Consent Orchestration</div>
          <h1 className="dashboard-title">Consent Access Control</h1>
          <p className="section-copy">
            Separate the requested clinical date window from the doctor access window,
            then track approval time with a live reverse countdown.
          </p>
        </div>
        <div className="dashboard-chip-row">
          <span className="debug-pill">
            <span className="debug-label">Pending</span>
            <span className="debug-value">{counts.pending}</span>
          </span>
          <span className="debug-pill">
            <span className="debug-label">Active</span>
            <span className="debug-value">{counts.active}</span>
          </span>
          <span className="debug-pill">
            <span className="debug-label">Expired</span>
            <span className="debug-value">{counts.expired}</span>
          </span>
        </div>
      </div>

      <div className="card section-card">
        <div className="section-eyebrow">New Request</div>
        <h3 className="section-title">Request patient data access</h3>

        <div className="consent-form-grid">
          <label className="field-group field-span-2">
            <span className="field-label">Patient email</span>
            <input
              className="field-input"
              placeholder="patient@email.com"
              value={patientEmail}
              onChange={(event) => setPatientEmail(event.target.value)}
            />
          </label>

          <label className="field-group">
            <span className="field-label">Year (optional)</span>
            <select
              className="field-input"
              value={selectedYear}
              onChange={(event) => setSelectedYear(event.target.value)}
            >
              <option value="">Custom range</option>
              {YEAR_OPTIONS.map((year) => (
                <option key={year} value={year}>
                  {year}
                </option>
              ))}
            </select>
          </label>

          <label className="field-group">
            <span className="field-label">Data range from</span>
            <input
              className="field-input"
              type="datetime-local"
              value={dateFrom}
              disabled={Boolean(selectedYear)}
              onChange={(event) => setDateFrom(event.target.value)}
            />
          </label>

          <label className="field-group">
            <span className="field-label">Data range until</span>
            <input
              className="field-input"
              type="datetime-local"
              value={dateTo}
              disabled={Boolean(selectedYear)}
              onChange={(event) => setDateTo(event.target.value)}
            />
          </label>

          <label className="field-group">
            <span className="field-label">Access from</span>
            <input
              className="field-input"
              type="datetime-local"
              value={accessFrom}
              onChange={(event) => setAccessFrom(event.target.value)}
            />
          </label>

          <label className="field-group">
            <span className="field-label">Access until</span>
            <input
              className="field-input"
              type="datetime-local"
              value={accessTo}
              onChange={(event) => setAccessTo(event.target.value)}
            />
          </label>
        </div>

        <div className="section-eyebrow" style={{ marginTop: "18px" }}>Requested scope</div>
        <div className="consent-chip-grid">
          {CATEGORY_OPTIONS.map((option) => {
            const checked = categories.includes(option.value);
            return (
              <button
                key={option.value}
                type="button"
                className={`consent-scope-chip ${checked ? "consent-scope-chip-active" : ""}`}
                onClick={() => toggleCategory(option.value)}
              >
                {option.label}
              </button>
            );
          })}
        </div>

        <div className="consent-preview-row">
          <div className="debug-pill">
            <span className="debug-label">Records requested</span>
            <span className="debug-value">{categories.join(", ") || "None"}</span>
          </div>
          <div className="debug-pill">
            <span className="debug-label">Access duration</span>
            <span className="debug-value">{accessDuration} minutes</span>
          </div>
          <div className="debug-pill">
            <span className="debug-label">Data range</span>
            <span className="debug-value">
              {selectedYear
                ? `Jan 1, ${selectedYear} - Dec 31, ${selectedYear}`
                : `${dateFrom ? new Date(dateFrom).toLocaleString() : "N/A"} - ${
                    dateTo ? new Date(dateTo).toLocaleString() : "N/A"
                  }`}
            </span>
          </div>
          <div className="debug-pill">
            <span className="debug-label">Access window</span>
            <span className="debug-value">
              {accessFrom ? new Date(accessFrom).toLocaleString() : "N/A"} -{" "}
              {accessTo ? new Date(accessTo).toLocaleString() : "N/A"}
            </span>
          </div>
        </div>

        <button className="primary-button" onClick={sendRequest} disabled={submitting}>
          <FileCheck2 size={16} /> {submitting ? "Sending..." : "Send consent request"}
        </button>
      </div>

      <div className="card section-card" style={{ marginTop: "24px" }}>
        <div className="page-header-row">
          <div>
            <div className="section-eyebrow">Request History</div>
            <h3 className="section-title">Consent lifecycle</h3>
          </div>
          {activeTab === "expired" && counts.expired > 0 && (
            <button
              className="ghost-danger-button"
              onClick={handleDeleteExpired}
              disabled={cleaningExpired}
            >
              <Trash2 size={14} /> {cleaningExpired ? "Deleting..." : "Delete expired"}
            </button>
          )}
        </div>

        <div className="consent-tabs">
          {[
            { id: "pending", label: "Pending", count: counts.pending || EMPTY_COUNTS.pending },
            { id: "active", label: "Active", count: counts.active || EMPTY_COUNTS.active },
            { id: "expired", label: "Expired", count: counts.expired || EMPTY_COUNTS.expired },
          ].map((tab) => (
            <button
              key={tab.id}
              className={`consent-tab ${activeTab === tab.id ? "consent-tab-active" : ""}`}
              onClick={() => setActiveTab(tab.id)}
            >
              {tab.label} <span>{tab.count}</span>
            </button>
          ))}
        </div>

        {loading && <p className="section-copy">Loading consent requests...</p>}
        {!loading && visibleRequests.length === 0 && (
          <p className="section-copy">No {activeTab} requests found.</p>
        )}

        <div className="consent-list">
          {visibleRequests.map((request) => {
            const effectiveStatus = normalizeStatus(request);
            const canDelete = ["expired", "rejected", "revoked"].includes(effectiveStatus);

            return (
              <div key={request.consent_id} className="consent-card">
                <div className="consent-card-header">
                  <div>
                    <div className="consent-card-title">{request.patient_id}</div>
                    <div className="consent-card-subtitle">
                      {request.categories?.join(", ") || "No categories"}
                    </div>
                  </div>
                  <span className={`consent-status consent-status-${effectiveStatus}`}>
                    {effectiveStatus}
                  </span>
                </div>

                <div className="consent-card-grid">
                  <div className="consent-metadata">
                    <CalendarClock size={14} />
                    Requested: {request.requested_at ? formatServerDateTime(request.requested_at) : "N/A"}
                  </div>
                  <div className="consent-metadata">
                    <Clock3 size={14} />
                    Access: {request.access_duration_minutes || 0} minutes
                  </div>
                  <div className="consent-metadata">
                    Range: {request.date_from ? formatServerDate(request.date_from) : "N/A"} -{" "}
                    {request.date_to ? formatServerDate(request.date_to) : "N/A"}
                  </div>
                  <div className="consent-metadata">
                    Access window: {request.access_from ? formatServerDateTime(request.access_from) : "Starts on approval"} -{" "}
                    {request.access_to ? formatServerDateTime(request.access_to) : "Until duration ends"}
                  </div>
                  {request.approved_at && (
                    <div className="consent-metadata">
                      Approved: {formatServerDateTime(request.approved_at)}
                    </div>
                  )}
                </div>

                {effectiveStatus === "active" && (
                  <div style={{ marginTop: "14px" }}>
                    <ConsentTimer expiresAt={request.expires_at} />
                  </div>
                )}

                {canDelete && (
                  <div className="consent-card-actions">
                    <button
                      className="ghost-danger-button"
                      onClick={() => handleDeleteConsent(request.consent_id)}
                    >
                      <Trash2 size={14} /> Delete from history
                    </button>
                  </div>
                )}
              </div>
            );
          })}
        </div>
      </div>
    </div>
  );
};

export default ConsentRequests;
