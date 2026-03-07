from pydantic import BaseModel, EmailStr

class UserRegister(BaseModel):
    name: str
    email: EmailStr
    password: str
    role: str  # "patient" or "doctor"

class UserLogin(BaseModel):
    email: EmailStr
    password: str