import { useEffect, useState } from "react";
import { useNavigate } from "react-router-dom";

import API from "../services/api";
import ConsentTimer from "../components/ConsentTimer";
import "../styles/dashboard.css";

const formatDateTime = (value) =>
  value
    ? new Date(value).toLocaleString([], {
        day: "numeric",
        month: "short",
        hour: "numeric",
        minute: "2-digit",
      })
    : "Unknown";

const Patients = () => {
  const [consents, setConsents] = useState([]);
  const navigate = useNavigate();

  useEffect(() => {
    API.get("/consent/sent")
      .then((res) => {
        const approved = (res.data || [])
          .filter((consent) => consent.status === "approved")
          .sort(
            (a, b) =>
              new Date(b.approved_at || b.requested_at || 0) -
              new Date(a.approved_at || a.requested_at || 0)
          );
        setConsents(approved);
      })
      .catch((err) => console.error(err));
  }, []);

  return (
    <div>
      <h1 className="dashboard-title" style={{ marginBottom: "20px" }}>Patients</h1>

      {consents.length === 0 && (
        <p className="section-copy">No approved patient consents yet</p>
      )}

      <div className="insight-list">
        {consents.map((consent) => (
          <div key={consent.consent_id} className="card patient-list-card">
            <div className="timeline-row">
              <div>
                <div className="section-eyebrow">Approved Patient</div>
                <div className="document-title">{consent.patient_id}</div>
              </div>
              <div className="timeline-time">
                {formatDateTime(consent.approved_at || consent.requested_at)}
              </div>
            </div>

            <div className="document-meta" style={{ marginTop: "10px" }}>
              {consent.categories?.join(", ") || "No categories"} - {consent.status}
            </div>
            <div style={{ marginTop: "10px" }}>
              <ConsentTimer expiresAt={consent.expires_at} />
            </div>

            <div className="document-link-wrap">
              <button
                onClick={() => navigate(`/patient/${consent.consent_id}`)}
                className="primary-button"
              >
                Open Dashboard
              </button>
            </div>
          </div>
        ))}
      </div>
    </div>
  );
};

export default Patients;
