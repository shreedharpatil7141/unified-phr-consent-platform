from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.routes.auth_routes import router as auth_router
from app.routes.user_routes import router as user_router 
from app.routes.consent_routes import router as consent_router
from app.routes.data_routes import router as data_router
from app.routes.health_routes import router as health_router
from app.routes.analytics_routes import router as analytics_router
from app.routes.alert_routes import router as alert_router

app = FastAPI()

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