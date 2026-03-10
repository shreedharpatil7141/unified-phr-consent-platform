import { useState, useEffect } from "react";
import { requestConsent, getSentRequests } from "../services/doctorService";

const ConsentRequests = () => {

  const [patientEmail, setPatientEmail] = useState("");
  const [categories, setCategories] = useState([]);
  const [dateFrom, setDateFrom] = useState("");
  const [dateTo, setDateTo] = useState("");
  const [duration, setDuration] = useState(0);
  const [requests, setRequests] = useState([]);

  const token = localStorage.getItem("token");

  useEffect(() => {
    loadRequests();
  }, []);

  useEffect(() => {
    calculateDuration();
  }, [dateFrom, dateTo]);

  const loadRequests = async () => {
    try {
      const data = await getSentRequests(token);
      console.log("CONSENT DATA:", data);
      setRequests(data || []);
    } catch (err) {
      console.error("Error loading consents:", err);
    }
  };

  const toggleCategory = (category) => {
    if (categories.includes(category)) {
      setCategories(categories.filter((c) => c !== category));
    } else {
      setCategories([...categories, category]);
    }
  };

  const calculateDuration = () => {
    if (!dateFrom || !dateTo) return;

    const from = new Date(dateFrom);
    const to = new Date(dateTo);

    const diff = (to - from) / (1000 * 60);

    if (diff > 0) {
      setDuration(Math.floor(diff));
    }
  };

  const sendRequest = async () => {

    if (!patientEmail || categories.length === 0) {
      alert("Please fill all fields");
      return;
    }

    try {

      await requestConsent(
        patientEmail,
        categories,
        dateFrom,
        dateTo,
        duration,
        token
      );

      alert("Consent request sent");

      setPatientEmail("");
      setCategories([]);
      setDateFrom("");
      setDateTo("");
      setDuration(0);

      loadRequests();

    } catch (err) {
      console.error(err);
      alert("Failed to send request");
    }

  };

  return (

    <div style={{ padding: "30px" }}>

      <h1 style={{ marginBottom: "25px" }}>Request Patient Data</h1>

      {/* Request Form */}
      <div style={{
        background: "#fff",
        padding: "25px",
        borderRadius: "10px",
        boxShadow: "0 2px 8px rgba(0,0,0,0.1)",
        marginBottom: "40px"
      }}>

        <div style={{ marginBottom: "20px" }}>
          <label><b>Patient Email</b></label>

          <input
            style={{ width: "100%", padding: "8px", marginTop: "6px" }}
            placeholder="patient@email.com"
            value={patientEmail}
            onChange={(e) => setPatientEmail(e.target.value)}
          />
        </div>

        {/* Categories */}
        <div style={{ marginBottom: "20px" }}>
          <label><b>Select Medical Categories</b></label>

          <div style={{ marginTop: "10px", display: "flex", flexWrap: "wrap", gap: "15px" }}>

            <label><input type="checkbox" onChange={() => toggleCategory("cardiology")} /> Cardiology</label>
            <label><input type="checkbox" onChange={() => toggleCategory("hematology")} /> Hematology</label>
            <label><input type="checkbox" onChange={() => toggleCategory("radiology")} /> Radiology</label>
            <label><input type="checkbox" onChange={() => toggleCategory("lab_reports")} /> Lab Reports</label>
            <label><input type="checkbox" onChange={() => toggleCategory("prescriptions")} /> Prescriptions</label>
            <label><input type="checkbox" onChange={() => toggleCategory("vitals")} /> Vitals</label>

          </div>
        </div>

        {/* Dates */}
        <div style={{ display: "flex", gap: "20px", marginBottom: "20px" }}>

          <div>
            <label><b>Date From</b></label>

            <input
              type="datetime-local"
              value={dateFrom}
              onChange={(e) => setDateFrom(e.target.value)}
            />
          </div>

          <div>
            <label><b>Date To</b></label>

            <input
              type="datetime-local"
              value={dateTo}
              onChange={(e) => setDateTo(e.target.value)}
            />
          </div>

        </div>

        {/* Duration */}
        <div style={{ marginBottom: "20px" }}>
          <label><b>Access Duration</b></label>
          <p>{duration} minutes (auto calculated)</p>
        </div>

        <button
          onClick={sendRequest}
          style={{
            background: "#2563eb",
            color: "white",
            padding: "10px 18px",
            border: "none",
            borderRadius: "6px",
            cursor: "pointer"
          }}
        >
          Send Consent Request
        </button>

      </div>

      {/* Sent Requests */}
      <h2 style={{ marginBottom: "20px" }}>Sent Requests</h2>

      <div style={{
        background: "#fff",
        padding: "20px",
        borderRadius: "10px",
        boxShadow: "0 2px 8px rgba(0,0,0,0.1)"
      }}>

        {requests?.length === 0 && (
          <p>No requests yet</p>
        )}

        {requests?.map((req) => (

          <div
            key={req.consent_id}
            style={{
              borderBottom: "1px solid #eee",
              padding: "12px 0"
            }}
          >

            <p><b>Patient:</b> {req.patient_id}</p>

            <p>
              <b>Status:</b>
              <span style={{
                marginLeft: "8px",
                color:
                  req.status === "approved"
                    ? "green"
                    : req.status === "rejected"
                    ? "red"
                    : "orange"
              }}>
                {req.status}
              </span>
            </p>

            <p>
              <b>Categories:</b> {req.categories?.join(", ") || "None"}
            </p>

            <p>
              <b>Consent ID:</b> {req.consent_id}
            </p>

          </div>

        ))}

      </div>

    </div>

  );

};

export default ConsentRequests;