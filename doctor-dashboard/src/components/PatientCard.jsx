const PatientCard = ({ patientEmail, profile = {} }) => {
  const chips = [
    profile.height_cm ? `Height ${profile.height_cm} cm` : null,
    profile.weight_kg ? `Weight ${profile.weight_kg} kg` : null,
    profile.blood_group ? `Blood ${profile.blood_group}` : null,
    profile.allergies ? `Allergies ${profile.allergies}` : null,
  ].filter(Boolean);

  return (
    <div style={{
      background:"white",
      padding:"20px",
      borderRadius:"10px",
      boxShadow:"0 2px 8px rgba(0,0,0,0.05)"
    }}>
      <h3>Patient Info</h3>

      <p><strong>Email:</strong> {patientEmail}</p>
      {profile.name && <p><strong>Name:</strong> {profile.name}</p>}
      <p><strong>Status:</strong> Active Consent</p>
      {chips.length > 0 && (
        <p><strong>Baseline:</strong> {chips.join(" • ")}</p>
      )}

    </div>
  )

}

export default PatientCard
