import time
from typing import Dict, Any
from fastapi import APIRouter
from app.core.config import settings

router = APIRouter()
START_TIME = time.time()


@router.get("/health", response_model=Dict[str, Any])
def health_check() -> Dict[str, Any]:
    """
    Health check endpoint for frontend and mobile apps to verify backend connectivity.
    """
    uptime_seconds = round(time.time() - START_TIME, 2)
    return {
        "status": "online",
        "service": settings.PROJECT_NAME,
        "version": settings.VERSION,
        "uptime_seconds": uptime_seconds,
        "timestamp": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime())
    }
