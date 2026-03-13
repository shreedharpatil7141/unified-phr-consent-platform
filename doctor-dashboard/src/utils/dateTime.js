const HAS_TIMEZONE_REGEX = /(Z|[+-]\d{2}:\d{2})$/i;
const ISO_WITHOUT_TIMEZONE_REGEX =
  /^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(?:\.\d+)?$/;

export const parseServerDate = (value) => {
  if (value == null || value === "") return new Date(NaN);
  if (value instanceof Date) return value;
  if (typeof value === "number") return new Date(value);

  const raw = String(value).trim();
  if (!raw) return new Date(NaN);

  if (ISO_WITHOUT_TIMEZONE_REGEX.test(raw) && !HAS_TIMEZONE_REGEX.test(raw)) {
    return new Date(`${raw}Z`);
  }

  return new Date(raw);
};

export const toTimestamp = (value) => parseServerDate(value).getTime();

export const formatServerDateTime = (value, options) => {
  const date = parseServerDate(value);
  if (Number.isNaN(date.getTime())) return "Unknown";
  return date.toLocaleString([], options);
};

export const formatServerDate = (value, options) => {
  const date = parseServerDate(value);
  if (Number.isNaN(date.getTime())) return "N/A";
  return date.toLocaleDateString([], options);
};
