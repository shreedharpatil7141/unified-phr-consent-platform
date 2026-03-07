const HealthTimeline = ({ records }) => {

  const sorted = [...records].sort(
    (a,b)=> new Date(b.timestamp) - new Date(a.timestamp)
  );

  return (

    <div className="timeline">

      {sorted.map((r,i)=>(
        <div key={i} className="timeline-item">

          <strong>{r.category}</strong>

          <p>{new Date(r.timestamp).toLocaleString()}</p>

          <p>
            {r.source} • {r.provider}
          </p>

        </div>
      ))}

    </div>

  );

};

export default HealthTimeline;