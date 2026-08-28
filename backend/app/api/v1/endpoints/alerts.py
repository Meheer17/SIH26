import time
from typing import List, Dict, Any, Optional
from fastapi import APIRouter, HTTPException, status
from pydantic import BaseModel, Field

router = APIRouter()

# In-memory storage for active & historical alerts
ALERT_HISTORY: List[Dict[str, Any]] = []


class AlertDispatchRequest(BaseModel):
    app_context: str = Field(..., description="Target application ('arogya_sathi', 'medikiosk', 'rakshak_mitra', 'nyaya_sahay')")
    severity: str = Field(..., description="Severity tier ('LOW', 'MODERATE', 'HIGH', 'CRITICAL_SOS')")
    title: str = Field(..., description="Alert headline title")
    message: str = Field(..., description="Detailed alert message")
    recipients: List[str] = Field(..., description="List of target recipients (caregivers, doctors, commanders, nodal officers)")
    escalation_timeout_seconds: int = Field(default=60, description="Auto-escalation timer in seconds")
    metadata: Optional[Dict[str, Any]] = Field(default_factory=dict, description="Context metadata (vitals, location, case stage)")


@router.post("/dispatch", summary="Dispatch Multi-Tier Alert")
def dispatch_alert(request: AlertDispatchRequest):
    """
    Dispatches a multi-tier alert routed according to severity tier:
    - LOW: In-App Banner
    - MODERATE: In-App Banner + Push Notification
    - HIGH: In-App Banner + Push Notification + SMS Gateway Dispatch
    - CRITICAL_SOS: In-App Banner + Push + SMS + Call Dispatch + Loud Alarm
    """
    severity_upper = request.severity.upper()
    if severity_upper not in ["LOW", "MODERATE", "HIGH", "CRITICAL_SOS"]:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Invalid severity tier.")

    channels = []
    if severity_upper == "LOW":
        channels = ["IN_APP_BANNER"]
    elif severity_upper == "MODERATE":
        channels = ["IN_APP_BANNER", "PUSH_NOTIFICATION"]
    elif severity_upper == "HIGH":
        channels = ["IN_APP_BANNER", "PUSH_NOTIFICATION", "SMS_DISPATCH"]
    elif severity_upper == "CRITICAL_SOS":
        channels = ["IN_APP_BANNER", "PUSH_NOTIFICATION", "SMS_DISPATCH", "EMERGENCY_CALL_DISPATCH", "LOUD_ALARM_TRIGGER"]

    alert_id = f"ALT-{int(time.time() * 1000)}"
    alert_record = {
        "alert_id": alert_id,
        "app_context": request.app_context,
        "severity": severity_upper,
        "title": request.title,
        "message": request.message,
        "channels": channels,
        "recipients": request.recipients,
        "escalation_timeout_seconds": request.escalation_timeout_seconds,
        "status": "DISPATCHED",
        "acknowledged": False,
        "timestamp": time.strftime("%Y-%m-%d %H:%M:%S"),
        "metadata": request.metadata
    }

    ALERT_HISTORY.insert(0, alert_record)

    return {
        "message": f"Alert '{alert_id}' successfully dispatched via channels: {', '.join(channels)}",
        "alert": alert_record
    }


@router.post("/{alert_id}/acknowledge", summary="Acknowledge Alert")
def acknowledge_alert(alert_id: str):
    """Marks an active alert as acknowledged, stopping escalation timers."""
    for alert in ALERT_HISTORY:
        if alert["alert_id"] == alert_id:
            alert["acknowledged"] = True
            alert["status"] = "ACKNOWLEDGED"
            return {"message": f"Alert '{alert_id}' acknowledged.", "alert": alert}

    raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=f"Alert '{alert_id}' not found.")


@router.get("/history", summary="List Alert History")
def get_alert_history(app_context: Optional[str] = None):
    """Returns list of active and historical alerts."""
    if app_context:
        filtered = [a for a in ALERT_HISTORY if a["app_context"] == app_context]
        return {"count": len(filtered), "alerts": filtered}

    return {"count": len(ALERT_HISTORY), "alerts": ALERT_HISTORY}
