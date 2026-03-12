const HealthAlerts = ({ records }) => {

  const metricRecords = records.filter(
    (r) => Array.isArray(r.metrics) && r.metrics.length > 0
  )

  if(metricRecords.length < 3) return null

  const values = metricRecords
    .map(r =>
      r.metrics.find(m => m.name === "heart_rate")?.value
    )
    .filter((value) => value !== undefined && value !== null)

  if(values.length < 3) return null

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
