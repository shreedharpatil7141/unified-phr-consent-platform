const AlertsPanel = ({ aiInsight, loading }) => {
  if (loading) {
    return (
      <div className="card insight-card">
        <div className="section-eyebrow">Preventive Insight</div>
        <h3 className="section-title">AI Preventive Alerts</h3>
        <div className="insight-banner insight-safe">
          <div className="insight-banner-title">Loading AI insight...</div>
          <div className="insight-banner-text">Fetching consent-scoped analysis.</div>
        </div>
      </div>
    );
  }

  const hasInsight = !!aiInsight;
  const alertMessage = !hasInsight
    ? "AI insight unavailable"
    : aiInsight.source === "no_vitals"
      ? "No shared vitals in this consent"
      : "AI consent-scoped insight";

  const alertMeta = !hasInsight
    ? "No analysis could be generated for this consent."
    : aiInsight.insight || "No insight generated.";

  const alertTone =
    !hasInsight || aiInsight.source === "no_vitals"
      ? "warning"
      : aiInsight.risk_tone === "critical"
        ? "critical"
        : aiInsight.risk_tone === "warning"
          ? "warning"
          : "safe";

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
