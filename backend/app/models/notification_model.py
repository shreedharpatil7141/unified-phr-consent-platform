from pydantic import BaseModel
from datetime import datetime

class Notification(BaseModel):
    user_id: str
    message: str
    created_at: datetime | None = None
    read: bool = False
