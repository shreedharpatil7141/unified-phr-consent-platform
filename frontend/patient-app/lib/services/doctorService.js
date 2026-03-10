import axios from "axios";

const API_BASE = "http://localhost:8000";

export const requestConsent = async (
  patientEmail,
  categories,
  dateFrom,
  dateTo,
  duration,
  token
) => {
  const response = await axios.post(
    `${API_BASE}/consent/request`,
    {
      patient_id: patientEmail,
      categories: categories,
      date_from: dateFrom,
      date_to: dateTo,
      access_duration_minutes: duration
    },
    {
      headers: {
        Authorization: `Bearer ${token}`,
        "Content-Type": "application/json"
      }
    }
  );

  return response.data;
};

export const getSentRequests = async (token) => {
  const response = await axios.get(
    `${API_BASE}/consent/sent`,
    {
      headers: {
        Authorization: `Bearer ${token}`
      }
    }
  );

  return response.data;
};