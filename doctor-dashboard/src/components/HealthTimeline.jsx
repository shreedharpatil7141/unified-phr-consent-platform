import { formatServerDateTime, parseServerDate } from "../utils/dateTime";

const formatTime = (timestamp) =>
  formatServerDateTime(timestamp, {
    day: "numeric",
    month: "short",
    hour: "numeric",
    minute: "2-digit",
  });

const buildGroupedTimeline = (records = []) => {
  const vitals = records.filter(
    (record) => !(record.file_url || record.file_name)
  );
  const documents = records.filter(
    (record) => !!(record.file_url || record.file_name)
  );

  const grouped = [];

  if (vitals.length) {
    const latestVital = [...vitals].sort(
      (a, b) => parseServerDate(b.timestamp) - parseServerDate(a.timestamp)
    )[0];
    const types = [...new Set(vitals.map((record) => record.record_type || record.type).filter(Boolean))];

    grouped.push({
      id: "group-vitals",
      category: "Vitals",
      title: `Shared vitals bundle`,
      timestamp: latestVital.timestamp,
      meta: `${vitals.length} readings - ${types.slice(0, 4).join(", ")}`,
    });
  }

  if (documents.length) {
    const latestDocument = [...documents].sort(
      (a, b) => parseServerDate(b.timestamp) - parseServerDate(a.timestamp)
    )[0];
    const domains = [...new Set(documents.map((record) => record.domain).filter(Boolean))];

    grouped.push({
      id: "group-documents",
      category: "Documents",
      title: `Shared medical documents`,
      timestamp: latestDocument.timestamp,
      meta: `${documents.length} file(s) - ${domains.slice(0, 3).join(", ") || "clinical attachments"}`,
    });
  }

  return grouped.sort(
    (a, b) => parseServerDate(b.timestamp) - parseServerDate(a.timestamp)
  );
};

const HealthTimeline = ({ records }) => {
  const grouped = buildGroupedTimeline(records);

  if (!grouped.length) {
    return <div className="timeline-empty">No shared records available for this consent.</div>;
  }

  return (
    <div className="timeline">
      {grouped.map((item) => (
        <div key={item.id} className="timeline-item">
          <div className="timeline-dot" />
          <div className="timeline-content">
            <div className="timeline-row">
              <div className="timeline-category">{item.category}</div>
              <div className="timeline-time">{formatTime(item.timestamp)}</div>
            </div>
            <div className="timeline-title">{item.title}</div>
            <div className="timeline-meta">{item.meta}</div>
          </div>
        </div>
      ))}
    </div>
  );
};

export default HealthTimeline;
