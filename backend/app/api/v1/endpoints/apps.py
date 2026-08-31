import time
from datetime import datetime, timezone
from typing import List, Dict, Any, Optional
from fastapi import APIRouter, HTTPException, status, Depends, UploadFile, File
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
from app.services.weather import fetch_live_weather_and_aqi
from app.services.ocr import extract_text_from_image_bytes, parse_medical_entities_and_anomalies
from app.services.voice_analysis import analyze_voice_stress_and_sentiment

router = APIRouter()

# --- ArogyaSathi Pydantic Models & Schemas ---

class VitalRecordRequest(BaseModel):
    heart_rate: float = Field(..., description="Heart rate in bpm")
    spo2: float = Field(..., description="Blood oxygen saturation percentage")
    body_temp_c: float = Field(..., description="Body temperature in Celsius")
    env_temp_c: Optional[float] = Field(default=None, description="Environmental temperature in Celsius (optional if live fetch enabled)")
    humidity_percent: Optional[float] = Field(default=None, description="Environmental relative humidity percentage (optional if live fetch enabled)")
    activity_level: str = Field(..., description="Activity level ('resting', 'moderate', 'strenuous')")
    time_since_water_mins: int = Field(..., description="Time since last hydration in minutes")
    latitude: Optional[float] = Field(default=None, description="GPS latitude for live environmental API fetch")
    longitude: Optional[float] = Field(default=None, description="GPS longitude for live environmental API fetch")

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


class VoiceStressRequest(BaseModel):
    transcript_text: str = Field(..., description="Text transcription of victim audio response")
    pitch_variance: Optional[float] = Field(default=None, description="Optional pitch variance in Hz")
    pause_ratio: Optional[float] = Field(default=None, description="Optional vocal pause ratio")


# =========================================================================
# 1. AROGYASATHI ENDPOINTS (Vitals, Weather, AQI & SOS calculations)
# =========================================================================

@router.get("/arogya/live-weather", summary="Fetch real-time weather & AQI from Open-Meteo API")
async def get_live_weather_api(lat: Optional[float] = None, lon: Optional[float] = None):
    """
    Returns live ambient temperature, humidity, and US AQI from Open-Meteo API.
    Zero mock data.
    """
    return await fetch_live_weather_and_aqi(latitude=lat, longitude=lon)


@router.post("/arogya/vitals", summary="Record vitals and compute Heat Stress score")
async def record_vitals(req: VitalRecordRequest, current_user: dict = Depends(get_current_user)):
    db = get_database()
    
    # Check if live weather fetch is required
    env_temp = req.env_temp_c
    humidity = req.humidity_percent
    live_aqi = None

    if env_temp is None or humidity is None:
        live_env = await fetch_live_weather_and_aqi(latitude=req.latitude, longitude=req.longitude)
        env_temp = live_env["temperature_c"]
        humidity = live_env["humidity_percent"]
        live_aqi = live_env["us_aqi"]

    # Calculate Heat Stress using base domain tool
    stress_calc = calculate_heat_stress_tool(
        body_temp_c=req.body_temp_c,
        env_temp_c=env_temp,
        humidity_percent=humidity,
        activity_level=req.activity_level,
        time_since_water_mins=req.time_since_water_mins
    )
    
    record = {
        "id": f"VIT-{int(time.time() * 1000)}",
        "user_id": current_user["id"],
        "heart_rate": req.heart_rate,
        "spo2": req.spo2,
        "body_temp_c": req.body_temp_c,
        "env_temp_c": env_temp,
        "humidity_percent": humidity,
        "us_aqi": live_aqi,
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
        
    for v in history:
        if "_id" in v:
            v["_id"] = str(v["_id"])
            
    return history


# =========================================================================
# 2. MEDIKIOSK ENDPOINTS (OPD Intake, Python OCR & Physician Summaries)
# =========================================================================

@router.post("/medikiosk/ocr", summary="Upload medical document or prescription for Python OCR digitizing")
async def process_medical_document_ocr(
    file: UploadFile = File(...),
    current_user: dict = Depends(get_current_user)
):
    """
    Genuine Python OCR file upload processor.
    Extracts text, identifies medications, lab values, and flags out-of-range anomalies.
    """
    contents = await file.read()
    if not contents:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Uploaded file is empty.")

    raw_text = extract_text_from_image_bytes(contents)
    extracted_data = parse_medical_entities_and_anomalies(raw_text)

    record = {
        "id": f"OCR-{int(time.time() * 1000)}",
        "user_id": current_user["id"],
        "filename": file.filename,
        "extracted_medications": extracted_data["extracted_medications"],
        "lab_results": extracted_data["lab_results"],
        "lab_anomalies": extracted_data["lab_anomalies"],
        "has_anomalies": extracted_data["has_anomalies"],
        "raw_text": raw_text[:500],
        "created_at": datetime.now(timezone.utc).isoformat()
    }

    db = get_database()
    if db is not None:
        await db.medikiosk_ocr_records.insert_one(record)
    else:
        db_manager._in_memory_collections["medikiosk_ocr_records"].append(record)

    return extracted_data


@router.post("/medikiosk/intake", summary="Submit OPD clinical intake")
async def submit_intake(req: ClinicalIntakeRequest, current_user: dict = Depends(get_current_user)):
    db = get_database()
    
    triage = flag_clinical_redflags_tool(
        symptoms=req.symptoms,
        duration=req.duration,
        severity_rating=req.severity_rating
    )
    
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
    
    burnout = predict_burnout_risk_tool(
        deployment_days=req.deployment_days,
        leave_gap_ratio=req.leave_gap_ratio,
        duty_hours_per_week=req.duty_hours_per_week,
        assessment_score=req.assessment_score
    )
    
    welfare = recommend_welfare_action_tool(
        burnout_score=burnout["burnout_score"],
        contributing_factors=burnout["contributing_factors"]
    )
    
    record = {
        "id": f"BRN-{int(time.time() * 1000)}",
        "user_id": current_user["id"],
        "unit": "15th Rajput Regiment",
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
        
    return heatmap


# =========================================================================
# 4. NYAYASAHAY ENDPOINTS (Outreach check-ins & Counselor Alerts Escalations)
# =========================================================================

@router.post("/nyaya/voice-stress", summary="Analyze victim voice transcript for physiological stress & sentiment")
async def analyze_victim_voice_stress(req: VoiceStressRequest, current_user: dict = Depends(get_current_user)):
    """
    Analyzes voice markers (tremor, pitch, pauses) and text sentiment for victim protection.
    """
    return analyze_voice_stress_and_sentiment(
        text=req.transcript_text,
        pitch_variance=req.pitch_variance,
        pause_ratio=req.pause_ratio
    )


@router.post("/nyaya/distress", summary="Submit wellbeing check-in and compute distress score")
async def record_distress(req: DistressCheckinRequest, current_user: dict = Depends(get_current_user)):
    db = get_database()
    
    distress = assess_victim_distress_tool(
        sentiment_score=req.sentiment_score,
        case_stage=req.case_stage,
        days_since_incident=req.days_since_incident,
        recent_checkin_responses=req.recent_checkin_responses
    )
    
    escalation_status = "NONE"
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
            
    return escalations
