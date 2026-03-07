const RiskScore = ({ records }) => {

  const heartRates = records
    .flatMap(r => r.metrics)
    .filter(m => m.name === "heart_rate")
    .map(m => m.value);

  let score = 90;
  let factors = [];

  if (heartRates.length >= 2) {

    const first = heartRates[0];
    const last = heartRates[heartRates.length - 1];

    if (last > first) {
      score -= 10;
      factors.push("Increasing heart rate trend");
    }

    if (last > 100) {
      score -= 15;
      factors.push("High resting heart rate");
    }

  }

  if (factors.length === 0) {
    factors.push("No major risk detected");
  }

  return (

    <div className="card">

      <h3 style={{marginBottom:"10px"}}>AI Health Risk Score</h3>

      <h1 style={{
        fontSize:"36px",
        color:"#2563eb",
        marginBottom:"10px"
      }}>
        {score}%
      </h1>

      <div>

        {factors.map((f,i)=>(
          <p key={i}>
            • {f}
          </p>
        ))}

      </div>

    </div>

  );

};

export default RiskScore;