const hostname = window.location.hostname || "127.0.0.1";
const protocol = window.location.protocol || "http:";
const fallback = `${protocol}//${hostname}:8000`;

export const API_BASE_URL =
  (process.env.REACT_APP_API_BASE_URL || "").trim() || fallback;
