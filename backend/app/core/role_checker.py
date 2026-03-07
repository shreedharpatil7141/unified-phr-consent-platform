from fastapi import Depends, HTTPException, status
from app.core.dependencies import get_current_user

def require_role(required_role: str):
    def role_dependency(current_user: dict = Depends(get_current_user)):
        if current_user["role"] != required_role:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Access denied: insufficient permissions"
            )
        return current_user
    return role_dependency