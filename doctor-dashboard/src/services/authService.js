import axios from "axios";

const API_URL = "http://127.0.0.1:8000";

export const loginUser = async (email, password) => {

  const formData = new URLSearchParams();
  formData.append("username", email);
  formData.append("password", password);

  const response = await axios.post(
    `${API_URL}/auth/login`,
    formData,
    {
      headers: {
        "Content-Type": "application/x-www-form-urlencoded"
      }
    }
  );

  return response.data;
};

export const registerUser = async (email, password, role) => {

  const response = await axios.post(`${API_URL}/auth/register`, {
    email,
    password,
    role
  });

  return response.data;
};