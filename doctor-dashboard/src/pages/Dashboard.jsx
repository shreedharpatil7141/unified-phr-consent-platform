import { useEffect, useMemo, useState } from "react";
import { useNavigate } from "react-router-dom";
import { Activity, Database, HeartPulse, AlertTriangle } from "lucide-react";

import "../styles/dashboard.css";
import API from "../services/api";
import ConsentTimer from "../components/ConsentTimer";

const StatCard = ({ title, value, icon }) => (
  <div className="card stat-card">
    <div>
      <p className="stat-title">{title}</p>
      <h2 className="stat-value">{value}</h2>
    </div>
    <div className="icon-box">{icon}</div>
  </div>
);

const formatDateTime = (value) =>
  value
    ? new Date(value).toLocaleString([], {
        day: "numeric",
        month: "short",
        hour: "numeric",
        minute: "2-digit",
      })
    : "Unknown";

const Dashboard = () => {
  const [consents, setConsents] = useState([]);
  const [notifications, setNotifications] = useState([]);
  const navigate = useNavigate();

  useEffect(() => {
    API.get("/consent/sent")
      .then((res) => setConsents(res.data || []))
      .catch((err) => console.error("Consent load error:", err));

    API.get("/notifications/my")
      .then((res) => setNotifications(res.data || []))
      .catch((err) => console.error("Notification load error:", err));
  }, []);

  const activeConsents = useMemo(
    () =>
      consents
        .filter((consent) => consent.status === "approved" && consent.expires_at)
        .sort(
          (a, b) =>
            new Date(a.expires_at || 0) -
            new Date(b.expires_at || 0)
        ),
    [consents]
  );
  const connectedPatients = useMemo(
    () => new Set(activeConsents.map((consent) => consent.patient_id)).size,
    [activeConsents]
  );

  const pendingConsents = consents.filter((consent) => consent.status === "pending");
  const unreadNotifications = notifications.filter((notification) => !notification.read);

  return (
    <div className="dashboard-container">
      <h1 className="dashboard-title">Doctor Dashboard</h1>

      <div className="grid grid-4">
        <StatCard title="Patients Connected" value={connectedPatients} icon={<Activity size={20} />} />
        <StatCard title="Active Consents" value={activeConsents.length} icon={<Database size={20} />} />
        <StatCard title="Pending Requests" value={pendingConsents.length} icon={<HeartPulse size={20} />} />
        <StatCard title="Unread Alerts" value={unreadNotifications.length} icon={<AlertTriangle size={20} />} />
      </div>

      <div className="grid grid-2" style={{ marginTop: "30px" }}>
        <div className="card section-card">
          <div className="section-eyebrow">Access Queue</div>
          <h3 className="section-title">Active patient access</h3>

          {!activeConsents.length && (
            <p className="section-copy">No active consents yet.</p>
          )}

          <div className="insight-list">
            {activeConsents.slice(0, 4).map((consent) => (
              <div key={consent.consent_id} className="insight-list-item">
                <div className="timeline-row">
                  <div>
                    <div className="document-title">{consent.patient_id}</div>
                    <div className="document-meta">
                      {consent.categories?.join(", ") || "No categories"}
                    </div>
                    <div style={{ marginTop: "10px" }}>
                      <ConsentTimer expiresAt={consent.expires_at} />
                    </div>
                  </div>
                  <div className="timeline-time">
                    Approved {formatDateTime(consent.approved_at || consent.requested_at)}
                  </div>
                </div>
                <div className="document-link-wrap">
                  <button
                    className="primary-button"
                    onClick={() => navigate(`/patient/${consent.consent_id}`)}
                  >
                    Open Dashboard
                  </button>
                </div>
              </div>
            ))}
          </div>
        </div>

        <div className="card section-card">
          <div className="section-eyebrow">Operational Feed</div>
          <h3 className="section-title">Latest Notifications</h3>

          {!notifications.length && (
            <p className="section-copy">No notifications available.</p>
          )}

          <div className="insight-list">
            {notifications.slice(0, 4).map((notification) => (
              <div key={notification.notification_id} className="insight-list-item">
                <div>{notification.message}</div>
                <div className="timeline-time" style={{ marginTop: "8px" }}>
                  {formatDateTime(notification.created_at)}
                </div>
              </div>
            ))}
          </div>
        </div>
      </div>
    </div>
  );
};

export default Dashboard;
