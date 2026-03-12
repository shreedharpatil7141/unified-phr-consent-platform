from fastapi import APIRouter, HTTPException, Depends
from fastapi.security import OAuth2PasswordRequestForm
from app.config.database import db
from app.schemas.user_schema import UserRegister
from app.core.security import hash_password, verify_password, create_access_token
from datetime import timedelta

router = APIRouter(prefix="/auth", tags=["Authentication"])

users_collection = db["users"]

@router.post("/register")
def register(user: UserRegister):
    # hygienic checks
    existing_user = users_collection.find_one({"email": user.email})
    if existing_user:
        raise HTTPException(status_code=400, detail="Email already registered")

    # bcrypt has a 72-byte limit; enforce and inform client
    if len(user.password.encode('utf-8')) > 72:
        raise HTTPException(
            status_code=400,
            detail="Password too long: must be 72 bytes or fewer"
        )

    try:
        hashed_pw = hash_password(user.password)
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

    user_data = {
        "name": user.name,
        "email": user.email,
        "password": hashed_pw,
        "role": user.role,
        "height_cm": user.height_cm,
        "weight_kg": user.weight_kg,
        "allergies": user.allergies,
        "blood_group": user.blood_group,
        "chronic_conditions": user.chronic_conditions,
        "emergency_contact": user.emergency_contact,
        "gender": user.gender,
        "age": user.age,
        "profile_complete": any(
            value is not None and value != ""
            for value in [
                user.height_cm,
                user.weight_kg,
                user.allergies,
                user.blood_group,
                user.chronic_conditions,
                user.emergency_contact,
                user.gender,
                user.age,
            ]
        ),
    }

    users_collection.insert_one(user_data)

    return {"message": "User registered successfully"}


@router.post("/login")
def login(form_data: OAuth2PasswordRequestForm = Depends()):
    db_user = users_collection.find_one({"email": form_data.username})

    if not db_user:
        raise HTTPException(status_code=400, detail="Invalid credentials")

    if not verify_password(form_data.password, db_user["password"]):
        raise HTTPException(status_code=400, detail="Invalid credentials")

    access_token = create_access_token(
        data={"sub": db_user["email"], "role": db_user["role"]},
        expires_delta=timedelta(minutes=60)
    )

    return {
        "access_token": access_token,
        "token_type": "bearer",
        "email": db_user["email"],
        "name": db_user.get("name", ""),
        "profile_complete": db_user.get("profile_complete", False),
    }
