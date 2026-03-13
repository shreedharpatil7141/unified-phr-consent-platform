import { useEffect, useMemo, useState } from "react";
import { ShieldCheck, Users, CircleCheck, CircleOff, CalendarClock } from "lucide-react";

import { getDoctorAppointments, getMyAccessAudit } from "../services/doctorService";

const AuditLogs = () => {
  const [daysBack, setDaysBack] = useState(30);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState("");
  const [summary, setSummary] = useState({});
  const [appointmentSummary, setAppointmentSummary] = useState({
    total: 0,
    requested: 0,
    confirmed: 0,
    completed: 0,
    cancelled: 0,
  });

  const loadAudit = async () => {
    setLoading(true);
    setError("");
    try {
      const [data, appointments] = await Promise.all([
        getMyAccessAudit(daysBack),
        getDoctorAppointments(),
      ]);
      setSummary(data?.audit_summary || {});
      const cutoff = Date.now() - daysBack * 24 * 60 * 60 * 1000;
      const filtered = (appointments || []).filter((item) => {
        const at = new Date(item.requested_at || item.scheduled_for || 0).getTime();
        return at >= cutoff;
      });
      const next = {
        total: filtered.length,
        requested: 0,
        confirmed: 0,
        completed: 0,
        cancelled: 0,
      };
      filtered.forEach((item) => {
        const key = item?.status || "requested";
        if (Object.prototype.hasOwnProperty.call(next, key)) {
          next[key] += 1;
        }
      });
      setAppointmentSummary(next);
    } catch (err) {
      setError(err?.response?.data?.detail || "Failed to load audit logs");
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    loadAudit();
  }, [daysBack]);

  const byPatient = useMemo(() => {
    const entries = Object.entries(summary?.by_patient || {});
    entries.sort((a, b) => (b[1] || 0) - (a[1] || 0));
    return entries;
  }, [summary]);

  return (
    <div className="dashboard-container">
      <div className="page-header-row">
        <div>
          <div className="section-eyebrow">Compliance</div>
          <h1 className="dashboard-title">Doctor Audit Logs</h1>
          <p className="section-copy">
            Review your consented data access activity for ABDM-aligned audit visibility.
          </p>
        </div>
        <div>
          <select
            className="field-input"
            value={daysBack}
            onChange={(event) => setDaysBack(Number(event.target.value))}
          >
            <option value={7}>Last 7 days</option>
            <option value={30}>Last 30 days</option>
            <option value={90}>Last 90 days</option>
          </select>
        </div>
      </div>

      {loading && <p className="section-copy">Loading audit logs...</p>}
      {!loading && error && <p className="section-copy">{error}</p>}

      {!loading && !error && (
        <>
          <div className="grid grid-4">
            <div className="card stat-card">
              <div>
                <div className="stat-title">Total Accesses</div>
                <div className="stat-value">{summary?.total_accesses || 0}</div>
              </div>
              <div className="icon-box">
                <ShieldCheck size={20} />
              </div>
            </div>
            <div className="card stat-card">
              <div>
                <div className="stat-title">Successful</div>
                <div className="stat-value">{summary?.successful_accesses || 0}</div>
              </div>
              <div className="icon-box">
                <CircleCheck size={20} />
              </div>
            </div>
            <div className="card stat-card">
              <div>
                <div className="stat-title">Denied</div>
                <div className="stat-value">{summary?.denied_accesses || 0}</div>
              </div>
              <div className="icon-box">
                <CircleOff size={20} />
              </div>
            </div>
            <div className="card stat-card">
              <div>
                <div className="stat-title">Patients Accessed</div>
                <div className="stat-value">{byPatient.length}</div>
              </div>
              <div className="icon-box">
                <Users size={20} />
              </div>
            </div>
            <div className="card stat-card">
              <div>
                <div className="stat-title">Appointments ({daysBack}d)</div>
                <div className="stat-value">{appointmentSummary.total}</div>
              </div>
              <div className="icon-box">
                <CalendarClock size={20} />
              </div>
            </div>
          </div>

          <div className="card section-card" style={{ marginTop: "20px" }}>
            <div className="section-eyebrow">Breakdown</div>
            <h3 className="section-title">Accesses by Patient</h3>
            {!byPatient.length && (
              <p className="section-copy">No patient access logs found for this period.</p>
            )}
            {!!byPatient.length && (
              <div className="insight-list">
                {byPatient.map(([patientId, count]) => (
                  <div key={patientId} className="insight-list-item">
                    <div className="page-header-row">
                      <div className="document-title" style={{ fontSize: "16px" }}>{patientId}</div>
                      <div className="debug-value" style={{ fontSize: "16px" }}>{count} accesses</div>
                    </div>
                  </div>
                ))}
              </div>
            )}
          </div>

          <div className="card section-card" style={{ marginTop: "20px" }}>
            <div className="section-eyebrow">Appointments</div>
            <h3 className="section-title">Appointment Activity ({daysBack} days)</h3>
            <div className="insight-list">
              <div className="insight-list-item">Requested: {appointmentSummary.requested}</div>
              <div className="insight-list-item">Confirmed: {appointmentSummary.confirmed}</div>
              <div className="insight-list-item">Completed: {appointmentSummary.completed}</div>
              <div className="insight-list-item">Cancelled: {appointmentSummary.cancelled}</div>
            </div>
          </div>
        </>
      )}
    </div>
  );
};

export default AuditLogs;
