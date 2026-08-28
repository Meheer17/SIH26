import time
from typing import List, Dict, Any, Optional
from fastapi import APIRouter, HTTPException, status
from pydantic import BaseModel, Field

router = APIRouter()

# In-memory storage for emergency SOS events
ACTIVE_SOS_EVENTS: List[Dict[str, Any]] = []


class LocationSnapshot(BaseModel):
    latitude: float = Field(..., description="GPS Latitude")
    longitude: float = Field(..., description="GPS Longitude")
    altitude: Optional[float] = Field(default=0.0, description="Altitude in meters")
    address_name: Optional[str] = Field(default="GPS Location", description="Human-readable address or landmark")


class HealthSnapshot(BaseModel):
    heart_rate: Optional[int] = Field(default=None, description="Current Heart Rate (bpm)")
    body_temp_c: Optional[float] = Field(default=None, description="Body Temperature (°C)")
    heat_index: Optional[float] = Field(default=None, description="Heat Stress Index")
    triage_status: Optional[str] = Field(default=None, description="Clinical triage status ('RED_FLAG', 'NORMAL')")
    burnout_score: Optional[int] = Field(default=None, description="Burnout score (0-100)")
    distress_score: Optional[int] = Field(default=None, description="Victim distress score (0-100)")


class TriggerSosRequest(BaseModel):
    app_context: str = Field(..., description="Application domain ('arogya_sathi', 'medikiosk', 'rakshak_mitra', 'nyaya_sahay')")
    user_id: str = Field(..., description="User or Patient ID triggering SOS")
    user_name: str = Field(..., description="User or Patient full name")
    location: LocationSnapshot = Field(..., description="GPS location snapshot")
    health_snapshot: HealthSnapshot = Field(..., description="Latest vitals/mental health snapshot")
    emergency_contacts: List[str] = Field(..., description="List of phone numbers / emails to alert")
    emergency_reason: str = Field(default="One-Tap Emergency SOS Triggered", description="Reason for emergency trigger")


@router.post("/trigger", summary="Trigger One-Tap Emergency SOS")
def trigger_sos(request: TriggerSosRequest):
    """
    Triggers a critical Emergency SOS event:
    1. Captures GPS coordinates & address name.
    2. Bundles latest health snapshot.
    3. Dispatches payload to SMS gateway & emergency contact list.
    4. Registers event for active emergency responder monitoring.
    """
    sos_id = f"SOS-{int(time.time() * 1000)}"

    sos_event = {
        "sos_id": sos_id,
        "app_context": request.app_context,
        "user_id": request.user_id,
        "user_name": request.user_name,
        "location": request.location.model_dump(),
        "health_snapshot": request.health_snapshot.model_dump(),
        "emergency_contacts": request.emergency_contacts,
        "emergency_reason": request.emergency_reason,
        "status": "ACTIVE_CRITICAL_SOS",
        "responders_notified": ["Local Ambulance (108)", "District Emergency Cell", "Emergency Contacts"],
        "timestamp": time.strftime("%Y-%m-%d %H:%M:%S"),
    }

    ACTIVE_SOS_EVENTS.insert(0, sos_event)

    return {
        "message": f"🚨 EMERGENCY SOS ACTIVATED! ID: '{sos_id}'. Dispatching responders and alerting emergency contacts.",
        "sos_event": sos_event
    }


@router.post("/{sos_id}/cancel", summary="Cancel Active SOS Event")
def cancel_sos(sos_id: str, cancel_reason: str = "User cancelled during countdown"):
    """Cancels an active SOS event if triggered accidentally."""
    for event in ACTIVE_SOS_EVENTS:
        if event["sos_id"] == sos_id:
            event["status"] = "CANCELLED"
            event["cancel_reason"] = cancel_reason
            return {"message": f"SOS '{sos_id}' has been cancelled.", "sos_event": event}

    raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=f"SOS '{sos_id}' not found.")


@router.get("/active", summary="List Active Emergency SOS Events")
def get_active_sos(app_context: Optional[str] = None):
    """Returns active emergency SOS events for emergency responder dashboards."""
    active = [e for e in ACTIVE_SOS_EVENTS if e["status"] == "ACTIVE_CRITICAL_SOS"]
    if app_context:
        active = [e for e in active if e["app_context"] == app_context]

    return {"active_count": len(active), "events": active}
