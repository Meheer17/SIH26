from fastapi import APIRouter
from app.api.v1.endpoints import health, auth, admin, consent

api_router = APIRouter()
api_router.include_router(health.router, tags=["Health Check"])
api_router.include_router(auth.router, prefix="/auth", tags=["Authentication"])
api_router.include_router(admin.router, prefix="/admin", tags=["Admin Role Management"])
api_router.include_router(consent.router, prefix="/consent", tags=["Consent Engine"])

