import React, { useEffect, useMemo, useState } from "react";
import { useParams } from "react-router-dom";
import { Activity, HeartPulse, Database, AlertTriangle } from "lucide-react";

import { getDashboardData } from "../services/api";
import { API_BASE_URL } from "../services/config";
import PatientCard from "../components/PatientCard";
import HealthTimeline from "../components/HealthTimeline";
import VitalsChart from "../components/VitalsChart.jsx";
import AlertsPanel from "../components/AlertsPanel";
import RiskScore from "../components/RiskScore";
import ConsentTimer from "../components/ConsentTimer";
import "../styles/dashboard.css";

const StatCard = ({ title, value, icon }) => (
  <div className="card stat-card">
    <div>
      <p className="stat-title">{title}</p>
      <h2 className="stat-value">{value}</h2>
    </div>
    <div className="icon-box">{icon}</div>
  </div>
);

const PatientDashboard = () => {
  const [data, setData] = useState(null);
  const { consentId } = useParams();

  useEffect(() => {
    if (!consentId) return;

    const token = localStorage.getItem("token");
    if (!token) {
      alert("No token found. Please login again.");
      return;
    }

    getDashboardData(consentId)
      .then((res) => {
        setData(res?.data || { records: [], message: "No data available" });
      })
      .catch((err) => {
        console.error("Dashboard load error:", err);
        setData({ records: [], message: "Failed to load patient data" });
      });
  }, [consentId]);

  const dashboardData = data || { records: [] };
  const records = dashboardData.records || [];
  const patientEmail = dashboardData.patient_id;
  const patientProfile = dashboardData.patient_profile || {};
  const allowedCategories = dashboardData.allowed_categories || [];
  const documents = records.filter((record) => !!(record.file_url || record.file_name));
  const vitals = records.filter((record) => !(record.file_url || record.file_name));

  const groupedRecordCount = useMemo(() => {
    let count = 0;
    if (vitals.length) count += 1;
    if (documents.length) count += 1;
    return count;
  }, [vitals.length, documents.length]);

  const consentScope = allowedCategories.join(", ") || "documents";
  const consentApprovedAt = dashboardData.consent_approved_at
    ? new Date(dashboardData.consent_approved_at).toLocaleString()
    : "Pending approval timestamp";
  const consentExpiresAt = dashboardData.consent_expires_at
    ? new Date(dashboardData.consent_expires_at).toLocaleString()
    : "Not available";

  const vitalsEmptyMessage = allowedCategories.some((category) =>
    ["vitals", "cardiology", "cardiac"].includes((category || "").toLowerCase())
  )
    ? "No synced vital readings are available in the currently shared consent window."
    : `This consent is scoped to ${consentScope} and does not include vitals.`;

  const resolveFileUrl = (fileUrl) => {
    if (!fileUrl) return "";
    if (fileUrl.startsWith("http://") || fileUrl.startsWith("https://")) return fileUrl;
    return `${API_BASE_URL}${fileUrl}`;
  };

  const getDocumentUrl = (record) => {
    if (record.file_url) return resolveFileUrl(record.file_url);
    if (record.file_name) return `${API_BASE_URL}/uploads/${record.file_name}`;
    return "#";
  };

  if (!consentId) {
    return <div className="dashboard-container">No consent selected.</div>;
  }

  if (!data) {
    return <div className="dashboard-container">Loading Patient Data...</div>;
  }

  return (
    <div className="dashboard-container">
      <h1 className="dashboard-title">Patient Health Dashboard</h1>

      <div className="grid grid-4">
        <StatCard title="Patient" value={patientEmail} icon={<Activity size={20} />} />
        <StatCard title="Records" value={groupedRecordCount} icon={<Database size={20} />} />
        <StatCard title="Vitals" value={vitals.length ? "Shared" : "Not Shared"} icon={<HeartPulse size={20} />} />
        <StatCard title="Alerts" value="AI Monitoring" icon={<AlertTriangle size={20} />} />
      </div>

      <div className="grid grid-2" style={{ marginTop: "30px" }}>
        <div className="card section-card">
          <div className="section-eyebrow">Consent State</div>
          <h3 className="section-title">Access Overview</h3>
          <span className="status-success">
            {dashboardData.message || "Consent-approved patient data loaded"}
          </span>
          <div style={{ marginTop: "14px" }}>
            <ConsentTimer expiresAt={dashboardData.consent_expires_at} />
          </div>
          <div className="debug-grid" style={{ marginTop: "16px" }}>
            <div className="debug-pill">
              <span className="debug-label">Shared scope</span>
              <span className="debug-value">{consentScope}</span>
            </div>
            <div className="debug-pill">
              <span className="debug-label">Approved at</span>
              <span className="debug-value">{consentApprovedAt}</span>
            </div>
            <div className="debug-pill">
              <span className="debug-label">Consent expires</span>
              <span className="debug-value">{consentExpiresAt}</span>
            </div>
          </div>
        </div>

        <PatientCard patientEmail={patientEmail} profile={patientProfile} />
      </div>

      <div className="card section-card" style={{ marginTop: "20px" }}>
        <div className="section-eyebrow">Clinical Snapshot</div>
        <h3 className="section-title">Clinical Summary</h3>
        <p className="section-copy">
          {dashboardData.insight_summary || "No shared summary available for this consent."}
        </p>
      </div>

      <div className="grid grid-chart" style={{ marginTop: "30px" }}>
        <div className="card section-card">
          <div className="section-eyebrow">Continuous Monitoring</div>
          <h3 className="section-title">Vitals Trend</h3>
          <VitalsChart records={records} emptyMessage={vitalsEmptyMessage} />
        </div>

        <div style={{ display: "flex", flexDirection: "column", gap: "20px" }}>
          <AlertsPanel records={records} />
          <RiskScore records={records} />
        </div>
      </div>

      <div className="card section-card" style={{ marginTop: "30px" }}>
        <div className="section-eyebrow">Shared Files</div>
        <h3 className="section-title">Medical Documents</h3>

        {!documents.length && <p className="section-copy">No uploaded documents</p>}

        {documents.map((record, index) => (
          <div key={`${record.file_name || record.record_name || index}`} className="document-item">
            <div className="document-title">
              {record.record_name || record.recordName || record.file_name || "Medical File"}
            </div>
            <div className="document-meta">
              {record.category || "document"}
              {record.domain ? ` - ${record.domain}` : ""}
            </div>
            <div className="document-link-wrap">
              <a
                href={getDocumentUrl(record)}
                target="_blank"
                rel="noreferrer"
                className="document-link"
              >
                View PDF
              </a>
            </div>
          </div>
        ))}
      </div>

      <div className="card section-card" style={{ marginTop: "30px" }}>
        <div className="section-eyebrow">Chronology</div>
        <h3 className="section-title">Unified Health Timeline</h3>
        <HealthTimeline records={records} />
      </div>
    </div>
  );
};

export default PatientDashboard;
