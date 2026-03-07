const PatientCard = ({ patientEmail }) => {

  return (
    <div style={{
      background:"white",
      padding:"20px",
      borderRadius:"10px",
      boxShadow:"0 2px 8px rgba(0,0,0,0.05)"
    }}>
      <h3>Patient Info</h3>

      <p><strong>Email:</strong> {patientEmail}</p>
      <p><strong>Status:</strong> Active Consent</p>

    </div>
  )

}

export default PatientCard