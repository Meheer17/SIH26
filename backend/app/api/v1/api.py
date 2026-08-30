from fastapi import APIRouter
from app.api.v1.endpoints import health, auth, admin, consent, ai, alerts, sos, apps

api_router = APIRouter()
api_router.include_router(health.router, tags=["Health Check"])
api_router.include_router(auth.router, prefix="/auth", tags=["Authentication"])
api_router.include_router(admin.router, prefix="/admin", tags=["Admin Role Management"])
api_router.include_router(consent.router, prefix="/consent", tags=["Consent Engine"])
api_router.include_router(ai.router, prefix="/ai", tags=["AI Agents Engine"])
api_router.include_router(alerts.router, prefix="/alerts", tags=["Multi-Tier Alert System"])
api_router.include_router(sos.router, prefix="/sos", tags=["SOS Emergency Module"])
api_router.include_router(apps.router, prefix="/apps", tags=["Domain Applications"])

