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
import { parseServerDate } from "../utils/dateTime";

ChartJS.register(
  CategoryScale,
  LinearScale,
  PointElement,
  LineElement,
  Tooltip,
  Legend,
  Filler
);

const HEART_RATE_METRIC = {
  keys: ["heart_rate", "heart rate", "heart-rate", "heartrate", "pulse_rate", "pulse rate", "pulse-rate", "hr"],
  label: "Heart Rate",
  unit: "bpm",
  color: "#ef5d78",
};

const isFiniteNumber = (value) => Number.isFinite(Number(value));
const normalizeKey = (value) =>
  String(value || "")
    .toLowerCase()
    .replace(/[_-]/g, " ")
    .replace(/\s+/g, " ")
    .trim();
const parseNumericValue = (value) => {
  if (value == null) return null;
  if (typeof value === "number" && Number.isFinite(value)) return value;
  const match = String(value).match(/-?\d+(\.\d+)?/);
  if (!match) return null;
  const parsed = Number(match[0]);
  return Number.isFinite(parsed) ? parsed : null;
};
const resolveTimestamp = (record) =>
  record.timestamp || record.recorded_at || record.created_at || record.updated_at || null;

const extractMetricEntry = (record) => {
  const recordType = normalizeKey(record.record_type || record.type);

  for (const metric of [HEART_RATE_METRIC]) {
    const metricKeys = metric.keys.map(normalizeKey);
    if (Array.isArray(record.metrics)) {
      const matchedMetric = record.metrics.find((item) =>
        metricKeys.includes(normalizeKey(item.name))
      );
      const parsedMetricValue = parseNumericValue(matchedMetric?.value);
      if (parsedMetricValue != null && isFiniteNumber(parsedMetricValue)) {
        return {
          metric,
          value: parsedMetricValue,
          timestamp: resolveTimestamp(record),
        };
      }
    }

    const parsedRecordValue = parseNumericValue(record.value);
    if (metricKeys.includes(recordType) && parsedRecordValue != null && isFiniteNumber(parsedRecordValue)) {
      return {
        metric,
        value: parsedRecordValue,
        timestamp: resolveTimestamp(record),
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

  const selectedMetric = extracted.length ? HEART_RATE_METRIC : null;

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
        {emptyMessage || "No shared heart-rate data available for this consent"}
      </div>
    );
  }

  const metricRecords = extracted
    .filter((entry) => entry.metric.label === selectedMetric.label)
    .filter((entry) => {
      const ts = parseServerDate(entry.timestamp);
      return !Number.isNaN(ts.getTime());
    })
    .sort((a, b) => parseServerDate(a.timestamp) - parseServerDate(b.timestamp));

  if (!metricRecords.length) {
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
        No valid heart-rate timeline points found for this consent.
      </div>
    );
  }

  const values = metricRecords.map((entry) => entry.value);
  const latestValue = values[values.length - 1];
  const averageValue = values.reduce((sum, value) => sum + value, 0) / values.length;
  const minValue = Math.min(...values);
  const maxValue = Math.max(...values);
  const scale = getMetricRange(selectedMetric, values);
  const latestTimestamp = parseServerDate(metricRecords[metricRecords.length - 1].timestamp);
  const firstTimestamp = parseServerDate(metricRecords[0].timestamp);
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
    labels: metricRecords.map((entry) => formatAxisTime(parseServerDate(entry.timestamp))),
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
            return formatTooltipTime(parseServerDate(point.timestamp));
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
