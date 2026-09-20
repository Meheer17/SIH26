"""
SvasthyaSetu — Digital Twin API Endpoints
Feature 12: Longitudinal 3D Digital Twin & Health Score Engine
"""

from typing import Optional, Dict, Any, List
from fastapi import APIRouter, Depends, HTTPException, Query
from pydantic import BaseModel, Field

from app.api.deps import get_current_user
from app.db.database import get_database, db_manager
from app.services.digital_twin import PatientDigitalTwinService

router = APIRouter()

class WhatIfRequest(BaseModel):
    intervention_key: str = Field(..., description="Key of intervention e.g. 'stop_bp_meds', 'stop_iron_tablets', 'extreme_heat_exposure', 'daily_pranayama_hydration', 'dehydration_crisis', 'high_altitude_deployment'")
    weeks: int = Field(default=24, ge=4, le=52, description="Simulation horizon in weeks (default: 24)")

class VoiceBriefingRequest(BaseModel):
    intervention_key: Optional[str] = Field(default=None, description="Optional active intervention scenario to brief on")
    language: str = Field(default="en", description="Language code e.g. 'en', 'hi'")


@router.get("/status", summary="F12: Get Patient Digital Twin Multi-Organ Status")
async def get_digital_twin_status(current_user: dict = Depends(get_current_user)):
    """
    Computes real-time multi-organ health twin from user's latest stored telemetry,
    vitals history, and environmental heat stress.
    """
    user_id = current_user["id"]
    db = get_database()

    # Query latest vitals from ArogyaSathi or PHC collections
    latest_vitals = {}
    if db is not None:
        vitals_cursor = db.arogya_vitals.find({"user_id": user_id}).sort("created_at", -1)
        vitals_list = await vitals_cursor.to_list(length=1)
        if vitals_list:
            latest_vitals = vitals_list[0]
    else:
        mem_vitals = [v for v in db_manager._in_memory_collections.get("arogya_vitals", []) if v.get("user_id") == user_id]
        if mem_vitals:
            latest_vitals = mem_vitals[-1]

    # Merge with default normal parameters if empty
    vitals_payload = {
        "heart_rate": latest_vitals.get("heart_rate", 74.0),
        "spo2": latest_vitals.get("spo2", 98.0),
        "body_temp_c": latest_vitals.get("body_temp_c", 36.9),
        "systolic_bp": latest_vitals.get("systolic_bp", 120.0),
        "diastolic_bp": latest_vitals.get("diastolic_bp", 80.0),
        "stress_score": latest_vitals.get("stress_score", 26.0),
        "hydration_pct": latest_vitals.get("hydration_pct", 78.0)
    }

    organ_data = PatientDigitalTwinService.calculate_organ_status(vitals_payload, current_user)
    organ_data["user_id"] = user_id
    organ_data["patient_name"] = current_user.get("full_name", "Ramesh Chandra Patel")
    organ_data["gender"] = current_user.get("gender", "Male")
    organ_data["timestamp"] = latest_vitals.get("created_at", None)

    return organ_data


@router.get("/forecast", summary="F12: Longitudinal 24-Week Bayesian Trajectory Forecast")
async def get_trajectory_forecast(
    intervention: Optional[str] = Query(default=None, description="Optional what-if scenario key"),
    weeks: int = Query(default=24, ge=4, le=52, description="Forecast horizon in weeks"),
    current_user: dict = Depends(get_current_user)
):
    """
    Simulates 100 Monte Carlo trajectories with Bayesian updating, producing
    80% confidence interval bands (median, p10, p90) for all physiological indices.
    """
    baseline = {
        "hemoglobin": 13.5,
        "systolic_bp": 120.0,
        "cardiovascular_strain": 22.0,
        "stress_score": 26.0,
        "renal_heat_strain": 20.0,
        "composite_health": 86.0
    }

    result = PatientDigitalTwinService.simulate_longitudinal_trajectory(
        baseline_metrics=baseline,
        intervention_key=intervention,
        weeks=weeks
    )
    result["patient_name"] = current_user.get("full_name", "Ramesh Chandra Patel")
    return result


@router.post("/what-if", summary="F12: Simulate What-If Clinical Intervention")
async def simulate_what_if_scenario(
    req: WhatIfRequest,
    current_user: dict = Depends(get_current_user)
):
    """
    Evaluates physiological outcome of specific lifestyle or medical intervention
    against baseline trajectory.
    """
    if req.intervention_key not in PatientDigitalTwinService.INTERVENTIONS:
        raise HTTPException(status_code=400, detail=f"Unknown intervention key. Choose from: {list(PatientDigitalTwinService.INTERVENTIONS.keys())}")

    baseline_metrics = {
        "hemoglobin": 13.5,
        "systolic_bp": 120.0,
        "cardiovascular_strain": 22.0,
        "stress_score": 26.0,
        "renal_heat_strain": 20.0,
        "composite_health": 86.0
    }

    baseline_sim = PatientDigitalTwinService.simulate_longitudinal_trajectory(baseline_metrics, intervention_key=None, weeks=req.weeks)
    simulated_sim = PatientDigitalTwinService.simulate_longitudinal_trajectory(baseline_metrics, intervention_key=req.intervention_key, weeks=req.weeks)

    intervention_meta = PatientDigitalTwinService.INTERVENTIONS[req.intervention_key]

    return {
        "scenario_key": req.intervention_key,
        "title": intervention_meta["title"],
        "description": intervention_meta["description"],
        "impact_summary": intervention_meta["impact_summary"],
        "organ_alerts": intervention_meta["organ_alerts"],
        "baseline_trajectory": baseline_sim["metrics"],
        "simulated_trajectory": simulated_sim["metrics"],
        "weeks": list(range(req.weeks + 1)),
        "risk_delta": {
            "cardiovascular_strain_delta": round(simulated_sim["metrics"]["cardiovascular_strain"]["projected_24w_median"] - baseline_sim["metrics"]["cardiovascular_strain"]["projected_24w_median"], 1),
            "systolic_bp_delta": round(simulated_sim["metrics"]["systolic_bp"]["projected_24w_median"] - baseline_sim["metrics"]["systolic_bp"]["projected_24w_median"], 1),
            "composite_health_delta": round(simulated_sim["metrics"]["composite_health"]["projected_24w_median"] - baseline_sim["metrics"]["composite_health"]["projected_24w_median"], 1)
        }
    }


@router.get("/interventions", summary="F12: List Available What-If Interventions")
async def list_interventions():
    """Returns directory of supported what-if scenarios."""
    return {
        "count": len(PatientDigitalTwinService.INTERVENTIONS),
        "interventions": [
            {
                "key": k,
                "title": v["title"],
                "description": v["description"],
                "impact_summary": v["impact_summary"],
                "organ_alerts": v["organ_alerts"]
            }
            for k, v in PatientDigitalTwinService.INTERVENTIONS.items()
        ]
    }


@router.post("/voice-briefing", summary="F12: Generate Talking Avatar Clinical Audio Briefing")
async def generate_voice_briefing(
    req: VoiceBriefingRequest,
    current_user: dict = Depends(get_current_user)
):
    """
    Generates natural clinical speech synthesis script and lip-sync viseme frames
    for the 3D talking avatar.
    """
    vitals = {"heart_rate": 74.0, "spo2": 98.0, "body_temp_c": 36.9, "systolic_bp": 120.0, "diastolic_bp": 80.0, "stress_score": 26.0}
    organ_data = PatientDigitalTwinService.calculate_organ_status(vitals, current_user)

    briefing = PatientDigitalTwinService.generate_talking_avatar_briefing(
        organ_data=organ_data,
        intervention_key=req.intervention_key,
        language=req.language
    )
    briefing["patient_name"] = current_user.get("full_name", "Ramesh Chandra Patel")
    return briefing


@router.get("/avatar-models", summary="F12: Free 3D Talking Avatar Rigs & GLB Models")
async def get_avatar_models():
    """
    Returns verified free & open-source 3D humanoid GLB models with morph targets / visemes
    compatible with Three.js, TalkingHead, WebGL, and mobile 3D controllers.
    """
    return {
        "count": len(PatientDigitalTwinService.AVATAR_PRESETS),
        "frameworks_supported": ["TalkingHead (met4citizen)", "Three.js GLTFLoader", "Flutter 3D / WebGL Canvas", "Babylon.js"],
        "standard_visemes": ["viseme_aa", "viseme_E", "viseme_I", "viseme_O", "viseme_U", "jawOpen", "mouthSmile"],
        "avatars": PatientDigitalTwinService.AVATAR_PRESETS
    }
