import React from "react";
import { BrowserRouter as Router, Routes, Route, Navigate } from "react-router-dom";

import Layout from "./components/Layout";
import Dashboard from "./pages/Dashboard";
import PatientDashboard from "./pages/PatientDashboard";
import Patients from "./pages/Patients";
import ConsentRequests from "./pages/ConsentRequests";
import Timeline from "./pages/Timeline";

function App() {
  return (

    <Router>

      <Layout>

        <Routes>

          <Route path="/" element={<Navigate to="/dashboard" />} />

          <Route path="/dashboard" element={<Dashboard />} />

          <Route path="/patient/:consentId" element={<PatientDashboard />} />

          <Route path="/patients" element={<Patients />} />

          <Route path="/consents" element={<ConsentRequests />} />

          <Route path="/timeline" element={<Timeline />} />

        </Routes>

      </Layout>

    </Router>

  );
}

export default App;