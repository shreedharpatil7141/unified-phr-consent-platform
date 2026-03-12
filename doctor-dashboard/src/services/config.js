const hostname = window.location.hostname || "127.0.0.1";
const protocol = window.location.protocol || "http:";

export const API_BASE_URL = `${protocol}//${hostname}:8000`;
