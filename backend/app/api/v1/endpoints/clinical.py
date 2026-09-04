"""
Clinical Engine & Dual-Path Prescriptions Router
"""
from fastapi import APIRouter, Body
from typing import List, Optional
from pydantic import BaseModel
from app.services.clinical_engine import generate_dual_prescription, DUAL_PATHWAY_DB

router = APIRouter()

class VoiceIntakeRequest(BaseModel):
    transcript: str
    language: str = "hi-IN" # Hindi / Tamil / Telugu / Bengali / English
    patient_age: Optional[int] = 35
    gender: Optional[str] = "male"

class DualPrescriptionRequest(BaseModel):
    condition_key: str # HEAT_STRESS / ANEMIA / HYPERTENSION / CHRONIC_STRESS
    symptoms: Optional[List[str]] = []

@router.post("/dual-prescription")
def get_dual_pathway_prescription(req: DualPrescriptionRequest = Body(...)):
    """
    Generates integrated Western (ICD-11) + AYUSH parallel treatment recommendations.
    """
    return generate_dual_prescription(req.condition_key, req.symptoms)

@router.get("/dual-prescription/conditions")
def list_supported_conditions():
    """Lists supported dual-prescription medical conditions."""
    return {"supported_conditions": list(DUAL_PATHWAY_DB.keys())}

@router.post("/intake-voice")
def process_vernacular_voice_intake(req: VoiceIntakeRequest = Body(...)):
    """
    Converts raw vernacular voice transcript into structured clinical SOAP notes.
    """
    text = req.transcript.lower()
    
    # Extract symptoms heuristically
    extracted_symptoms = []
    if "bukhar" in text or "fever" in text or "koyal" in text or "kaichal" in text:
        extracted_symptoms.append("Fever (Pyrexia)")
    if "khansi" in text or "cough" in text or "irumbal" in text:
        extracted_symptoms.append("Cough (Bronchial Irritation)")
    if "sar dard" in text or "headache" in text or "thalai vali" in text:
        extracted_symptoms.append("Cephalea (Headache)")
    if "chakar" in text or "dizziness" in text or "giddiness" in text:
        extracted_symptoms.append("Vertigo / Heat Dizziness")

    if not extracted_symptoms:
        extracted_symptoms = ["General Malaise / Fatigue"]

    primary_condition = "HEAT_STRESS" if ("fever" in text or "chakar" in text) else "ANEMIA"
    dual_rx = generate_dual_prescription(primary_condition, extracted_symptoms)

    return {
        "status": "SUCCESS",
        "soap_note": {
            "Subjective": f"Patient reports: '{req.transcript}'. Language: {req.language}.",
            "Objective": f"Extracted Symptoms: {', '.join(extracted_symptoms)}. Patient Age: {req.patient_age}, Gender: {req.gender}.",
            "Assessment": f"Suspected Primary Condition: {primary_condition.replace('_', ' ')} (ICD-11: {dual_rx['icd_11_code']})",
            "Plan": dual_rx["allopathic_pathway"]
        },
        "dual_prescription": dual_rx
    }
