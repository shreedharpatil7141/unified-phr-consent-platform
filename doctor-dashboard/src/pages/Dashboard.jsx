import { Activity, Database, HeartPulse, AlertTriangle } from "lucide-react";
import "../styles/dashboard.css";

const Dashboard = () => {

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
          <li>Patient shared cardiology report</li>
          <li>Wearable device uploaded vitals</li>
          <li>Doctor accessed unified health record</li>
        </ul>

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