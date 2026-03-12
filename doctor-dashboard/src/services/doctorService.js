import API from "./api";

//////////////////////////////////////////////////
// SEND CONSENT REQUEST
//////////////////////////////////////////////////

export const requestConsent = async (
  patientEmail,
  categories,
  dateFrom,
  dateTo,
  duration,
  token
) => {
  const response = await API.post(
    `/consent/request`,
    {
      patient_id: patientEmail,
      categories: categories,
      date_from: dateFrom,
      date_to: dateTo,
      access_duration_minutes: duration
    },
  );

  return response.data;
};

//////////////////////////////////////////////////
// GET SENT CONSENTS
//////////////////////////////////////////////////

export const getSentRequests = async (token) => {
  const response = await API.get(`/consent/sent`);

  return response.data;
};

////////////////////////////////////////////////////////
// NOTIFICATIONS
////////////////////////////////////////////////////////

export const getNotifications = async (token) => {
  const response = await API.get(`/notifications/my`);
  return response.data;
};

export const markNotificationRead = async (notificationId, token) => {
  const response = await API.post(`/notifications/mark-read/${notificationId}`, {});
  return response.data;
};

export const deleteNotification = async (notificationId, token) => {
  const response = await API.delete(`/notifications/${notificationId}`);
  return response.data;
};

export const deleteConsent = async (consentId, token) => {
  const response = await API.delete(`/consent/${consentId}`);
  return response.data;
};

export const deleteExpiredConsents = async (token) => {
  const response = await API.delete(`/consent/expired/cleanup`);
  return response.data;
};
