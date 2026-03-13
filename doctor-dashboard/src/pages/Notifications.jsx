import React, { useEffect, useMemo, useState } from "react";
import { Bell, CheckCheck, Trash2 } from "lucide-react";

import {
  deleteNotification,
  getNotifications,
  markNotificationRead,
} from "../services/doctorService";
import "../styles/dashboard.css";
import { formatServerDateTime } from "../utils/dateTime";

const Notifications = () => {
  const [notes, setNotes] = useState([]);
  const [loading, setLoading] = useState(true);

  const unreadCount = useMemo(
    () => notes.filter((note) => !note.read).length,
    [notes]
  );

  const publishNotificationChange = () => {
    window.dispatchEvent(new Event("notifications:changed"));
  };

  const loadNotifications = async () => {
    setLoading(true);
    try {
      const token = localStorage.getItem("token");
      const data = await getNotifications(token);
      setNotes(data || []);
    } catch (error) {
      console.error("Failed to load notifications", error);
    } finally {
      setLoading(false);
      publishNotificationChange();
    }
  };

  useEffect(() => {
    loadNotifications();
  }, []);

  const handleMarkRead = async (id) => {
    const previousNotes = notes;
    setNotes((current) =>
      current.map((note) =>
        note.notification_id === id ? { ...note, read: true } : note
      )
    );
    publishNotificationChange();

    try {
      const token = localStorage.getItem("token");
      await markNotificationRead(id, token);
    } catch (error) {
      console.error("Failed to mark notification as read", error);
      setNotes(previousNotes);
      publishNotificationChange();
    }
  };

  const handleDelete = async (id) => {
    const previousNotes = notes;
    setNotes((current) => current.filter((note) => note.notification_id !== id));
    publishNotificationChange();

    try {
      const token = localStorage.getItem("token");
      await deleteNotification(id, token);
    } catch (error) {
      console.error("Failed to delete notification", error);
      setNotes(previousNotes);
      publishNotificationChange();
    }
  };

  return (
    <div className="dashboard-container">
      <div className="page-header-row">
        <div>
          <div className="section-eyebrow">Activity Center</div>
          <h1 className="dashboard-title">Notifications</h1>
          <p className="section-copy">
            Read updates, remove noise, and keep your unread badge accurate.
          </p>
        </div>
        <div className="debug-pill">
          <span className="debug-label">Unread</span>
          <span className="debug-value">{unreadCount}</span>
        </div>
      </div>

      <div className="card section-card">
        <div className="section-eyebrow">Inbox</div>
        <h3 className="section-title">Recent clinical updates</h3>

        {loading && <p className="section-copy">Loading notifications...</p>}
        {!loading && notes.length === 0 && (
          <p className="section-copy">No notifications yet.</p>
        )}

        <div className="notification-list">
          {notes.map((note) => (
            <div
              key={note.notification_id}
              className={`notification-item ${note.read ? "notification-item-read" : ""}`}
            >
              <div className="notification-icon">
                <Bell size={16} />
              </div>

                <div className="notification-content">
                  <div className="notification-message">{note.message}</div>
                  <div className="notification-meta">
                    {formatServerDateTime(note.created_at)}
                  </div>
                </div>

              <div className="notification-actions">
                {!note.read && (
                  <button
                    className="secondary-button"
                    onClick={() => handleMarkRead(note.notification_id)}
                  >
                    <CheckCheck size={14} /> Mark read
                  </button>
                )}

                <button
                  className="ghost-danger-button"
                  onClick={() => handleDelete(note.notification_id)}
                >
                  <Trash2 size={14} /> Delete
                </button>
              </div>
            </div>
          ))}
        </div>
      </div>
    </div>
  );
};

export default Notifications;
