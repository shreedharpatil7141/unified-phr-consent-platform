import { useEffect, useMemo, useState } from "react";
import { CalendarClock, CheckCircle2, XCircle } from "lucide-react";

import {
  cancelAppointment,
  deleteAppointment,
  completeAppointment,
  confirmAppointment,
  getDoctorAppointments,
} from "../services/doctorService";
import { formatServerDateTime } from "../utils/dateTime";

const toDateTimeLocal = (value) => {
  if (!value) return "";
  const d = new Date(value);
  const pad = (n) => `${n}`.padStart(2, "0");
  return `${d.getFullYear()}-${pad(d.getMonth() + 1)}-${pad(d.getDate())}T${pad(d.getHours())}:${pad(d.getMinutes())}`;
};

const toIso = (localValue) => (localValue ? new Date(localValue).toISOString() : null);
const isExpiredConfirmed = (item) =>
  item?.status === "confirmed" && item?.ends_at && new Date(item.ends_at).getTime() < Date.now();

const Appointments = () => {
  const [appointments, setAppointments] = useState([]);
  const [loading, setLoading] = useState(true);
  const [selected, setSelected] = useState(null);
  const [startAt, setStartAt] = useState("");
  const [endAt, setEndAt] = useState("");
  const [note, setNote] = useState("");

  const loadAppointments = async () => {
    setLoading(true);
    try {
      const data = await getDoctorAppointments();
      setAppointments(data || []);
    } catch (error) {
      console.error("Failed to load appointments", error);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    loadAppointments();
  }, []);

  const byStatus = useMemo(() => {
    return appointments.reduce(
      (acc, row) => {
        const key = row.status || "requested";
        if (!acc[key]) acc[key] = [];
        acc[key].push(row);
        return acc;
      },
      { requested: [], confirmed: [], completed: [], cancelled: [] }
    );
  }, [appointments]);

  const openConfirm = (appointment) => {
    setSelected(appointment);
    setStartAt(toDateTimeLocal(appointment.scheduled_for));
    const defaultEnd = appointment.ends_at
      ? toDateTimeLocal(appointment.ends_at)
      : toDateTimeLocal(new Date(new Date(appointment.scheduled_for).getTime() + 30 * 60000).toISOString());
    setEndAt(defaultEnd);
    setNote(appointment.confirmation_note || "");
  };

  const submitConfirm = async () => {
    if (!selected) return;
    try {
      await confirmAppointment(
        selected.appointment_id,
        toIso(startAt),
        toIso(endAt),
        note
      );
      setSelected(null);
      await loadAppointments();
    } catch (error) {
      alert(error?.response?.data?.detail || "Failed to confirm appointment");
    }
  };

  const markComplete = async (appointmentId) => {
    try {
      await completeAppointment(appointmentId);
      await loadAppointments();
    } catch (error) {
      alert(error?.response?.data?.detail || "Failed to complete appointment");
    }
  };

  const markCancel = async (appointmentId) => {
    try {
      await cancelAppointment(appointmentId, "Cancelled by doctor");
      await loadAppointments();
    } catch (error) {
      alert(error?.response?.data?.detail || "Failed to cancel appointment");
    }
  };

  const removeAppointment = async (appointmentId) => {
    try {
      await deleteAppointment(appointmentId);
      if (selected?.appointment_id === appointmentId) {
        setSelected(null);
      }
      await loadAppointments();
    } catch (error) {
      alert(error?.response?.data?.detail || "Failed to delete appointment");
    }
  };

  const renderList = (items, emptyText) => {
    if (!items.length) return <p className="section-copy">{emptyText}</p>;
    return (
      <div className="consent-list">
        {items.map((item) => (
          <div key={item.appointment_id} className="consent-card">
            <div className="consent-card-header">
              <div>
                <div className="consent-card-title">{item.patient_email}</div>
                <div className="consent-card-subtitle">{item.reason || "General consultation"}</div>
              </div>
              <span className={`consent-status consent-status-${item.status || "pending"}`}>
                {item.status}
              </span>
            </div>

            <div className="consent-card-grid">
              <div className="consent-metadata">
                <CalendarClock size={14} />
                Requested: {formatServerDateTime(item.requested_at)}
              </div>
              <div className="consent-metadata">
                Scheduled: {formatServerDateTime(item.scheduled_for)}
              </div>
              <div className="consent-metadata">
                Ends: {item.ends_at ? formatServerDateTime(item.ends_at) : "Not assigned"}
              </div>
              <div className="consent-metadata">
                Note: {item.confirmation_note || "No note"}
              </div>
            </div>

            <div style={{ marginTop: "14px", display: "flex", gap: "10px", flexWrap: "wrap" }}>
              {item.status === "requested" && (
                <button className="primary-button" onClick={() => openConfirm(item)}>
                  <CheckCircle2 size={14} /> Confirm & allocate slot
                </button>
              )}
              {item.status === "confirmed" && (
                <button className="secondary-button" onClick={() => markComplete(item.appointment_id)}>
                  Mark completed
                </button>
              )}
              {item.status !== "completed" && item.status !== "cancelled" && !isExpiredConfirmed(item) && (
                <button className="ghost-danger-button" onClick={() => markCancel(item.appointment_id)}>
                  <XCircle size={14} /> Cancel
                </button>
              )}
              {(item.status === "completed" || item.status === "cancelled" || isExpiredConfirmed(item)) && (
                <button className="ghost-danger-button" onClick={() => removeAppointment(item.appointment_id)}>
                  Delete
                </button>
              )}
            </div>
          </div>
        ))}
      </div>
    );
  };

  return (
    <div className="dashboard-container">
      <div className="page-header-row">
        <div>
          <div className="section-eyebrow">Clinical Scheduling</div>
          <h1 className="dashboard-title">Appointments</h1>
          <p className="section-copy">Confirm requests, allocate slots, and close visits.</p>
        </div>
      </div>

      {selected && (
        <div className="card section-card" style={{ marginBottom: "20px" }}>
          <div className="section-eyebrow">Slot Allocation</div>
          <h3 className="section-title">Confirm appointment for {selected.patient_email}</h3>

          <div className="consent-form-grid">
            <label className="field-group">
              <span className="field-label">Start time</span>
              <input
                className="field-input"
                type="datetime-local"
                value={startAt}
                onChange={(event) => setStartAt(event.target.value)}
              />
            </label>
            <label className="field-group">
              <span className="field-label">End time</span>
              <input
                className="field-input"
                type="datetime-local"
                value={endAt}
                onChange={(event) => setEndAt(event.target.value)}
              />
            </label>
            <label className="field-group field-span-2">
              <span className="field-label">Confirmation note</span>
              <input
                className="field-input"
                value={note}
                onChange={(event) => setNote(event.target.value)}
              />
            </label>
          </div>

          <div style={{ marginTop: "16px", display: "flex", gap: "10px" }}>
            <button className="primary-button" onClick={submitConfirm}>
              Confirm appointment
            </button>
            <button className="secondary-button" onClick={() => setSelected(null)}>
              Close
            </button>
          </div>
        </div>
      )}

      {loading && <p className="section-copy">Loading appointments...</p>}
      {!loading && (
        <>
          <div className="card section-card" style={{ marginBottom: "20px" }}>
            <div className="section-eyebrow">Pending</div>
            <h3 className="section-title">Requested appointments</h3>
            {renderList(byStatus.requested || [], "No pending appointment requests")}
          </div>

          <div className="card section-card" style={{ marginBottom: "20px" }}>
            <div className="section-eyebrow">Confirmed</div>
            <h3 className="section-title">Upcoming appointments</h3>
            {renderList(byStatus.confirmed || [], "No confirmed appointments")}
          </div>

          <div className="card section-card">
            <div className="section-eyebrow">Closed</div>
            <h3 className="section-title">History</h3>
            {renderList(
              [...(byStatus.completed || []), ...(byStatus.cancelled || [])],
              "No completed/cancelled appointments"
            )}
          </div>
        </>
      )}
    </div>
  );
};

export default Appointments;
