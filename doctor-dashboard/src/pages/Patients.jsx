import { useEffect, useState } from "react";
import axios from "axios";
import { useNavigate } from "react-router-dom";

const Patients = () => {

  const [consents,setConsents] = useState([]);
  const navigate = useNavigate();

  useEffect(()=>{

    const token = localStorage.getItem("token");

    axios.get("http://127.0.0.1:8000/consent/sent",{
      headers:{
        Authorization:`Bearer ${token}`
      }
    })
    .then(res => {

      const approved = res.data.filter(c => c.status === "approved");
      setConsents(approved);

    })
    .catch(err => console.error(err));

  },[]);

  return(

    <div>

      <h1 style={{marginBottom:"20px"}}>Patients</h1>

      {consents.length === 0 && (
        <p>No approved patient consents yet</p>
      )}

      {consents.map((c,index)=>(

        <div key={index} style={{
          background:"white",
          padding:"16px",
          borderRadius:"10px",
          marginBottom:"10px",
          boxShadow:"0 2px 10px rgba(0,0,0,0.05)"
        }}>

          <p><b>Patient:</b> {c.patient_id}</p>
          <p><b>Status:</b> {c.status}</p>

          <button
            onClick={()=>navigate(`/patient/${c.consent_id}`)}
            style={{
              marginTop:"10px",
              padding:"8px 16px",
              background:"#2563eb",
              color:"white",
              border:"none",
              borderRadius:"6px",
              cursor:"pointer"
            }}
          >
            View Records
          </button>

        </div>

      ))}

    </div>

  );

};

export default Patients;