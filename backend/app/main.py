from pathlib import Path

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles

from app.routes.auth_routes import router as auth_router
from app.routes.user_routes import router as user_router 
from app.routes.consent_routes import router as consent_router
from app.routes.data_routes import router as data_router
from app.routes.health_routes import router as health_router
from app.routes.analytics_routes import router as analytics_router
from app.routes.alert_routes import router as alert_router
from app.routes.notification_routes import router as notification_router
from app.routes.ai_routes import router as ai_router
from app.routes.admin_routes import router as admin_router
from app.routes.family_routes import router as family_router
from app.routes.appointment_routes import router as appointment_router

app = FastAPI()

uploads_dir = Path("uploads")
uploads_dir.mkdir(exist_ok=True)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(auth_router)
app.include_router(user_router)
app.include_router(consent_router)
app.include_router(data_router)
app.include_router(health_router)
app.include_router(analytics_router)
app.include_router(alert_router)
app.include_router(notification_router)
app.include_router(ai_router)
app.include_router(admin_router)
app.include_router(family_router)
app.include_router(appointment_router)
app.mount("/uploads", StaticFiles(directory=str(uploads_dir)), name="uploads")
