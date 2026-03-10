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

const PatientDashboard = () => {

  const [data, setData] = useState(null);

  const { consentId } = useParams();

  const activeConsentId = consentId;

  useEffect(() => {

    if (!activeConsentId) return;

    const token = localStorage.getItem("token");

    if (!token) {
      alert("No token found. Please login again.");
      return;
    }

    getDashboardData(activeConsentId, token)
      .then(res => {

        if (res && res.data) {
          setData(res.data);
        } else {
          setData({ records: [], message: "No data available" });
        }

      })
      .catch(err => {
        console.error("Dashboard load error:", err);
        setData({ records: [], message: "Failed to load patient data" });
      });

  }, [activeConsentId]);

  if (!consentId) {
    return (
      <div className="dashboard-container">
        <h1 className="dashboard-title">Doctor Dashboard</h1>

        <div className="grid grid-4">

          <StatCard title="Patients Connected" value="3" icon={<Activity size={20}/>} />
          <StatCard title="Active Consents" value="2" icon={<Database size={20}/>} />
          <StatCard title="Health Records" value="15" icon={<HeartPulse size={20}/>} />
          <StatCard title="AI Alerts" value="1" icon={<AlertTriangle size={20}/>} />

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

  if (!data) {
    return (
      <div className="dashboard-container">
        Loading Patient Data...
      </div>
    );
  }

  const records = data.records || [];

  const patientEmail = data.patient_id;

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
          value={records.length}
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
          <VitalsChart records={records}/>
        </div>

        <div style={{display:"flex",flexDirection:"column",gap:"20px"}}>
          <AlertsPanel records={records}/>
          <RiskScore records={records}/>
        </div>

      </div>

      {/* -------- DOCUMENTS SECTION (NEW) -------- */}

      <div className="card" style={{marginTop:"30px"}}>

        <h3 style={{marginBottom:"15px"}}>Medical Documents</h3>

        {records
          .filter(r => r.file_url)
          .map((r,index)=>(
            <div key={index} style={{marginBottom:"10px"}}>

              <b>{r.recordName || "Medical File"}</b>

              <div>
                <a
                  href={r.file_url}
                  target="_blank"
                  rel="noreferrer"
                  style={{color:"#2563eb"}}
                >
                  View PDF
                </a>
              </div>

            </div>
        ))}

        {records.filter(r => r.file_url).length === 0 && (
          <p>No uploaded documents</p>
        )}

      </div>

      {/* -------- TIMELINE -------- */}

      <div className="card" style={{marginTop:"30px"}}>
        <h3 style={{marginBottom:"15px"}}>Unified Health Timeline</h3>
        <HealthTimeline records={records}/>
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

export default PatientDashboard;