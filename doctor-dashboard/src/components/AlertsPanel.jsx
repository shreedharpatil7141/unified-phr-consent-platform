const extractHeartValue = (record) => {
  if (Array.isArray(record.metrics)) {
    const metric =
      record.metrics.find((m) => m.name === "heart_rate") ||
      record.metrics.find((m) => m.name === "Heart Rate") ||
      record.metrics.find((m) => m.name === "heart rate");
    if (metric?.value != null) {
      return Number(metric.value);
    }
  }

  const recordType = (record.record_type || record.type || "").toLowerCase();
  if (
    recordType === "heart rate" ||
    recordType === "heart_rate" ||
    recordType === "pulse rate" ||
    recordType === "pulse_rate"
  ) {
    return Number(record.value || 0);
  }

  return null;
};

const AlertsPanel = ({ records }) => {
  const heartRates = (records || [])
    .map(extractHeartValue)
    .filter((value) => Number.isFinite(value));

  let alertMessage = "No abnormal trends detected";
  let alertTone = "safe";
  let alertMeta = "Vitals look stable across the currently shared dataset.";

  if (heartRates.length >= 3) {
    const last = heartRates[heartRates.length - 1];
    const first = heartRates[0];
    const max = Math.max(...heartRates);

    if (last - first > 8) {
      alertMessage = "Rising heart-rate trend detected";
      alertTone = "warning";
      alertMeta = "Recommend reviewing recent activity, symptoms, and cardiac history.";
    } else if (max > 105) {
      alertMessage = "High peak heart-rate reading detected";
      alertTone = "warning";
      alertMeta = "Shared vitals include elevated readings that may need clinical correlation.";
    }
  }

  return (
    <div className="card insight-card">
      <div className="section-eyebrow">Preventive Insight</div>
      <h3 className="section-title">AI Preventive Alerts</h3>

      <div className={`insight-banner insight-${alertTone}`}>
        <div className="insight-banner-title">{alertMessage}</div>
        <div className="insight-banner-text">{alertMeta}</div>
      </div>
    </div>
  );
};

export default AlertsPanel;
