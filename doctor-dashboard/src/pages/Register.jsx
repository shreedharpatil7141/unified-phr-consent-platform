import React,{useState} from "react";
import { registerUser } from "../services/authService";
import { useNavigate,Link } from "react-router-dom";
import "../styles/auth.css";

const Register = () => {

  const navigate = useNavigate();

  const [name,setName] = useState("");
  const [email,setEmail] = useState("");
  const [password,setPassword] = useState("");

  const handleRegister = async () => {
    if (!name.trim() || !email.trim() || !password.trim()) {
      alert("Name, email, and password are required");
      return;
    }

    try{

      await registerUser(name.trim(),email.trim(),password,"doctor");

      alert("Account created");

      navigate("/login");

    }catch(err){

      alert(err?.response?.data?.detail || "Registration failed");

    }

  };

  return(

    <div className="auth-container">

      <div className="auth-card">

        <h2>Doctor Registration</h2>

        <input
          placeholder="Full name"
          value={name}
          onChange={(e)=>setName(e.target.value)}
        />

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

        <button onClick={handleRegister}>
          Register
        </button>

        <p>
          Already have an account?  
          <Link to="/login"> Login</Link>
        </p>

      </div>

    </div>

  );

};

export default Register;
