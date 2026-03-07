from fastapi import APIRouter, Depends
from app.core.dependencies import get_current_user

router = APIRouter(prefix="/user", tags=["User"])

@router.get("/me")
def get_me(current_user: dict = Depends(get_current_user)):
    return current_user