import { Line } from "react-chartjs-2";

const HealthTrendChart = ({ records }) => {

  const labels = records.map(r => r.timestamp);

  const values = records.map(r =>
    r.metrics.find(m => m.name === "heart_rate")?.value
  );

  const data = {
    labels: labels,
    datasets: [
      {
        label: "Heart Rate",
        data: values,
        borderColor: "#4f46e5",
        backgroundColor: "rgba(79,70,229,0.2)",
        tension:0.3
      }
    ]
  };

  return (
    <div>
      <Line data={data}/>
    </div>
  );
};

export default HealthTrendChart;