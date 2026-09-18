from fastapi import APIRouter
from app.api.v1.endpoints import health, auth, admin, consent, ai, alerts, sos, apps, cin, screening, clinical, epidemic, covert_sos, mind_family, nyaya_manas

api_router = APIRouter()
api_router.include_router(health.router, tags=["Health Check"])
api_router.include_router(auth.router, prefix="/auth", tags=["Authentication"])
api_router.include_router(admin.router, prefix="/admin", tags=["Admin Role Management"])
api_router.include_router(consent.router, prefix="/consent", tags=["Consent Engine"])
api_router.include_router(ai.router, prefix="/ai", tags=["AI Agents Engine"])
api_router.include_router(alerts.router, prefix="/alerts", tags=["Multi-Tier Alert System"])
api_router.include_router(sos.router, prefix="/sos", tags=["SOS Emergency Module"])
api_router.include_router(apps.router, prefix="/apps", tags=["Domain Applications"])
api_router.include_router(nyaya_manas.router, prefix="/nyaya-manas", tags=["Nyaya-Manas Mental Health & Distress System"])
api_router.include_router(nyaya_manas.router, prefix="/apps/nyaya-manas", tags=["Nyaya-Manas Mental Health & Distress System"])
api_router.include_router(cin.router, prefix="/cin", tags=["Community Immunity Network (CIN)"])
api_router.include_router(screening.router, prefix="/screening", tags=["Non-Invasive Diagnostic Screening"])
api_router.include_router(clinical.router, prefix="/clinical", tags=["Clinical Engine & Dual-Path Prescriptions"])
api_router.include_router(epidemic.router, prefix="/epidemic", tags=["Epidemic Heatmap & DBSCAN Clustering"])
api_router.include_router(covert_sos.router, prefix="/covert-sos", tags=["Covert Stealth SOS & Dead Man Switch"])
api_router.include_router(mind_family.router, prefix="/mind-family", tags=["Cultural AI Counselor & Family Health Graph"])
api_router.include_router(mind_family.router, prefix="/mind", tags=["Cultural AI Counselor & Family Health Graph"])



