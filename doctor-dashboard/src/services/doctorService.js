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
  accessFrom,
  accessTo,
  token
) => {
  const toIso = (value) => (value ? new Date(value).toISOString() : null);

  const response = await API.post(
    `/consent/request`,
    {
      patient_id: patientEmail,
      categories: categories,
      date_from: toIso(dateFrom),
      date_to: toIso(dateTo),
      access_duration_minutes: duration,
      access_from: toIso(accessFrom),
      access_to: toIso(accessTo),
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

export const getMyAccessAudit = async (daysBack = 30) => {
  const response = await API.get(`/consent/audit-logs/my-accesses`, {
    params: { days_back: daysBack },
  });
  return response.data;
};

////////////////////////////////////////////////////////
// APPOINTMENTS
////////////////////////////////////////////////////////

export const getDoctorAppointments = async () => {
  const response = await API.get(`/appointments/doctor`);
  return response.data;
};

export const confirmAppointment = async (
  appointmentId,
  scheduledFor,
  endsAt,
  confirmationNote = ""
) => {
  const response = await API.post(`/appointments/${appointmentId}/confirm`, {
    scheduled_for: scheduledFor,
    ends_at: endsAt,
    confirmation_note: confirmationNote,
  });
  return response.data;
};

export const completeAppointment = async (appointmentId, note = "") => {
  const response = await API.post(`/appointments/${appointmentId}/complete`, {
    note,
  });
  return response.data;
};

export const cancelAppointment = async (appointmentId, note = "") => {
  const response = await API.post(`/appointments/${appointmentId}/cancel`, {
    note,
  });
  return response.data;
};

export const deleteAppointment = async (appointmentId) => {
  const response = await API.delete(`/appointments/${appointmentId}`);
  return response.data;
};
