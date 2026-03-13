import React, { useState } from "react";
import { loginUser } from "../services/authService";
import { useNavigate, Link } from "react-router-dom";
import "../styles/auth.css";

const Login = () => {

  const navigate = useNavigate();

  const [email,setEmail] = useState("");
  const [password,setPassword] = useState("");

  const handleLogin = async () => {

    try{

      const data = await loginUser(email,password);

      localStorage.setItem("token",data.access_token);
      localStorage.setItem("name", data.name || "");
      localStorage.setItem("email", data.email || "");

      navigate("/dashboard");

    }catch(err){

      alert("Invalid credentials");

    }

  };

  return(

    <div className="auth-container">

      <div className="auth-card">

        <h2>Doctor Login</h2>

        <input
          placeholder="Email"
          value={email}
          onChange={(e)=>setEmail(e.target.value)}
        />

        <input
          type="password"
          placeholder="Password"
          value={password}
          onChange={(e)=>setPassword(e.target.value)}
        />

        <button onClick={handleLogin}>
          Login
        </button>

        <p>
          Don't have an account?  
          <Link to="/register"> Register</Link>
        </p>

      </div>

    </div>

  );

};

export default Login;
