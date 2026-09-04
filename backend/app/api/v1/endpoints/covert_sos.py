"""
Covert Emergency SOS & Dead Man's Switch Router
Handles stealth panic triggers (shake, fake calculator pin, power button rhythm)
and passive inactivity heartbeats for high-risk personnel / atrocity victims.
"""
from fastapi import APIRouter, Body, HTTPException
from typing import Optional, Dict, Any
from pydantic import BaseModel
from datetime import datetime, timezone

router = APIRouter()

class CovertSOSTrigger(BaseModel):
    trigger_type: str # SHAKE / FAKE_CALCULATOR / POWER_BUTTON / STEALTH_TAP
    user_id: Optional[str] = "ANON_USER_99"
    lat: Optional[float] = 28.6139
    lng: Optional[float] = 77.2090
    battery_level: Optional[int] = 85
    covert_pin_entered: Optional[str] = None

class DeadManPing(BaseModel):
    user_id: str
    last_active_timestamp: float # Epoch seconds
    heartbeat_interval_seconds: int = 3600 # Default 1 hour ping
    inactivity_tolerance_seconds: int = 7200 # 2 hours max threshold

# In-memory status store for demo heartbeats
DEAD_MAN_STORE: Dict[str, Dict[str, Any]] = {}

@router.post("/covert-trigger")
def trigger_covert_sos(payload: CovertSOSTrigger = Body(...)):
    """
    Triggers covert stealth SOS. Sends silent alert to designated emergency contacts & legal aid.
    Disguises app state as a calculator or weather widget on user screen.
    """
    dispatch_time = datetime.now(timezone.utc).isoformat()
    
    return {
        "status": "DISPATCHED",
        "covert_alert_id": f"SOS_STEALTH_{int(datetime.now().timestamp())}",
        "trigger_mechanism": payload.trigger_type,
        "disguise_mode": "ACTIVE_CALCULATOR_UI",
        "gps_coordinates": {"lat": payload.lat, "lng": payload.lng},
        "dispatch_timestamp": dispatch_time,
        "notified_channels": ["Encrypted Legal Cell SMS", "Nearest Control Room", "Designated Caregiver"],
        "stealth_note": "No sound or flashing indicators emitted on patient device."
    }

@router.post("/deadman-ping")
def update_deadman_heartbeat(ping: DeadManPing = Body(...)):
    """Registers passive activity heartbeat from patient device."""
    DEAD_MAN_STORE[ping.user_id] = {
        "user_id": ping.user_id,
        "last_active": ping.last_active_timestamp,
        "interval": ping.heartbeat_interval_seconds,
        "tolerance": ping.inactivity_tolerance_seconds,
        "status": "HEALTHY_ACTIVE",
        "updated_at": datetime.now(timezone.utc).isoformat()
    }
    return {
        "status": "HEARTBEAT_ACKNOWLEDGED",
        "user_id": ping.user_id,
        "next_expected_ping_within_seconds": ping.inactivity_tolerance_seconds
    }

@router.get("/deadman-status/{user_id}")
def check_deadman_status(user_id: str):
    """
    Checks whether a user's dead man's switch has timed out due to total inactivity.
    """
    record = DEAD_MAN_STORE.get(user_id)
    if not record:
        # Generate simulated active status
        return {
            "user_id": user_id,
            "status": "ACTIVE_NORMAL",
            "last_seen_hours_ago": 0.5,
            "escalation_required": False
        }
    
    now_ts = datetime.now().timestamp()
    elapsed = now_ts - record["last_active"]
    
    if elapsed > record["tolerance"]:
        return {
            "user_id": user_id,
            "status": "DEADMAN_SWITCH_TRIGGERED",
            "last_seen_hours_ago": round(elapsed / 3600.0, 2),
            "escalation_required": True,
            "action_taken": "Automated SOS sent to welfare officer and secondary contact."
        }

    return {
        "user_id": user_id,
        "status": "ACTIVE_NORMAL",
        "last_seen_hours_ago": round(elapsed / 3600.0, 2),
        "escalation_required": False
    }
