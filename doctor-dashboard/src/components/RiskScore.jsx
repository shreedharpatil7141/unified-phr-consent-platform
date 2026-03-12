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

const RiskScore = ({ records }) => {
  const heartRates = (records || [])
    .map(extractHeartValue)
    .filter((value) => Number.isFinite(value));

  let score = 90;
  const factors = [];

  if (heartRates.length >= 2) {
    const first = heartRates[0];
    const last = heartRates[heartRates.length - 1];
    const avg = heartRates.reduce((sum, value) => sum + value, 0) / heartRates.length;

    if (last > first) {
      score -= 10;
      factors.push("Increasing heart-rate trend in the shared records");
    }

    if (avg > 95) {
      score -= 10;
      factors.push("Average heart rate is elevated");
    }

    if (Math.max(...heartRates) > 110) {
      score -= 8;
      factors.push("Peak heart-rate readings cross 110 bpm");
    }
  }

  if (factors.length === 0) {
    factors.push("No major cardiometabolic risk signal detected from shared vitals");
  }

  const tone = score >= 80 ? "safe" : score >= 65 ? "warning" : "critical";

  return (
    <div className="card insight-card">
      <div className="section-eyebrow">Risk Estimate</div>
      <h3 className="section-title">AI Health Risk Score</h3>

      <div className={`risk-score risk-score-${tone}`}>
        <div className="risk-score-value">{score}%</div>
        <div className="risk-score-caption">based on the shared vitals set</div>
      </div>

      <div className="insight-list">
        {factors.map((factor, index) => (
          <div key={index} className="insight-list-item">
            {factor}
          </div>
        ))}
      </div>
    </div>
  );
};

export default RiskScore;
