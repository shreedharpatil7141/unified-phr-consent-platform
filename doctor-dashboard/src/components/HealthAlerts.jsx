const HealthAlerts = ({ records }) => {

  if(records.length < 3) return null

  const values = records.map(r =>
    r.metrics.find(m => m.name === "heart_rate")?.value
  )

  const increasing =
    values[values.length-1] > values[0] + 10

  if(!increasing) return null

  return (
    <div style={{
      background:"#fff3cd",
      padding:"20px",
      borderRadius:"10px",
      marginBottom:"20px"
    }}>
      ⚠ Preventive Alert: Increasing heart rate trend detected.
      Recommend cardiology check-up.
    </div>
  )
}

export default HealthAlerts