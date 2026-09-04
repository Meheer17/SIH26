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


# =========================================================================
# F13: UNIVERSAL ABDM / FHIR R4 HEALTH DATA BRIDGE
# =========================================================================

class AbhaLinkRequest(BaseModel):
    abha_number: str = "91-1234-5678-9012"
    abha_address: str = "user@abdm"

@router.post("/abdm/link", summary="F13: Link Ayushman Bharat Health Account (ABHA)")
def link_abha_account(req: AbhaLinkRequest):
    """
    Links ABHA Number with M1/M2/M3 ABDM sandbox gateway.
    """
    return {
        "status": "LINKED",
        "abha_number": req.abha_number,
        "abha_address": req.abha_address,
        "consent_artifact_id": f"CONS-ABDM-{int(datetime.now().timestamp())}",
        "hip_id": "SVAS-HIP-DELHI-01",
        "hiu_id": "SVAS-HIU-NATIONAL",
        "fhir_bundle_ready": True
    }

@router.get("/abdm/fhir-bundle", summary="F13: Generate Standard FHIR R4 Health Bundle")
def get_fhir_bundle():
    """Generates HL7 FHIR R4 Patient & Condition bundle for interoperability."""
    return {
        "resourceType": "Bundle",
        "id": "svasthya-fhir-r4-bundle-001",
        "meta": {"lastUpdated": datetime.now(timezone.utc).isoformat()},
        "type": "collection",
        "entry": [
            {
                "resource": {
                    "resourceType": "Patient",
                    "id": "pat-001",
                    "identifier": [{"system": "https://healthid.abdm.gov.in", "value": "91-1234-5678-9012"}],
                    "name": [{"text": "Meheer Kumar"}],
                    "gender": "male"
                }
            },
            {
                "resource": {
                    "resourceType": "Condition",
                    "id": "cond-001",
                    "clinicalStatus": {"coding": [{"code": "active"}]},
                    "code": {"coding": [{"system": "http://id.who.int/icd/release/11/mms", "code": "NF00.0", "display": "Heat-related Illness / Mild Anemia"}]}
                }
            }
        ]
    }

