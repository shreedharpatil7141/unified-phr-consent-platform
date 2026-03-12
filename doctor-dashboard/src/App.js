import React from "react";
import { BrowserRouter as Router, Routes, Route, Navigate } from "react-router-dom";

import Layout from "./components/Layout";
import Dashboard from "./pages/Dashboard";
import PatientDashboard from "./pages/PatientDashboard";
import Patients from "./pages/Patients";
import ConsentRequests from "./pages/ConsentRequests";
import Notifications from "./pages/Notifications";

/* NEW AUTH PAGES */
import Login from "./pages/Login";
import Register from "./pages/Register";

function App() {
  return (

    <Router>

      <Routes>

        {/* Redirect root to login */}
        <Route path="/" element={<Navigate to="/login" />} />

        {/* AUTH ROUTES */}
        <Route path="/login" element={<Login />} />
        <Route path="/register" element={<Register />} />

        {/* MAIN DASHBOARD LAYOUT */}
        <Route
          path="/dashboard"
          element={
            <Layout>
              <Dashboard />
            </Layout>
          }
        />

        {/* PATIENT HEALTH DASHBOARD */}
        <Route
          path="/patient/:consentId"
          element={
            <Layout>
              <PatientDashboard />
            </Layout>
          }
        />

        {/* PATIENTS LIST */}
        <Route
          path="/patients"
          element={
            <Layout>
              <Patients />
            </Layout>
          }
        />

        {/* CONSENT REQUESTS */}
        <Route
          path="/consents"
          element={
            <Layout>
              <ConsentRequests />
            </Layout>
          }
        />

        {/* NOTIFICATIONS */}
        <Route
          path="/notifications"
          element={
            <Layout>
              <Notifications />
            </Layout>
          }
        />

      </Routes>

    </Router>

  );
}

export default App;
