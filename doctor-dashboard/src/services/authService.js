import axios from "axios";
import { API_BASE_URL } from "./config";

const API_URL = API_BASE_URL;

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
