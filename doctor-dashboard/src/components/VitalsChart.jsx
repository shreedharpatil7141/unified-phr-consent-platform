import { Line } from "react-chartjs-2";
import {
  Chart as ChartJS,
  CategoryScale,
  LinearScale,
  PointElement,
  LineElement,
  Tooltip,
  Legend
} from "chart.js";

ChartJS.register(
  CategoryScale,
  LinearScale,
  PointElement,
  LineElement,
  Tooltip,
  Legend
);

const VitalsChart = ({ records }) => {

  const heartRecords = records.filter(
    r => r.category === "cardiology"
  );

  const labels = heartRecords.map(r =>
    new Date(r.timestamp).toLocaleDateString()
  );

  const values = heartRecords.map(r =>
    r.metrics.find(m => m.name === "heart_rate")?.value || 0
  );

  const data = {
    labels,
    datasets: [
      {
        label: "Heart Rate (bpm)",
        data: values,
        borderColor: "#2563eb",
        backgroundColor: "rgba(37,99,235,0.2)",
        tension: 0.4,
        fill: true,
        pointRadius: 4
      }
    ]
  };

  const options = {
    responsive: true,
    maintainAspectRatio: false
  };

  return (
    <div style={{ height: "300px" }}>
      <Line data={data} options={options} />
    </div>
  );
};

export default VitalsChart;