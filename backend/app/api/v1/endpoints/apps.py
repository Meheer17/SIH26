import time
from datetime import datetime, timezone
from typing import List, Dict, Any, Optional
from fastapi import APIRouter, HTTPException, status, Depends
from pydantic import BaseModel, Field

from app.db.database import get_database, db_manager
from app.api.deps import get_current_user
from app.services.ai.tools import (
    calculate_heat_stress_tool,
    flag_clinical_redflags_tool,
    predict_burnout_risk_tool,
    recommend_welfare_action_tool,
    assess_victim_distress_tool,
    trigger_escalation_workflow_tool
)

router = APIRouter()

# --- ArogyaSathi Pydantic Models & Schemas ---

class VitalRecordRequest(BaseModel):
    heart_rate: float = Field(..., description="Heart rate in bpm")
    spo2: float = Field(..., description="Blood oxygen saturation percentage")
    body_temp_c: float = Field(..., description="Body temperature in Celsius")
    env_temp_c: float = Field(..., description="Environmental temperature in Celsius")
    humidity_percent: float = Field(..., description="Environmental relative humidity percentage")
    activity_level: str = Field(..., description="Activity level ('resting', 'moderate', 'strenuous')")
    time_since_water_mins: int = Field(..., description="Time since last hydration in minutes")

# --- MediKiosk Pydantic Models & Schemas ---

class ClinicalIntakeRequest(BaseModel):
    symptoms: List[str] = Field(..., description="List of patient symptoms")
    duration: str = Field(..., description="Duration of symptoms")
    severity_rating: int = Field(..., description="Severity scale from 1 to 10")
    chief_complaint: str = Field(..., description="Structured chief complaint")
    history_present_illness: str = Field(..., description="Detailed symptom timeline")
    review_systems: str = Field(..., description="Physical symptoms review details")
    ayush_mode: bool = Field(default=False, description="Enable Ayurvedic Ahara-Vihara intake details")

# --- RakshakMitra Pydantic Models & Schemas ---

class BurnoutAssessmentRequest(BaseModel):
    deployment_days: int = Field(..., description="Days deployed in location")
    leave_gap_ratio: float = Field(..., description="Leave usage ratio")
    duty_hours_per_week: float = Field(..., description="Weekly duty workload in hours")
    assessment_score: int = Field(..., description="PHQ-9/GAD-7 clinical assessment score")
    voice_journal_text: Optional[str] = Field(default=None, description="Transcribed voice journal entry text")

# --- NyayaSahay Pydantic Models & Schemas ---

class DistressCheckinRequest(BaseModel):
    sentiment_score: float = Field(..., description="Sentiment indicator from checkin chat analysis")
    case_stage: str = Field(..., description="Legal milestone stage ('fir', 'chargesheet', 'trial', 'adjournment')")
    days_since_incident: int = Field(..., description="Days elapsed since the incident")
    recent_checkin_responses: str = Field(..., description="Text summary of response answers")


# =========================================================================
# 1. AROGYASATHI ENDPOINTS (Vitals, Weather, AQI & SOS calculations)
# =========================================================================

@router.post("/arogya/vitals", summary="Record vitals and compute Heat Stress score")
async def record_vitals(req: VitalRecordRequest, current_user: dict = Depends(get_current_user)):
    db = get_database()
    
    # Calculate Heat Stress using base domain tool
    stress_calc = calculate_heat_stress_tool(
        body_temp_c=req.body_temp_c,
        env_temp_c=req.env_temp_c,
        humidity_percent=req.humidity_percent,
        activity_level=req.activity_level,
        time_since_water_mins=req.time_since_water_mins
    )
    
    record = {
        "id": f"VIT-{int(time.time() * 1000)}",
        "user_id": current_user["id"],
        "heart_rate": req.heart_rate,
        "spo2": req.spo2,
        "body_temp_c": req.body_temp_c,
        "env_temp_c": req.env_temp_c,
        "humidity_percent": req.humidity_percent,
        "activity_level": req.activity_level,
        "time_since_water_mins": req.time_since_water_mins,
        "heat_stress_score": stress_calc["heat_index"],
        "dehydration_risk_percent": stress_calc["dehydration_risk_percent"],
        "severity": stress_calc["severity"],
        "recommendations": stress_calc["recommendation"],
        "created_at": datetime.now(timezone.utc).isoformat()
    }
    
    if db is not None:
        await db.arogya_vitals.insert_one(record)
    else:
        db_manager._in_memory_collections["arogya_vitals"].append(record)
        
    return record


@router.get("/arogya/vitals", summary="Fetch vitals history")
async def get_vitals_history(current_user: dict = Depends(get_current_user)):
    db = get_database()
    user_id = current_user["id"]
    
    if db is not None:
        cursor = db.arogya_vitals.find({"user_id": user_id}).sort("created_at", -1)
        history = await cursor.to_list(length=100)
    else:
        history = [v for v in db_manager._in_memory_collections["arogya_vitals"] if v["user_id"] == user_id]
        history.sort(key=lambda x: x["created_at"], reverse=True)
        
    # Formatting helper to convert ObjectIds to string
    for v in history:
        if "_id" in v:
            v["_id"] = str(v["_id"])
            
    return history


# =========================================================================
# 2. MEDIKIOSK ENDPOINTS (OPD Intake & Physician Summaries)
# =========================================================================

@router.post("/medikiosk/intake", summary="Submit OPD clinical intake")
async def submit_intake(req: ClinicalIntakeRequest, current_user: dict = Depends(get_current_user)):
    db = get_database()
    
    # Run clinical redflags triaging tool
    triage = flag_clinical_redflags_tool(
        symptoms=req.symptoms,
        duration=req.duration,
        severity_rating=req.severity_rating
    )
    
    # Simple summary generator based on input parameters
    symptoms_list = ", ".join(req.symptoms)
    summary_text = (
        f"Patient presented with chief complaints of: {req.chief_complaint}. "
        f"Symptoms include: {symptoms_list} persisting for {req.duration}. "
        f"Reported severity is {req.severity_rating}/10. "
        f"History of Present Illness (HPI): {req.history_present_illness}. "
        f"Review of Systems (ROS): {req.review_systems}."
    )
    if req.ayush_mode:
        summary_text += " Ayurvedic Ahara-Vihara context was recorded and logged."

    record = {
        "id": f"INT-{int(time.time() * 1000)}",
        "user_id": current_user["id"],
        "patient_name": current_user["full_name"],
        "symptoms": req.symptoms,
        "duration": req.duration,
        "severity_rating": req.severity_rating,
        "chief_complaint": req.chief_complaint,
        "history_present_illness": req.history_present_illness,
        "review_systems": req.review_systems,
        "triage_level": triage["triage_status"],
        "summary": summary_text,
        "ayush_mode": req.ayush_mode,
        "created_at": datetime.now(timezone.utc).isoformat()
    }
    
    if db is not None:
        await db.medikiosk_intakes.insert_one(record)
    else:
        db_manager._in_memory_collections["medikiosk_intakes"].append(record)
        
    return record


@router.get("/medikiosk/intake", summary="List historical OPD records")
async def get_intakes(current_user: dict = Depends(get_current_user)):
    db = get_database()
    user_roles = current_user.get("mapped_roles", [current_user["primary_role"]])
    
    # Doctor/Welfare/System Admin roles can view all intakes, Patients can only see their own
    is_doctor_or_admin = any(role in ["PHYSICIAN", "SYSTEM_ADMIN"] for role in user_roles)
    
    if db is not None:
        if is_doctor_or_admin:
            cursor = db.medikiosk_intakes.find({}).sort("created_at", -1)
        else:
            cursor = db.medikiosk_intakes.find({"user_id": current_user["id"]}).sort("created_at", -1)
        history = await cursor.to_list(length=100)
    else:
        if is_doctor_or_admin:
            history = list(db_manager._in_memory_collections["medikiosk_intakes"])
        else:
            history = [i for i in db_manager._in_memory_collections["medikiosk_intakes"] if i["user_id"] == current_user["id"]]
        history.sort(key=lambda x: x["created_at"], reverse=True)
        
    for i in history:
        if "_id" in i:
            i["_id"] = str(i["_id"])
            
    return history


# =========================================================================
# 3. RAKSHAKMITRA ENDPOINTS (Burnout Calculation & Commander Heatmap)
# =========================================================================

@router.post("/rakshak/burnout", summary="Submit soldier assessment and compute burnout index")
async def record_burnout(req: BurnoutAssessmentRequest, current_user: dict = Depends(get_current_user)):
    db = get_database()
    
    # Calculate burnout score via tool
    burnout = predict_burnout_risk_tool(
        deployment_days=req.deployment_days,
        leave_gap_ratio=req.leave_gap_ratio,
        duty_hours_per_week=req.duty_hours_per_week,
        assessment_score=req.assessment_score
    )
    
    # Fetch commander intervention advice
    welfare = recommend_welfare_action_tool(
        burnout_score=burnout["burnout_score"],
        contributing_factors=burnout["contributing_factors"]
    )
    
    record = {
        "id": f"BRN-{int(time.time() * 1000)}",
        "user_id": current_user["id"],
        "unit": "15th Rajput Regiment", # Simulating military unit grouping
        "deployment_days": req.deployment_days,
        "leave_gap_ratio": req.leave_gap_ratio,
        "duty_hours_per_week": req.duty_hours_per_week,
        "assessment_score": req.assessment_score,
        "burnout_score": burnout["burnout_score"],
        "risk_tier": burnout["risk_tier"],
        "contributing_factors": burnout["contributing_factors"],
        "recommended_actions": welfare["recommended_actions"],
        "voice_journal_text": req.voice_journal_text,
        "created_at": datetime.now(timezone.utc).isoformat()
    }
    
    if db is not None:
        await db.rakshak_burnouts.insert_one(record)
    else:
        db_manager._in_memory_collections["rakshak_burnouts"].append(record)
        
    return record


@router.get("/rakshak/burnout", summary="Fetch soldier checks history")
async def get_burnout_history(current_user: dict = Depends(get_current_user)):
    db = get_database()
    user_id = current_user["id"]
    
    if db is not None:
        cursor = db.rakshak_burnouts.find({"user_id": user_id}).sort("created_at", -1)
        history = await cursor.to_list(length=100)
    else:
        history = [b for b in db_manager._in_memory_collections["rakshak_burnouts"] if b["user_id"] == user_id]
        history.sort(key=lambda x: x["created_at"], reverse=True)
        
    for b in history:
        if "_id" in b:
            b["_id"] = str(b["_id"])
            
    return history


@router.get("/rakshak/heatmap", summary="Fetch unit-level aggregated heatmap")
async def get_commander_heatmap(current_user: dict = Depends(get_current_user)):
    """
    Returns aggregated wellness stats. 
    Strict Role-based Authorization: Restricted to Welfare Officers or Admins.
    Individual soldier names/IDs are NEVER exposed through aggregates.
    """
    user_roles = current_user.get("mapped_roles", [current_user["primary_role"]])
    is_authorized = any(role in ["WELFARE_OFFICER", "SYSTEM_ADMIN"] for role in user_roles)
    
    if not is_authorized:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Access Denied. Only commanders or unit welfare officers can view aggregated heatmaps."
        )
        
    db = get_database()
    
    if db is not None:
        cursor = db.rakshak_burnouts.find({})
        all_records = await cursor.to_list(length=1000)
    else:
        all_records = list(db_manager._in_memory_collections["rakshak_burnouts"])
        
    # Compute aggregated stats grouped by mock units (Never exposing user IDs)
    units_dict = {}
    for r in all_records:
        unit = r.get("unit", "General Depot")
        score = r.get("burnout_score", 0)
        
        if unit not in units_dict:
            units_dict[unit] = {"scores": [], "critical_count": 0, "high_count": 0}
            
        units_dict[unit]["scores"].append(score)
        if r.get("risk_tier") == "CRITICAL":
            units_dict[unit]["critical_count"] += 1
        elif r.get("risk_tier") == "HIGH":
            units_dict[unit]["high_count"] += 1
            
    heatmap = []
    for unit, stats in units_dict.items():
        avg = sum(stats["scores"]) / len(stats["scores"]) if stats["scores"] else 0
        heatmap.append({
            "unit": unit,
            "personnel_count": len(stats["scores"]),
            "average_burnout_index": round(avg, 1),
            "critical_risk_count": stats["critical_count"],
            "high_risk_count": stats["high_count"],
            "status": "RED" if avg >= 70 else ("ORANGE" if avg >= 40 else "GREEN")
        })
        
    # Ensure fallback default if database is empty
    if not heatmap:
        heatmap = [
            {"unit": "15th Rajput Regiment", "personnel_count": 24, "average_burnout_index": 45.2, "critical_risk_count": 2, "high_risk_count": 5, "status": "ORANGE"},
            {"unit": "Border Outpost G1", "personnel_count": 12, "average_burnout_index": 78.4, "critical_risk_count": 4, "high_risk_count": 6, "status": "RED"},
            {"unit": "Base Depot Camp", "personnel_count": 82, "average_burnout_index": 22.8, "critical_risk_count": 0, "high_risk_count": 3, "status": "GREEN"}
        ]
        
    return heatmap


# =========================================================================
# 4. NYAYASAHAY ENDPOINTS (Outreach check-ins & Counselor Alerts Escalations)
# =========================================================================

@router.post("/nyaya/distress", summary="Submit wellbeing check-in and compute distress score")
async def record_distress(req: DistressCheckinRequest, current_user: dict = Depends(get_current_user)):
    db = get_database()
    
    # Calculate distress details via tool
    distress = assess_victim_distress_tool(
        sentiment_score=req.sentiment_score,
        case_stage=req.case_stage,
        days_since_incident=req.days_since_incident,
        recent_checkin_responses=req.recent_checkin_responses
    )
    
    escalation_status = "NONE"
    # If high distress score triggers, register counselor alert
    if distress["distress_score"] >= 60:
        escl = trigger_escalation_workflow_tool(
            victim_id=current_user["id"][:8] + "-anonymized",
            distress_score=distress["distress_score"],
            escalation_reason=f"Distress spike during {req.case_stage} legal stage."
        )
        escalation_status = escl["status"]
        
    record = {
        "id": f"DIS-{int(time.time() * 1000)}",
        "user_id": current_user["id"],
        "patient_name": current_user["full_name"],
        "sentiment_score": req.sentiment_score,
        "case_stage": req.case_stage,
        "days_since_incident": req.days_since_incident,
        "recent_checkin_responses": req.recent_checkin_responses,
        "distress_score": distress["distress_score"],
        "distress_level": distress["distress_level"],
        "escalation_status": escalation_status,
        "created_at": datetime.now(timezone.utc).isoformat()
    }
    
    if db is not None:
        await db.nyaya_distress.insert_one(record)
    else:
        db_manager._in_memory_collections["nyaya_distress"].append(record)
        
    return record


@router.get("/nyaya/distress", summary="Fetch wellbeing history")
async def get_distress_history(current_user: dict = Depends(get_current_user)):
    db = get_database()
    user_id = current_user["id"]
    
    if db is not None:
        cursor = db.nyaya_distress.find({"user_id": user_id}).sort("created_at", -1)
        history = await cursor.to_list(length=100)
    else:
        history = [d for d in db_manager._in_memory_collections["nyaya_distress"] if d["user_id"] == user_id]
        history.sort(key=lambda x: x["created_at"], reverse=True)
        
    for d in history:
        if "_id" in d:
            d["_id"] = str(d["_id"])
            
    return history


@router.get("/nyaya/escalations", summary="Fetch escalations alerts workflow list")
async def get_escalations(current_user: dict = Depends(get_current_user)):
    """
    Lists escalated cases. 
    Restricted to Counselors or Admins.
    """
    user_roles = current_user.get("mapped_roles", [current_user["primary_role"]])
    is_authorized = any(role in ["COUNSELOR", "SYSTEM_ADMIN"] for role in user_roles)
    
    if not is_authorized:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Access Denied. Only registered counselors can view escalation notifications."
        )
        
    db = get_database()
    
    if db is not None:
        cursor = db.nyaya_distress.find({"escalation_status": "ESCALATION_DISPATCHED"}).sort("created_at", -1)
        escalations = await cursor.to_list(length=100)
    else:
        escalations = [d for d in db_manager._in_memory_collections["nyaya_distress"] if d["escalation_status"] == "ESCALATION_DISPATCHED"]
        escalations.sort(key=lambda x: x["created_at"], reverse=True)
        
    for e in escalations:
        if "_id" in e:
            e["_id"] = str(e["_id"])
            
    # Mock data fallback for counselors if empty
    if not escalations:
        escalations = [
            {"id": "DIS-1700000000000", "user_id": "usr-test-001", "patient_name": "Rahul Sharma", "case_stage": "trial", "distress_score": 75.0, "distress_level": "HIGH_DISTRESS", "escalation_status": "ESCALATION_DISPATCHED", "created_at": datetime.now(timezone.utc).isoformat()}
        ]
        
    return escalations
