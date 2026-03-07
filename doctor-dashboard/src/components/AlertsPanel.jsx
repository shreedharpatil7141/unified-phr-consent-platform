const AlertsPanel = ({ records }) => {

  const heartRates = records
    .flatMap(r => r.metrics)
    .filter(m => m.name === "heart_rate")
    .map(m => m.value);

  let alertMessage = "No abnormal trends detected";
  let alertClass = "alert-safe";

  if (heartRates.length >= 3) {

    const last = heartRates[heartRates.length-1];
    const first = heartRates[0];

    if (last - first > 8) {
      alertMessage = "⚠ Rising heart rate detected. Recommend cardiology review.";
      alertClass = "alert-warning";
    }

  }

  return (

    <div className="card">

      <h3 style={{marginBottom:"10px"}}>AI Preventive Alerts</h3>

      <div className={alertClass}>
        {alertMessage}
      </div>

    </div>

  );

};

export default AlertsPanel;