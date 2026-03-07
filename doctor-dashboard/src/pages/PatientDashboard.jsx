import React, { useEffect, useState } from "react";
import { getDashboardData } from "../services/api";
import PatientCard from "../components/PatientCard";
import HealthTimeline from "../components/HealthTimeline";
import VitalsChart from "../components/VitalsChart";
import AlertsPanel from "../components/AlertsPanel";
import { Activity, HeartPulse, Database, AlertTriangle } from "lucide-react";
import RiskScore from "../components/RiskScore";
import "../styles/dashboard.css";
import { useParams } from "react-router-dom";

const Dashboard = () => {

  const [data, setData] = useState(null);

  const { consentId } = useParams();

  const activeConsentId =
    consentId || "c884df4c-f717-4f05-9d18-549b5ffb415b";

  useEffect(() => {

    // Only load patient data when a consentId exists
    if (!consentId) return;

    const token = localStorage.getItem("token");

    if (!token) {
      alert("No token found. Please login again.");
      return;
    }

    getDashboardData(activeConsentId)
      .then(res => setData(res.data))
      .catch(err => console.error(err));

  }, [activeConsentId, consentId]);

  // -------------------------
  // MAIN DASHBOARD OVERVIEW
  // -------------------------

  if (!consentId) {
    return (
      <div className="dashboard-container">

        <h1 className="dashboard-title">Doctor Dashboard</h1>

        <div className="grid grid-4">

          <StatCard
            title="Patients Connected"
            value="3"
            icon={<Activity size={20}/>}
          />

          <StatCard
            title="Active Consents"
            value="2"
            icon={<Database size={20}/>}
          />

          <StatCard
            title="Health Records"
            value="15"
            icon={<HeartPulse size={20}/>}
          />

          <StatCard
            title="AI Alerts"
            value="1"
            icon={<AlertTriangle size={20}/>}
          />

        </div>

        <div className="card" style={{marginTop:"30px"}}>

          <h3>Recent Activity</h3>

          <ul>
            <li>Patient shared cardiology reports</li>
            <li>Wearable device uploaded vitals</li>
            <li>Doctor accessed unified health record</li>
          </ul>

        </div>

      </div>
    );
  }

  // -------------------------
  // PATIENT DETAIL PAGE
  // -------------------------

  if (!data) {
    return (
      <div className="dashboard-container">
        Loading Patient Data...
      </div>
    );
  }

  const patientEmail =
    data.records?.[0]?.patient_id || "patient@test.com";

  return (

    <div className="dashboard-container">

      <h1 className="dashboard-title">Patient Health Dashboard</h1>

      <div className="grid grid-4">

        <StatCard
          title="Patient"
          value={patientEmail}
          icon={<Activity size={20}/>}
        />

        <StatCard
          title="Records"
          value={data.records.length}
          icon={<Database size={20}/>}
        />

        <StatCard
          title="Vitals"
          value="Heart Rate"
          icon={<HeartPulse size={20}/>}
        />

        <StatCard
          title="Alerts"
          value="AI Monitoring"
          icon={<AlertTriangle size={20}/>}
        />

      </div>

      <div className="grid grid-2" style={{marginTop:"30px"}}>

        <div className="card">
          <h3>Status</h3>
          <span className="status-success">
            {data.message}
          </span>
        </div>

        <PatientCard patientEmail={patientEmail}/>

      </div>

      <div className="grid grid-chart" style={{marginTop:"30px"}}>

        <div className="card">
          <h3 style={{marginBottom:"10px"}}>Vitals Trend</h3>
          <VitalsChart records={data.records}/>
        </div>

        <div style={{display:"flex",flexDirection:"column",gap:"20px"}}>
          <AlertsPanel records={data.records}/>
          <RiskScore records={data.records}/>
        </div>

      </div>

      <div className="card" style={{marginTop:"30px"}}>
        <h3 style={{marginBottom:"15px"}}>Unified Health Timeline</h3>
        <HealthTimeline records={data.records}/>
      </div>

    </div>

  );
};

const StatCard = ({title,value,icon}) => {

  return(

    <div className="card stat-card">

      <div>
        <p className="stat-title">{title}</p>
        <h2 className="stat-value">{value}</h2>
      </div>

      <div className="icon-box">
        {icon}
      </div>

    </div>

  );

};

export default Dashboard;