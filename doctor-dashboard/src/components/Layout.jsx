import { Link, useNavigate } from "react-router-dom";
import { LayoutDashboard, Users, FileCheck, Bell, ShieldCheck, CalendarClock, LogOut } from "lucide-react";
import { useEffect, useState } from "react";

import "../styles/layout.css";
import "../styles/dashboard.css";
import { getNotifications } from "../services/doctorService";

const Layout = ({ children }) => {
  const [notifCount, setNotifCount] = useState(0);
  const [doctorName, setDoctorName] = useState("");
  const navigate = useNavigate();

  const refreshNotifications = () => {
    const token = localStorage.getItem("token");
    if (!token) {
      setNotifCount(0);
      return;
    }

    getNotifications(token)
      .then((data) => {
        const unreadCount = (data || []).filter((note) => !note.read).length;
        setNotifCount(unreadCount);
      })
      .catch(() => {});
  };

  useEffect(() => {
    setDoctorName(localStorage.getItem("name") || "Doctor");
    refreshNotifications();
    const poller = setInterval(refreshNotifications, 15000);

    const handleNotificationsChanged = () => refreshNotifications();
    window.addEventListener("notifications:changed", handleNotificationsChanged);

    return () => {
      clearInterval(poller);
      window.removeEventListener("notifications:changed", handleNotificationsChanged);
    };
  }, []);

  const handleLogout = () => {
    localStorage.removeItem("token");
    localStorage.removeItem("name");
    localStorage.removeItem("email");
    navigate("/login");
  };

  return (
    <div className="layout">
      <div className="sidebar">
        <div>
          <h2 className="logo">HealthSync</h2>
          <div
            style={{
              color: "#e2e8f0",
              marginBottom: "12px",
              fontWeight: 700,
              fontSize: "14px",
            }}
          >
            Dr. {doctorName}
          </div>
          <div className="section-copy" style={{ color: "#94a3b8", marginBottom: "24px" }}>
            Doctor command center
          </div>

          <nav>
            <Link to="/dashboard" className="nav-item">
              <LayoutDashboard size={18} /> Dashboard
            </Link>

            <Link to="/patients" className="nav-item">
              <Users size={18} /> Patients
            </Link>

            <Link to="/consents" className="nav-item">
              <FileCheck size={18} /> Consents
            </Link>

            <Link to="/notifications" className="nav-item" style={{ position: "relative" }}>
              <Bell size={18} /> Notifications
              {notifCount > 0 && (
                <span
                  style={{
                    position: "absolute",
                    top: "0",
                    right: "10px",
                    background: "red",
                    color: "white",
                    borderRadius: "50%",
                    padding: "2px 6px",
                    fontSize: "10px",
                  }}
                >
                  {notifCount}
                </span>
              )}
            </Link>

            <Link to="/audit-logs" className="nav-item">
              <ShieldCheck size={18} /> Audit Logs
            </Link>

            <Link to="/appointments" className="nav-item">
              <CalendarClock size={18} /> Appointments
            </Link>
          </nav>
        </div>

        <button className="logout-button" onClick={handleLogout}>
          <LogOut size={16} /> Logout
        </button>
      </div>

      <div className="main-content">{children}</div>
    </div>
  );
};

export default Layout;
