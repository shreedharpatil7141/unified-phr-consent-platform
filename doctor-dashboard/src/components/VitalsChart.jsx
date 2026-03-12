import { Line } from "react-chartjs-2";
import {
  Chart as ChartJS,
  CategoryScale,
  LinearScale,
  PointElement,
  LineElement,
  Tooltip,
  Legend,
  Filler,
} from "chart.js";

ChartJS.register(
  CategoryScale,
  LinearScale,
  PointElement,
  LineElement,
  Tooltip,
  Legend,
  Filler
);

const METRIC_PRIORITY = [
  { keys: ["heart_rate", "heart rate", "pulse_rate", "pulse rate"], label: "Heart Rate", unit: "bpm", color: "#ef5d78" },
  { keys: ["steps"], label: "Steps", unit: "steps", color: "#22c55e" },
  { keys: ["distance"], label: "Distance", unit: "km", color: "#facc15" },
  { keys: ["spo2", "oxygen saturation"], label: "SpO2", unit: "%", color: "#06b6d4" },
  { keys: ["temperature", "body temperature"], label: "Temperature", unit: "C", color: "#f97316" },
  { keys: ["weight"], label: "Weight", unit: "kg", color: "#8b5cf6" },
];

const isFiniteNumber = (value) => Number.isFinite(Number(value));

const extractMetricEntry = (record) => {
  const recordType = (record.record_type || record.type || "").toLowerCase();

  for (const metric of METRIC_PRIORITY) {
    if (Array.isArray(record.metrics)) {
      const matchedMetric = record.metrics.find((item) =>
        metric.keys.includes((item.name || "").toLowerCase())
      );
      if (matchedMetric?.value != null && isFiniteNumber(matchedMetric.value)) {
        return {
          metric,
          value: Number(matchedMetric.value),
          timestamp: record.timestamp,
        };
      }
    }

    if (metric.keys.includes(recordType) && record.value != null && isFiniteNumber(record.value)) {
      return {
        metric,
        value: Number(record.value),
        timestamp: record.timestamp,
      };
    }
  }

  return null;
};

const getMetricRange = (metric, values) => {
  const minValue = Math.min(...values);
  const maxValue = Math.max(...values);

  if (metric.label === "Heart Rate") {
    return {
      min: Math.max(40, Math.floor((minValue - 8) / 10) * 10),
      max: Math.min(140, Math.ceil((maxValue + 8) / 10) * 10),
      step: 10,
    };
  }

  const span = Math.max(1, maxValue - minValue);
  const padding = Math.max(1, span * 0.15);
  const min = Math.max(0, minValue - padding);
  const max = maxValue + padding;
  const step = span <= 10 ? 2 : span <= 40 ? 5 : Math.ceil(span / 4);

  return { min, max, step };
};

const formatAxisTime = (date) =>
  date.toLocaleTimeString([], {
    hour: "numeric",
    minute: "2-digit",
  });

const formatTooltipTime = (date) =>
  date.toLocaleString([], {
    day: "numeric",
    month: "short",
    hour: "numeric",
    minute: "2-digit",
  });

const formatHeaderTime = (date) =>
  date.toLocaleString([], {
    day: "numeric",
    month: "short",
    hour: "numeric",
    minute: "2-digit",
  });

const formatValue = (value, unit) => {
  if (unit === "km") {
    return `${value.toFixed(2)} ${unit}`;
  }
  return `${Math.round(value)} ${unit}`;
};

const SummaryChip = ({ label, value, accent }) => (
  <div
    style={{
      flex: 1,
      minWidth: "90px",
      padding: "12px 14px",
      borderRadius: "14px",
      background: `${accent}12`,
      border: `1px solid ${accent}22`,
    }}
  >
    <div style={{ fontSize: "12px", color: "#6b7280", marginBottom: "6px" }}>{label}</div>
    <div style={{ fontSize: "18px", fontWeight: 700, color: "#111827" }}>{value}</div>
  </div>
);

const VitalsChart = ({ records, emptyMessage }) => {
  const extracted = (records || [])
    .map(extractMetricEntry)
    .filter(Boolean);

  const selectedMetric = METRIC_PRIORITY.find((metric) =>
    extracted.some((entry) => entry.metric.label === metric.label)
  );

  if (!selectedMetric) {
    return (
      <div
        style={{
          height: "300px",
          display: "flex",
          alignItems: "center",
          justifyContent: "center",
          color: "#6b7280",
          textAlign: "center",
          padding: "0 24px",
        }}
      >
        {emptyMessage || "No shared vitals available for this consent"}
      </div>
    );
  }

  const metricRecords = extracted
    .filter((entry) => entry.metric.label === selectedMetric.label)
    .sort((a, b) => new Date(a.timestamp) - new Date(b.timestamp));

  const values = metricRecords.map((entry) => entry.value);
  const latestValue = values[values.length - 1];
  const averageValue = values.reduce((sum, value) => sum + value, 0) / values.length;
  const minValue = Math.min(...values);
  const maxValue = Math.max(...values);
  const scale = getMetricRange(selectedMetric, values);
  const latestTimestamp = new Date(metricRecords[metricRecords.length - 1].timestamp);
  const firstTimestamp = new Date(metricRecords[0].timestamp);
  const rangeLabel =
    metricRecords.length > 1
      ? `${firstTimestamp.toLocaleDateString([], {
          day: "numeric",
          month: "short",
        })} - ${latestTimestamp.toLocaleDateString([], {
          day: "numeric",
          month: "short",
        })}`
      : firstTimestamp.toLocaleDateString([], {
          day: "numeric",
          month: "short",
          year: "numeric",
        });

  const data = {
    labels: metricRecords.map((entry) => formatAxisTime(new Date(entry.timestamp))),
    datasets: [
      {
        label: `${selectedMetric.label} (${selectedMetric.unit})`,
        data: values,
        borderColor: selectedMetric.color,
        backgroundColor: `${selectedMetric.color}22`,
        pointBackgroundColor: selectedMetric.color,
        pointBorderColor: "#ffffff",
        pointBorderWidth: 1.5,
        pointRadius: values.length <= 40 ? 3 : 1.5,
        pointHoverRadius: 5,
        borderWidth: 3,
        tension: 0.38,
        fill: true,
      },
    ],
  };

  const options = {
    responsive: true,
    maintainAspectRatio: false,
    interaction: {
      mode: "index",
      intersect: false,
    },
    plugins: {
      legend: {
        display: false,
      },
      tooltip: {
        backgroundColor: "#111827",
        titleColor: "#f9fafb",
        bodyColor: "#f9fafb",
        padding: 12,
        displayColors: false,
        callbacks: {
          title: (tooltipItems) => {
            const item = tooltipItems[0];
            const point = metricRecords[item.dataIndex];
            return formatTooltipTime(new Date(point.timestamp));
          },
          label: (context) => formatValue(context.parsed.y, selectedMetric.unit),
        },
      },
    },
    scales: {
      x: {
        grid: {
          display: false,
        },
        border: {
          display: false,
        },
        ticks: {
          maxTicksLimit: 6,
          color: "#6b7280",
          font: {
            size: 11,
          },
        },
      },
      y: {
        position: "right",
        min: scale.min,
        max: scale.max,
        ticks: {
          stepSize: scale.step,
          color: "#6b7280",
          font: {
            size: 11,
          },
        },
        grid: {
          color: "#e5e7eb",
          drawBorder: false,
        },
        border: {
          display: false,
        },
      },
    },
  };

  return (
    <div>
      <div
        style={{
          display: "flex",
          justifyContent: "space-between",
          alignItems: "flex-start",
          gap: "16px",
          marginBottom: "16px",
          flexWrap: "wrap",
        }}
      >
        <div>
          <div style={{ fontSize: "13px", fontWeight: 700, color: selectedMetric.color, letterSpacing: "0.04em", textTransform: "uppercase" }}>
            {selectedMetric.label}
          </div>
          <div style={{ fontSize: "26px", fontWeight: 800, color: "#0f172a", marginTop: "4px" }}>
            {formatValue(latestValue, selectedMetric.unit)}
          </div>
          <div style={{ fontSize: "13px", color: "#64748b", marginTop: "6px" }}>
            Last updated {formatHeaderTime(latestTimestamp)}
          </div>
        </div>

        <div
          style={{
            padding: "10px 14px",
            borderRadius: "999px",
            background: "#f8fafc",
            border: "1px solid #e2e8f0",
            color: "#475569",
            fontSize: "13px",
            fontWeight: 600,
          }}
        >
          {rangeLabel}
        </div>
      </div>

      <div style={{ display: "flex", gap: "12px", marginBottom: "18px", flexWrap: "wrap" }}>
        <SummaryChip label="Current" value={formatValue(latestValue, selectedMetric.unit)} accent={selectedMetric.color} />
        <SummaryChip label="Average" value={formatValue(averageValue, selectedMetric.unit)} accent={selectedMetric.color} />
        <SummaryChip label="Min" value={formatValue(minValue, selectedMetric.unit)} accent={selectedMetric.color} />
        <SummaryChip label="Max" value={formatValue(maxValue, selectedMetric.unit)} accent={selectedMetric.color} />
      </div>

      <div
        style={{
          height: "320px",
          padding: "18px 18px 10px",
          borderRadius: "22px",
          background: `linear-gradient(180deg, ${selectedMetric.color}12 0%, #ffffff 24%)`,
          border: "1px solid #e2e8f0",
          boxShadow: "inset 0 1px 0 rgba(255,255,255,0.7)",
        }}
      >
        <Line data={data} options={options} />
      </div>
    </div>
  );
};

export default VitalsChart;
