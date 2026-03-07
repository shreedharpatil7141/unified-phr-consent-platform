import { Link } from "react-router-dom";

const Sidebar = () => {

  return (
    <div style={{
      width:"220px",
      height:"100vh",
      background:"#0f172a",
      color:"white",
      padding:"20px",
      position:"fixed",
      left:0,
      top:0
    }}>

      <h2 style={{marginBottom:"30px"}}>Doctor Portal</h2>

      <nav style={{display:"flex",flexDirection:"column",gap:"15px"}}>

        <Link style={linkStyle} to="/">Dashboard</Link>

        <Link style={linkStyle} to="/patients">Patients</Link>

        <Link style={linkStyle} to="/consents">Consent Requests</Link>

        <Link style={linkStyle} to="/timeline">Health Timeline</Link>

        <Link style={linkStyle} to="/ai">AI Insights</Link>

      </nav>

    </div>
  );

};

const linkStyle = {
  color:"white",
  textDecoration:"none",
  fontSize:"16px"
};

export default Sidebar;