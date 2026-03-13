const RiskScore = ({ aiInsight, loading }) => {
  const hasScore = Number.isFinite(aiInsight?.risk_score);
  const score = hasScore ? aiInsight.risk_score : null;
  const tone = aiInsight?.risk_tone || "safe";
  const factors = [];

  if (loading) {
    factors.push("Calculating AI-backed risk from shared consented records.");
  } else if (!aiInsight) {
    factors.push("AI risk insight is unavailable for this consent.");
  } else if (aiInsight.source === "no_vitals") {
    factors.push("No vitals are shared in this consent scope, so risk score cannot be computed.");
  } else {
    factors.push(aiInsight.insight || "AI insight generated for consented vitals.");
    if (aiInsight.sample_size != null) {
      factors.push(`Analyzed ${aiInsight.sample_size} heart-rate samples in shared data.`);
    }
  }

  return (
    <div className="card insight-card">
      <div className="section-eyebrow">Risk Estimate</div>
      <h3 className="section-title">AI Health Risk Score</h3>

      <div className={`risk-score risk-score-${tone}`}>
        <div className="risk-score-value">{hasScore ? `${score}%` : "N/A"}</div>
        <div className="risk-score-caption">
          {hasScore ? "computed from consent-shared vitals" : "insufficient vitals in shared scope"}
        </div>
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
