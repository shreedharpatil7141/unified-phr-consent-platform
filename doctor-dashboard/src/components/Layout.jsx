import { Link } from "react-router-dom";
import { LayoutDashboard, Users, FileCheck, Clock } from "lucide-react";
import "../styles/layout.css";

const Layout = ({ children }) => {

  return (
    <div className="layout">

      <div className="sidebar">

        <h2 className="logo">HealthSync</h2>

        <nav>

          <Link to="/dashboard" className="nav-item">
            <LayoutDashboard size={18}/> Dashboard
          </Link>

          <Link to="/patients" className="nav-item">
            <Users size={18}/> Patients
          </Link>

          <Link to="/consents" className="nav-item">
            <FileCheck size={18}/> Consents
          </Link>

          <Link to="/timeline" className="nav-item">
            <Clock size={18}/> Timeline
          </Link>

        </nav>

      </div>

      <div className="main-content">
        {children}
      </div>

    </div>
  );
};

export default Layout;