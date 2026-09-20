import time
import uuid
from datetime import datetime, timezone, timedelta
from typing import List, Dict, Any, Optional
from fastapi import APIRouter, HTTPException, status, Depends, Query, UploadFile, File
from pydantic import BaseModel, Field

from app.db.database import get_database, db_manager
from app.api.deps import get_current_user

router = APIRouter()

# =========================================================================
# IN-MEMORY COLLECTIONS INITIALIZATION (FOR ROBUST INSTANT FALLBACK)
# =========================================================================
for collection_name in [
    "medikiosk_patients",
    "medikiosk_sessions",
    "medikiosk_history_interviews",
    "medikiosk_consents",
    "medikiosk_documents",
    "medikiosk_summaries",
    "medikiosk_queue",
    "medikiosk_triage_alerts",
    "medikiosk_assistance_requests",
    "medikiosk_vitals",
    "medikiosk_departments",
    "medikiosk_kiosks",
    "medikiosk_feedbacks",
    "medikiosk_prescriptions",
    "medikiosk_audit_logs",
    "medikiosk_fhir_resources"
]:
    if collection_name not in db_manager._in_memory_collections:
        db_manager._in_memory_collections[collection_name] = []


# =========================================================================
# PYDANTIC SCHEMAS
# =========================================================================

class AbhaVerifyRequest(BaseModel):
    abha_id: str = Field(..., description="14-digit ABHA ID or mobile number")
    otp: Optional[str] = Field(default=None, description="6-digit OTP if verifying")

class AadhaarVerifyRequest(BaseModel):
    aadhaar_number: str = Field(..., description="12-digit Aadhaar number")
    otp: Optional[str] = Field(default="123456", description="OTP sent to UIDAI registered mobile")

class AbhaCreateRequest(BaseModel):
    aadhaar_number: str
    full_name: str
    dob_or_age: str
    gender: str
    mobile: str
    address: Optional[str] = "Varanasi, Uttar Pradesh"

class PatientRegisterRequest(BaseModel):
    full_name: str
    age: int
    gender: str
    phone: str
    address: Optional[str] = "Varanasi, UP"
    abha_id: Optional[str] = None
    emergency_contact: Optional[str] = None
    preferred_language: Optional[str] = "hi"
    department: Optional[str] = "General Medicine OPD"

class SessionCreateRequest(BaseModel):
    patient_id: str
    kiosk_id: Optional[str] = "KIOSK-04"
    language: Optional[str] = "hi"
    department: Optional[str] = "General Medicine OPD"
    visit_type: Optional[str] = "walk_in"

class ConsentGrantRequest(BaseModel):
    patient_id: str
    session_id: Optional[str] = None
    consent_types: List[str] = Field(
        default=["voice_recording", "ocr_scanning", "doctor_sharing", "abha_link", "research_deidentified"],
        description="List of granted consent scopes under DPDPA 2023"
    )
    signature_data: Optional[str] = "e-sign-verified-on-touchpad"
    audio_consent_verified: Optional[bool] = True

class HistoryStartRequest(BaseModel):
    session_id: str
    department: Optional[str] = "General Medicine OPD"
    mode: Optional[str] = "allopathic" # 'allopathic' or 'ayush'
    chief_complaint: Optional[str] = None
    body_site: Optional[str] = None

class HistoryRespondRequest(BaseModel):
    interview_id: str
    question_id: str
    answer_text: str
    input_mode: Optional[str] = "touch" # 'voice', 'touch', 'text'

class PrakritiRespondRequest(BaseModel):
    assessment_id: str
    question_id: str
    answer: str # e.g. 'vata', 'pitta', 'kapha'

class AharaViharaRequest(BaseModel):
    session_id: str
    patient_id: Optional[str] = None
    diet_type: str = "vegetarian" # vegetarian, non-vegetarian, vegan
    meal_regularity: str = "regular"
    taste_preference: str = "madhura_tikta" # sweet, bitter, spicy, etc.
    appetite_nature: str = "manda" # manda (low), tikshna (sharp), visham (erratic), sama (normal)
    bowel_regularity: str = "irregular"
    sleep_duration_hrs: float = 6.5
    sleep_quality: str = "interrupted"
    exercise_frequency: str = "sedentary"

class DashavidhaSubmissionRequest(BaseModel):
    patient_id: str
    prakriti: str = "Pitta-Kapha Pradhana"
    vikriti: str = "Vata-Pitta Dushti"
    sara: str = "Rakta-Mamsa Madhyama Sara"
    samhanana: str = "Madhyama Samhanana (Medium Compactness)"
    pramana: str = "Anurupa Pramana (Symmetrical)"
    satmya: str = "Sarva-Rasa Satmya"
    sattva: str = "Madhyama Sattva (Balanced Resilience)"
    ahara_shakti: str = "Manda Agni (Low Assimilation)"
    vyayama_shakti: str = "Madhyama Vyayama Shakti"
    vaya: str = "Madhyama Vaya (Adult Stage)"

class SummarySectionEditRequest(BaseModel):
    summary_id: str
    section: str # chief_complaint, hpi, past_medical_history, drug_allergy, family_history, personal_history, ros
    updated_content: str

class DoctorExamNotesRequest(BaseModel):
    encounter_id: str
    patient_id: str
    general_exam: Optional[str] = "Conscious, oriented, afebrile, pulse 78/min regular, BP 130/84 mmHg"
    systemic_cvs: Optional[str] = "S1 S2 heard, no murmurs, normal apical impulse"
    systemic_rs: Optional[str] = "Bilateral vesicular breath sounds, mild expiratory wheeze at bases"
    systemic_abdomen: Optional[str] = "Soft, non-tender, no organomegaly"
    systemic_cns: Optional[str] = "Cranial nerves intact, normal tone and power 5/5"
    dictation_text: Optional[str] = None

class DualPrescriptionRequest(BaseModel):
    encounter_id: str
    patient_id: str
    diagnoses: List[str] = ["Angina Pectoris (BA80)", "Essential Hypertension (BA00)"]
    ayush_diagnoses: Optional[List[str]] = ["Hridroga (KVT-04)", "Manda Agni"]
    allopathic_medications: List[Dict[str, Any]] = [
        {"name": "Tab Sorbitrate 5mg", "dosage": "SL PRN", "duration": "14 days", "instructions": "Sublingual for acute chest pain"},
        {"name": "Tab Amlodipine 5mg", "dosage": "1-0-0", "duration": "30 days", "instructions": "Once daily morning after food"},
        {"name": "Tab Atorvastatin 20mg", "dosage": "0-0-1", "duration": "30 days", "instructions": "At bedtime"}
    ]
    ayush_medications: List[Dict[str, Any]] = [
        {"name": "Arjunarishta", "dosage": "20ml BD", "duration": "30 days", "instructions": "With equal quantity of lukewarm water after meals"},
        {"name": "Prabhakar Vati", "dosage": "1 tab BD", "duration": "30 days", "instructions": "Cardio-protective formulation"},
        {"name": "Hridayarnava Rasa", "dosage": "125mg BD", "duration": "15 days", "instructions": "Under clinical supervision"}
    ]
    investigations_ordered: List[str] = ["12-Lead ECG", "Serum Troponin-I", "Lipid Profile", "HbA1c", "Serum Creatinine"]
    lifestyle_advice: Optional[str] = "Low salt, low fat diet. Avoid heavy exertion. Regular morning walk 20 min."
    follow_up_days: int = 7

class TriageVitalsRequest(BaseModel):
    patient_id: str
    session_id: Optional[str] = None
    blood_pressure_sys: int = 138
    blood_pressure_dia: int = 88
    heart_rate_bpm: int = 82
    temperature_c: float = 37.1
    spo2_pct: int = 97
    respiratory_rate: int = 18
    weight_kg: float = 72.5
    height_cm: float = 172.0

class EsiScoringRequest(BaseModel):
    patient_id: str
    esi_level: int = Field(..., ge=1, le=5, description="ESI 1 (Immediate resuscitation) to ESI 5 (Non-urgent)")
    routing_department: str = "Cardiology Special OPD"
    notes: Optional[str] = "Exertional dyspnea, stable vitals, requires priority OPD slot"

class PatientFeedbackRequest(BaseModel):
    session_id: str
    patient_name: Optional[str] = "Anonymous"
    rating: int = Field(..., ge=1, le=5)
    ease_of_use: str = "Very Easy"
    language_satisfaction: str = "Clear Hindi/Regional audio"
    comments: Optional[str] = "Great experience, no long wait at doctor counter!"


# =========================================================================
# SOCRATES QUESTION ONTOLOGY & CLINICAL LOGIC
# =========================================================================

SOCRATES_TREES = {
    "chest": [
        {
            "id": "q_site",
            "section": "Site",
            "question": "सीने में दर्द या भारीपन ठीक किस जगह महसूस हो रहा है? (Where exactly is the chest pain located?)",
            "options": ["सीने के बीच में (Center / Retrosternal)", "बाईं तरफ (Left side)", "दाईं तरफ (Right side)", "पेट के ऊपरी हिस्से में (Epigastrium)"]
        },
        {
            "id": "q_onset",
            "section": "Onset",
            "question": "यह दर्द कब और कैसे शुरू हुआ? (When and how did this pain begin?)",
            "options": ["अचानक 1-2 घंटे पहले (Sudden 1-2 hours ago)", "2-3 दिनों से धीरे-धीरे (Gradual over 2-3 days)", "चलने या सीढ़ियां चढ़ने पर (Upon physical exertion)", "खाना खाने के बाद (After meals)"]
        },
        {
            "id": "q_character",
            "section": "Character",
            "question": "दर्द का प्रकार कैसा है? (What is the character of the pain?)",
            "options": ["दबाव या जकड़न जैसा (Squeezing / Pressure)", "जलन जैसा (Burning / Acidic)", "सुई चुभने जैसा (Sharp / Stabbing)", "हल्का भारीपन (Dull ache)"]
        },
        {
            "id": "q_radiation",
            "section": "Radiation",
            "question": "क्या दर्द कहीं और भी फैल रहा है? (Does the pain radiate anywhere?)",
            "options": ["बाएं हाथ या कंधे की तरफ (Left arm / shoulder)", "गर्दन या जबड़े की तरफ (Neck / jaw)", "पीठ की तरफ (Back)", "कहीं नहीं, केवल सीने में (No radiation)"]
        },
        {
            "id": "q_associated",
            "section": "Associated",
            "question": "क्या इसके साथ अन्य लक्षण भी हैं? (Are there any associated symptoms?)",
            "options": ["सांस फूलना या घबराहट (Shortness of breath / palpitations)", "पसीना आना या चक्कर (Cold sweating / dizziness)", "उल्टी या मिचली (Nausea / vomiting)", "कोई अन्य लक्षण नहीं (None)"]
        },
        {
            "id": "q_timing",
            "section": "Timing",
            "question": "दर्द का समय और अवधि कैसी है? (What is the timing and duration?)",
            "options": ["लगातार बना हुआ है (Continuous)", "आता-जाता रहता है (Intermittent, 5-15 mins)", "केवल सुबह के समय (Morning only)", "रात में सोते समय (During night)"]
        },
        {
            "id": "q_exacerbating",
            "section": "Exacerbating/Relieving",
            "question": "किस स्थिति में दर्द बढ़ता या घटता है? (What makes it worse or better?)",
            "options": ["आराम करने से घटता है (Relieved by rest)", "गहरी सांस लेने से बढ़ता है (Worse on deep breathing)", "एंटासिड लेने से घटता है (Relieved by antacids)", "दबाने से दर्द होता है (Tender on pressure)"]
        },
        {
            "id": "q_severity",
            "section": "Severity",
            "question": "दर्द की तीव्रता 1 से 10 के पैमाने पर कितनी है? (Rate pain severity 1 to 10)",
            "options": ["1-3: हल्का (Mild)", "4-6: मध्यम (Moderate)", "7-8: तीव्र (Severe)", "9-10: असहनीय (Unbearable)"]
        }
    ],
    "head": [
        {
            "id": "q_site",
            "section": "Site",
            "question": "सिरदर्द किस भाग में हो रहा है? (Where is the headache located?)",
            "options": ["एक तरफ (Unilateral / Hemicranial)", "पूरे सिर में (Diffuse / Whole head)", "माथे और आंखों के पीछे (Frontal / Retro-orbital)", "सिर के पिछले हिस्से में (Occipital)"]
        },
        {
            "id": "q_character",
            "section": "Character",
            "question": "सिरदर्द कैसा महसूस हो रहा है? (What type of headache is it?)",
            "options": ["धड़कन जैसा (Throbbing / Pulsatile)", "दबाव या भारीपन (Tight band / Tension)", "बिजली के झटके जैसा (Lancinating)", "लगातार हल्का दर्द (Dull continuous)"]
        },
        {
            "id": "q_associated",
            "section": "Associated",
            "question": "क्या रोशनी या आवाज से परेशानी होती है? (Any photophobia or nausea?)",
            "options": ["हां, रोशनी और आवाज से परेशानी (Photophobia + Phonophobia)", "उल्टी या मिचली (Nausea / vomiting)", "गर्दन में अकड़न (Neck stiffness - Alert)", "कोई नहीं (None)"]
        }
    ],
    "abdomen": [
        {
            "id": "q_site",
            "section": "Site",
            "question": "पेट दर्द किस जगह हो रहा है? (Where is abdominal pain located?)",
            "options": ["नाभि के पास (Periumbilical)", "दाईं तरफ नीचे (Right lower quadrant)", "ऊपरी पेट में (Epigastrium)", "पूरे पेट में (Generalized)"]
        },
        {
            "id": "q_onset",
            "section": "Onset",
            "question": "दर्द कब से है? (Duration of abdominal pain)",
            "options": ["कुछ घंटों से (Hours)", "1-2 दिनों से (1-2 days)", "हफ्तों से (Chronic / Weeks)"]
        }
    ],
    "respiratory": [
        {
            "id": "q_breath",
            "section": "Breathlessness",
            "question": "सांस लेने में तकलीफ कब अधिक होती है? (When is dyspnea worst?)",
            "options": ["सीधे लेटने पर (Orthopnea)", "चलने-फिरने पर (On exertion)", "लगातार बैठी स्थिति में भी (At rest)", "रात में अचानक जागने पर (PND)"]
        },
        {
            "id": "q_cough",
            "section": "Cough",
            "question": "क्या खांसी भी आ रही है? (Is there associated cough?)",
            "options": ["सूखी खांसी (Dry cough)", "बलगम वाली खांसी (Productive sputum)", "खांसी में खून (Hemoptysis - Red Flag)", "कोई खांसी नहीं (No cough)"]
        }
    ]
}

# Red Flag symptom rules
RED_FLAG_PATTERNS = [
    {"keywords": ["chest", "pain", "sweat", "breath"], "flag": "SUSPECTED ACUTE CORONARY SYNDROME (ACS)", "severity": "HIGH", "action": "Immediate ECG & Emergency Consultation Bypass"},
    {"keywords": ["headache", "stiffness", "fever", "vomit"], "flag": "SUSPECTED MENINGITIS / SUBARACHNOID HEMORRHAGE", "severity": "HIGH", "action": "Emergency CT / Lumbar Puncture alert"},
    {"keywords": ["slurred", "droop", "weakness", "arm"], "flag": "SUSPECTED ACUTE ISCHEMIC STROKE", "severity": "CRITICAL", "action": "Immediate Code Stroke Protocol"},
    {"keywords": ["blood", "cough", "hemoptysis"], "flag": "MASSIVE HEMOPTYSIS", "severity": "HIGH", "action": "Emergency Pulmonology / Isolation"},
    {"keywords": ["suicide", "end life", "hopeless"], "flag": "PSYCHIATRIC EMERGENCY / SELF-HARM RISK", "severity": "CRITICAL", "action": "Urgent Crisis Counselor Dispatch"}
]


# =========================================================================
# HELPER TO SEED DEMO DATA
# =========================================================================

async def ensure_medikiosk_demo_data():
    """Seed comprehensive realistic records for MediKiosk demo."""
    db = get_database()
    
    # Check if already seeded in-memory
    if len(db_manager._in_memory_collections.get("medikiosk_summaries", [])) > 0 and len(db_manager._in_memory_collections.get("medikiosk_patients", [])) > 0:
        return

    now = datetime.now(timezone.utc)
    
    # 1. Demo Patients
    demo_patients = [
        {
            "_id": "pat-rajesh-001",
            "id": "pat-rajesh-001",
            "full_name": "Rajesh Kumar",
            "age": 48,
            "gender": "Male",
            "phone": "+91 98412 88421",
            "address": "B-14 Chetganj, Varanasi, UP",
            "abha_id": "91-8842-1094-8812",
            "emergency_contact": "Sunita Kumar (Wife): +91 98412 88422",
            "preferred_language": "hi",
            "department": "Cardiology Special OPD",
            "uhid": "UHID-VAR-2026-08842",
            "registered_at": (now - timedelta(minutes=45)).isoformat()
        },
        {
            "_id": "pat-savitri-002",
            "id": "pat-savitri-002",
            "full_name": "Savitri Devi",
            "age": 64,
            "gender": "Female",
            "phone": "+91 98110 41092",
            "address": "Village Chitaipur, Varanasi, UP",
            "abha_id": "91-4109-7721-0092",
            "emergency_contact": "Manoj Devi (Son): +91 98110 41093",
            "preferred_language": "hi",
            "department": "AYUSH Integrated OPD",
            "uhid": "UHID-VAR-2026-04109",
            "registered_at": (now - timedelta(minutes=70)).isoformat()
        },
        {
            "_id": "pat-aarav-003",
            "id": "pat-aarav-003",
            "full_name": "Aarav Sharma",
            "age": 12,
            "gender": "Male",
            "phone": "+91 97230 99120",
            "address": "Plot 9 Lanka, Varanasi, UP",
            "abha_id": "91-9912-3341-8810",
            "emergency_contact": "Vikram Sharma (Father): +91 97230 99121",
            "preferred_language": "en",
            "department": "General Medicine OPD",
            "uhid": "UHID-VAR-2026-09912",
            "registered_at": (now - timedelta(minutes=15)).isoformat()
        },
        {
            "_id": "pat-sunita-004",
            "id": "pat-sunita-004",
            "full_name": "Sunita Verma",
            "age": 35,
            "gender": "Female",
            "phone": "+91 94220 20410",
            "address": "Quarter 18 DLW Colony, Varanasi, UP",
            "abha_id": "91-2041-9981-1120",
            "emergency_contact": "Praveen Verma (Husband): +91 94220 20411",
            "preferred_language": "mr",
            "department": "General Medicine OPD",
            "uhid": "UHID-VAR-2026-02041",
            "registered_at": (now - timedelta(minutes=90)).isoformat()
        }
    ]

    # 2. Demo Queue Tokens
    demo_queue = [
        {
            "token": "OPD-CARD-8842",
            "patient_id": "pat-rajesh-001",
            "patient_name": "Rajesh Kumar",
            "age": 48,
            "gender": "Male",
            "abha": "91-8842-1094-8812",
            "department": "Cardiology Special OPD",
            "doctor_assigned": "Dr. Ananya Sharma",
            "room_no": "Room 104 (Block A)",
            "chief_complaint": "Chest tightness & exertional dyspnea x 2 days",
            "status": "READY FOR DOCTOR",
            "kiosk_completion": "100% COMPLETE",
            "severity": 6.0,
            "red_flag": False,
            "wait_time_min": 8,
            "token_created_at": (now - timedelta(minutes=20)).isoformat()
        },
        {
            "token": "OPD-CARD-4109",
            "patient_id": "pat-savitri-002",
            "patient_name": "Savitri Devi",
            "age": 64,
            "gender": "Female",
            "abha": "91-4109-7721-0092",
            "department": "AYUSH Integrated OPD",
            "doctor_assigned": "Vaidya R. K. Shastri",
            "room_no": "Room 202 (AYUSH Wing)",
            "chief_complaint": "Sudden right-side joint swelling & severe knee pain",
            "status": "READY FOR DOCTOR",
            "kiosk_completion": "100% COMPLETE",
            "severity": 8.0,
            "red_flag": False,
            "wait_time_min": 12,
            "token_created_at": (now - timedelta(minutes=30)).isoformat()
        },
        {
            "token": "OPD-CARD-9912",
            "patient_id": "pat-aarav-003",
            "patient_name": "Aarav Sharma",
            "age": 12,
            "gender": "Male",
            "abha": "91-9912-3341-8810",
            "department": "General Medicine OPD",
            "doctor_assigned": "Dr. S. K. Mehta",
            "room_no": "Emergency Triage Cubicle 2",
            "chief_complaint": "Acute wheezing & severe respiratory stridor post-pollution",
            "status": "RED-FLAG TRIAGE",
            "kiosk_completion": "PRIORITY ESCALATED",
            "severity": 9.0,
            "red_flag": True,
            "wait_time_min": 0,
            "token_created_at": (now - timedelta(minutes=10)).isoformat()
        },
        {
            "token": "OPD-CARD-2041",
            "patient_id": "pat-sunita-004",
            "patient_name": "Sunita Verma",
            "age": 35,
            "gender": "Female",
            "abha": "91-2041-9981-1120",
            "department": "General Medicine OPD",
            "doctor_assigned": "Dr. S. K. Mehta",
            "room_no": "Room 108",
            "chief_complaint": "Continuous unilateral migraine with nausea & photophobia",
            "status": "WAITING IN QUEUE",
            "kiosk_completion": "100% COMPLETE",
            "severity": 5.0,
            "red_flag": False,
            "wait_time_min": 24,
            "token_created_at": (now - timedelta(minutes=40)).isoformat()
        }
    ]

    # 3. Demo Clinical Summaries
    demo_summaries = [
        {
            "_id": "sum-rajesh-001",
            "id": "sum-rajesh-001",
            "patient_id": "pat-rajesh-001",
            "token": "OPD-CARD-8842",
            "visit_date": now.strftime("%d-%b-%Y"),
            "department": "Cardiology Special OPD",
            "doctor": "Dr. Ananya Sharma",
            "patient_demographics": "Rajesh Kumar, 48/M, ABHA: 91-8842-1094-8812, UHID: UHID-VAR-2026-08842",
            "chief_complaint": "Chest tightness & exertional dyspnea x 2 days",
            "hpi": "48-year-old male presenting with gradual retrosternal chest heaviness for 2 days, severity 6/10 on exertion (climbing 1 flight of stairs), relieved by 5-10 minutes of resting. Mild shortness of breath present. No diaphoresis, syncope, or radiation to jaw/back.",
            "past_medical_history": "• Essential Hypertension (5 years, on Tab Amlodipine 5mg OD)\n• Type 2 Diabetes Mellitus (3 years, on Tab Metformin 500mg BD)\n• Appendectomy (2015, uncomplicated)",
            "drug_allergy": "• Current medications: Tab Amlodipine 5mg OD, Tab Metformin 500mg BD\n• Known allergy: Penicillin (urticarial rash)",
            "family_history": "Father had Myocardial Infarction at age 54 (deceased). Mother has Type 2 Diabetes.",
            "personal_history": "Non-smoker, occasional tea, mixed vegetarian diet, sedentary desk job, sleep 6 hrs/night.",
            "ros": "Cardiovascular: Positive exertional chest discomfort. Respiratory: Mild dyspnea on exertion. GI: Normal. CNS: No dizziness.",
            "prior_investigations": "• HbA1c: 7.8% (3 months ago, ⚠️ Elevated)\n• Lipid Profile: LDL 142 mg/dL, Total Cholesterol 218 mg/dL\n• Serum Creatinine: 1.1 mg/dL (Normal)\n• ECG (6 months ago): Normal sinus rhythm, no ST changes",
            "red_flags": "Exertional chest heaviness + DM + HTN + positive paternal early CAD history → HIGH CARDIOVASCULAR RISK",
            "drug_interactions": "No major contraindications between Amlodipine and Metformin. Monitor renal function if ACEi/ARB initiated.",
            "ai_confidence_score": 94,
            "status": "DRAFT_READY",
            "sections_accepted": {"chief_complaint": True, "hpi": True, "past_medical_history": True, "drug_allergy": True}
        }
    ]

    # 4. Demo Scanned Documents & OCR
    demo_docs = [
        {
            "id": "doc-scan-001",
            "patient_id": "pat-rajesh-001",
            "session_id": "ses-rajesh-001",
            "title": "Prescription - District Hospital Varanasi (Nov 2025)",
            "doc_type": "prescription",
            "image_url": "https://images.unsplash.com/photo-1584308666744-24d5c474f2ae?w=600",
            "ocr_text": "DISTRICT HOSPITAL VARANASI - OPD MEDICINE\nPt: Rajesh Kumar, 48/M. Date: 14/11/2025\nRx:\n1. Tab Amlodipine 5mg 1 tab OD morning x 30 days\n2. Tab Metformin 500mg 1 tab BD after food x 30 days\nAdv: Low salt diet, Fasting Blood Sugar, Lipid Profile test\nSd/- Dr. Sharma, MD",
            "confidence": 92.5,
            "entities": {
                "medications": ["Tab Amlodipine 5mg OD", "Tab Metformin 500mg BD"],
                "diagnoses": ["Essential Hypertension", "Type 2 Diabetes Mellitus"],
                "tests": ["Fasting Blood Sugar", "Lipid Profile"]
            },
            "uploaded_at": (now - timedelta(minutes=25)).isoformat()
        },
        {
            "id": "doc-scan-002",
            "patient_id": "pat-rajesh-001",
            "session_id": "ses-rajesh-001",
            "title": "Diagnostic Lab Report - Thyrocare / SRL (Dec 2025)",
            "doc_type": "lab_report",
            "image_url": "https://images.unsplash.com/photo-1579684385127-1ef15d508118?w=600",
            "ocr_text": "CENTRAL CLINICAL BIOCHEMISTRY REPORT\nHbA1c: 7.8 % (Ref: 4.0 - 5.6 %) [HIGH]\nSerum Creatinine: 1.1 mg/dL (Ref: 0.7 - 1.2 mg/dL) [NORMAL]\nTotal Cholesterol: 218 mg/dL (Ref: < 200 mg/dL) [ELEVATED]\nLDL Cholesterol: 142 mg/dL (Ref: < 100 mg/dL) [HIGH]\nTriglycerides: 180 mg/dL (Ref: < 150 mg/dL) [ELEVATED]",
            "confidence": 96.0,
            "entities": {
                "abnormal_labs": [
                    {"test": "HbA1c", "value": "7.8%", "status": "HIGH", "ref": "4.0 - 5.6%"},
                    {"test": "LDL Cholesterol", "value": "142 mg/dL", "status": "HIGH", "ref": "< 100 mg/dL"},
                    {"test": "Total Cholesterol", "value": "218 mg/dL", "status": "ELEVATED", "ref": "< 200 mg/dL"}
                ]
            },
            "uploaded_at": (now - timedelta(minutes=24)).isoformat()
        }
    ]

    # 5. Demo Medical Timeline
    demo_timeline = [
        {"patient_id": "pat-rajesh-001", "date": "14 Nov 2025", "type": "OPD Visit", "title": "Hypertension & Diabetes Followup", "details": "BP 138/88. Prescribed Amlodipine 5mg OD + Metformin 500mg BD.", "color": "#0284C7"},
        {"patient_id": "pat-rajesh-001", "date": "02 Dec 2025", "type": "Lab Report", "title": "Comprehensive Lipid & Glycemic Panel", "details": "HbA1c 7.8% (elevated), LDL 142 mg/dL (high), Creatinine 1.1 (normal).", "color": "#E11D48"},
        {"patient_id": "pat-rajesh-001", "date": "15 Jun 2024", "type": "Cardiology Screening", "title": "Annual Resting 12-Lead ECG", "details": "Normal sinus rhythm, heart rate 74/min, no ischemia or ST changes.", "color": "#059669"},
        {"patient_id": "pat-rajesh-001", "date": "10 Aug 2015", "type": "Surgery", "title": "Laparoscopic Appendectomy", "details": "Acute catarrhal appendicitis treated successfully. Uncomplicated recovery.", "color": "#7C3AED"}
    ]

    # 6. Demo Red Flag Alerts
    demo_alerts = [
        {
            "id": "ALT-RED-901",
            "kiosk_id": "Kiosk #04 (Ground Floor OPD)",
            "patient_name": "Aarav Sharma",
            "age": 12,
            "gender": "Male",
            "symptoms": "Acute wheezing, respiratory stridor, SpO2 89%",
            "flag_title": "ACUTE PEDIATRIC RESPIRATORY DISTRESS",
            "severity": "CRITICAL",
            "created_at": (now - timedelta(minutes=9)).isoformat(),
            "status": "NURSING ACKNOWLEDGED",
            "response_time_sec": 42,
            "action_taken": "Oxygen mask 4L/min initiated, nebulization scheduled"
        },
        {
            "id": "ALT-RED-882",
            "kiosk_id": "Kiosk #01 (Entrance Lobby)",
            "patient_name": "Ramlal Yadav",
            "age": 68,
            "gender": "Male",
            "symptoms": "Retrosternal crushing chest pain, diaphoresis, radiating to left arm",
            "flag_title": "SUSPECTED ACUTE CORONARY SYNDROME (STEMI)",
            "severity": "CRITICAL",
            "created_at": (now - timedelta(minutes=48)).isoformat(),
            "status": "RESOLVED",
            "response_time_sec": 35,
            "action_taken": "Immediate code blue transfer to Cath Lab / CCU"
        }
    ]

    # 7. Demo Kiosks
    demo_kiosks = [
        {"id": "KIOSK-01", "location": "Entrance Lobby A", "status": "ONLINE", "uptime": "99.8%", "sessions_today": 48, "avg_time_min": 7.4},
        {"id": "KIOSK-02", "location": "Medicine OPD Waiting", "status": "ONLINE", "uptime": "99.5%", "sessions_today": 56, "avg_time_min": 8.1},
        {"id": "KIOSK-03", "location": "AYUSH Integrated Wing", "status": "ONLINE", "uptime": "99.9%", "sessions_today": 32, "avg_time_min": 9.2},
        {"id": "KIOSK-04", "location": "Cardiology & Chest Clinic", "status": "ONLINE", "uptime": "99.2%", "sessions_today": 41, "avg_time_min": 7.8},
        {"id": "KIOSK-05", "location": "Pediatric & Maternal Wing", "status": "MAINTENANCE", "uptime": "94.2%", "sessions_today": 12, "avg_time_min": 6.5}
    ]

    # Insert into Mongo or memory
    if db is not None:
        try:
            for p in demo_patients:
                await db.medikiosk_patients.update_one({"id": p["id"]}, {"$set": p}, upsert=True)
            for q in demo_queue:
                await db.medikiosk_queue.update_one({"token": q["token"]}, {"$set": q}, upsert=True)
            for s in demo_summaries:
                await db.medikiosk_summaries.update_one({"id": s["id"]}, {"$set": s}, upsert=True)
            for d in demo_docs:
                await db.medikiosk_documents.update_one({"id": d["id"]}, {"$set": d}, upsert=True)
            for t in demo_timeline:
                await db.medikiosk_timeline.update_one({"patient_id": t["patient_id"], "date": t["date"]}, {"$set": t}, upsert=True)
            for a in demo_alerts:
                await db.medikiosk_triage_alerts.update_one({"id": a["id"]}, {"$set": a}, upsert=True)
            for k in demo_kiosks:
                await db.medikiosk_kiosks.update_one({"id": k["id"]}, {"$set": k}, upsert=True)
        except Exception:
            pass

    # Always populate in-memory store
    db_manager._in_memory_collections["medikiosk_patients"] = demo_patients
    db_manager._in_memory_collections["medikiosk_queue"] = demo_queue
    db_manager._in_memory_collections["medikiosk_summaries"] = demo_summaries
    db_manager._in_memory_collections["medikiosk_documents"] = demo_docs
    db_manager._in_memory_collections["medikiosk_triage_alerts"] = demo_alerts
    db_manager._in_memory_collections["medikiosk_kiosks"] = demo_kiosks


# =========================================================================
# 1. AUTHENTICATION & PATIENT IDENTIFICATION APIS (P1 - P3)
# =========================================================================

@router.post("/auth/abha/verify", summary="Verify 14-digit ABHA ID or mobile for instant Kiosk login")
async def verify_abha(req: AbhaVerifyRequest):
    await ensure_medikiosk_demo_data()
    clean_id = req.abha_id.strip()
    
    # Check if patient exists
    db = get_database()
    patient = None
    if db is not None:
        patient = await db.medikiosk_patients.find_one({"$or": [{"abha_id": clean_id}, {"phone": clean_id}]})
    
    if not patient:
        for p in db_manager._in_memory_collections["medikiosk_patients"]:
            if p.get("abha_id") == clean_id or p.get("phone") == clean_id or clean_id in p.get("abha_id", ""):
                patient = p
                break

    if patient:
        if "_id" in patient:
            patient["_id"] = str(patient["_id"])
        return {
            "verified": True,
            "status": "REGISTERED_PATIENT",
            "message": "ABHA Verified via ABDM Gateway M1 API",
            "patient": patient
        }
    
    # New ABHA mock profile auto-generated
    return {
        "verified": True,
        "status": "NEW_ABHA_PROFILE",
        "message": "Valid ABHA format. Creating pre-filled clinical profile.",
        "patient": {
            "id": f"pat-{uuid.uuid4().hex[:8]}",
            "abha_id": clean_id if len(clean_id) >= 14 else f"91-{clean_id[-4:]}-2026-9901",
            "full_name": "Om Prakash",
            "age": 52,
            "gender": "Male",
            "phone": "+91 98390 12345",
            "address": "Godowlia, Varanasi, UP",
            "department": "General Medicine OPD"
        }
    }


@router.post("/auth/aadhaar/verify", summary="Verify Aadhaar and issue ABHA ID")
async def verify_aadhaar(req: AadhaarVerifyRequest):
    await ensure_medikiosk_demo_data()
    return {
        "success": True,
        "verified": True,
        "aadhaar_masked": f"XXXXXXXX{req.aadhaar_number[-4:] if len(req.aadhaar_number) >= 4 else '9901'}",
        "linked_mobile": "+91 ******8842",
        "abha_id": f"91-{uuid.uuid4().hex[:4]}-4109-8812",
        "abha_number": f"91-{uuid.uuid4().hex[:4]}-4109-8812",
        "abha_address": f"user.{req.aadhaar_number[-4:]}@abdm",
        "message": "Aadhaar e-KYC verified via UIDAI. ABHA Card issued."
    }


@router.post("/patients/register", summary="Register new patient on Kiosk")
async def register_patient(req: PatientRegisterRequest):
    await ensure_medikiosk_demo_data()
    db = get_database()
    now_iso = datetime.now(timezone.utc).isoformat()
    new_id = f"pat-{uuid.uuid4().hex[:8]}"
    abha = req.abha_id or f"91-{uuid.uuid4().hex[:4]}-{req.phone[-4:]}-2026"
    uhid = f"UHID-VAR-{datetime.now().year}-{uuid.uuid4().hex[:5].upper()}"

    record = {
        "_id": new_id,
        "id": new_id,
        "full_name": req.full_name,
        "age": req.age,
        "gender": req.gender,
        "phone": req.phone,
        "address": req.address,
        "abha_id": abha,
        "uhid": uhid,
        "emergency_contact": req.emergency_contact,
        "preferred_language": req.preferred_language or "hi",
        "department": req.department or "General Medicine OPD",
        "registered_at": now_iso
    }

    if db is not None:
        await db.medikiosk_patients.insert_one(record)
    db_manager._in_memory_collections["medikiosk_patients"].append(record)

    # Automatically add to live queue
    token_num = f"OPD-{req.department[:4].upper()}-{len(db_manager._in_memory_collections['medikiosk_queue']) + 101}"
    q_entry = {
        "token": token_num,
        "patient_id": new_id,
        "patient_name": req.full_name,
        "age": req.age,
        "gender": req.gender,
        "abha": abha,
        "department": req.department,
        "doctor_assigned": "Dr. Ananya Sharma" if "Cardio" in req.department else "Dr. S. K. Mehta",
        "room_no": "Room 104" if "Cardio" in req.department else "Room 108",
        "chief_complaint": "Intake session initiated",
        "status": "INTAKE IN PROGRESS",
        "kiosk_completion": "REGISTERED",
        "severity": 4.0,
        "red_flag": False,
        "wait_time_min": 15,
        "token_created_at": now_iso
    }
    if db is not None:
        await db.medikiosk_queue.insert_one(q_entry)
    db_manager._in_memory_collections["medikiosk_queue"].append(q_entry)

    if "_id" in record:
        record["_id"] = str(record["_id"])
    return {
        "success": True,
        "patient": record,
        "queue_token": token_num,
        "message": f"Patient successfully registered with UHID: {uhid}"
    }


@router.get("/patients", summary="List all registered patients")
async def list_patients(limit: int = 50):
    await ensure_medikiosk_demo_data()
    db = get_database()
    if db is not None:
        cursor = db.medikiosk_patients.find({}).sort("registered_at", -1)
        res = await cursor.to_list(length=limit)
        for r in res:
            if "_id" in r:
                r["_id"] = str(r["_id"])
        if res:
            return res
    
    return db_manager._in_memory_collections["medikiosk_patients"][:limit]


@router.get("/patients/directory/live", summary="All Patients Directory & Real-time Status Tracker")
async def get_live_patients_directory(
    department: Optional[str] = None,
    status_filter: Optional[str] = None,
    search: Optional[str] = None
):
    await ensure_medikiosk_demo_data()
    patients = list(db_manager._in_memory_collections.get("medikiosk_patients", []))
    queue = list(db_manager._in_memory_collections.get("medikiosk_queue", []))
    alerts = list(db_manager._in_memory_collections.get("medikiosk_triage_alerts", []))
    vitals = list(db_manager._in_memory_collections.get("medikiosk_vitals", []))
    summaries = list(db_manager._in_memory_collections.get("medikiosk_summaries", []))
    prescriptions = list(db_manager._in_memory_collections.get("medikiosk_prescriptions", []))
    consents = list(db_manager._in_memory_collections.get("medikiosk_consents", []))
    
    # Map by patient_id or token or name
    queue_map = {q.get("patient_id"): q for q in queue if q.get("patient_id")}
    for q in queue:
        if q.get("patient_name"):
            queue_map[q["patient_name"].lower()] = q
            
    alerts_patient_ids = {a.get("patient_id") for a in alerts if a.get("status") != "RESOLVED"}
    vitals_map = {v.get("patient_id"): v for v in vitals if v.get("patient_id")}
    presc_map = {p.get("patient_id"): p for p in prescriptions if p.get("patient_id")}
    consent_pids = {c.get("patient_id") for c in consents if c.get("patient_id")}
    summary_pids = {s.get("patient_id") for s in summaries if s.get("patient_id")}

    enriched = []
    for idx, p in enumerate(patients):
        pid = p.get("id") or str(p.get("_id", ""))
        name = p.get("full_name") or p.get("name", "Unknown")
        q_item = queue_map.get(pid) or queue_map.get(name.lower()) or {}
        v_item = vitals_map.get(pid) or {}
        has_rx = pid in presc_map
        has_alert = pid in alerts_patient_ids or q_item.get("red_flag") is True
        
        # Determine status & journey step
        status = q_item.get("status", "INTAKE IN PROGRESS")
        if has_alert:
            status = "RED-FLAG TRIAGE"
            journey_step = 4
        elif has_rx:
            status = "COMPLETED / RX ISSUED"
            journey_step = 6
        elif status == "IN CONSULTATION":
            journey_step = 5
        elif status in ["READY FOR DOCTOR", "WAITING IN QUEUE"]:
            journey_step = 4
        elif pid in summary_pids:
            journey_step = 4
            status = "READY FOR DOCTOR"
        elif pid in consent_pids:
            journey_step = 3
            status = "INTAKE IN PROGRESS"
        else:
            journey_step = 2
            status = "INTAKE IN PROGRESS"

        dept = q_item.get("department") or p.get("department") or "General Medicine OPD"
        complaint = q_item.get("chief_complaint") or p.get("chief_complaint") or "General Consultation & Health Intake"
        token = q_item.get("token") or f"OPD-{dept[:4].upper()}-{101 + idx}"

        item = {
            "patient_id": pid,
            "full_name": name,
            "age": p.get("age", 45),
            "gender": p.get("gender", "Male"),
            "phone": p.get("phone", "+91 98000 00000"),
            "address": p.get("address", "Varanasi, UP"),
            "abha_id": p.get("abha_id") or p.get("abha") or "91-XXXX-XXXX-XXXX",
            "uhid": p.get("uhid") or f"UHID-VAR-2026-{1000 + idx}",
            "department": dept,
            "status": status,
            "journey_step": journey_step,
            "token": token,
            "doctor_assigned": q_item.get("doctor_assigned") or ("Dr. Ananya Sharma" if "Cardio" in dept else "Dr. S. K. Mehta"),
            "room_no": q_item.get("room_no") or ("Room 104" if "Cardio" in dept else "Room 108"),
            "chief_complaint": complaint,
            "severity": q_item.get("severity", 5.0),
            "red_flag": has_alert,
            "wait_time_min": q_item.get("wait_time_min", (idx + 1) * 6),
            "has_consent": pid in consent_pids or True,
            "has_vitals": bool(v_item),
            "vitals": v_item if v_item else {
                "blood_pressure": "130/84 mmHg",
                "heart_rate": 78,
                "spo2": "98%",
                "temperature_c": 37.0,
                "bmi": 24.2,
                "abnormal_flags": []
            },
            "prakriti": "Pitta-Kapha Pradhana" if idx % 2 == 0 else "Vata-Pitta Pradhana",
            "registered_at": p.get("registered_at") or datetime.now(timezone.utc).isoformat()
        }
        
        # Apply filters
        if department and department.lower() not in dept.lower():
            continue
        if status_filter and status_filter.upper() != "ALL":
            if status_filter.upper() not in status.upper():
                continue
        if search:
            s = search.lower()
            if (s not in name.lower() and 
                s not in pid.lower() and 
                s not in item["uhid"].lower() and 
                s not in token.lower() and 
                s not in complaint.lower()):
                continue

        enriched.append(item)

    # Compute overall statistics
    stats = {
        "total_patients": len(patients),
        "intake_in_progress": sum(1 for e in enriched if "INTAKE" in e["status"]),
        "ready_for_doctor": sum(1 for e in enriched if "READY" in e["status"] or "WAITING" in e["status"]),
        "in_consultation": sum(1 for e in enriched if "CONSULTATION" in e["status"]),
        "completed": sum(1 for e in enriched if "COMPLETED" in e["status"] or "RX" in e["status"]),
        "red_flags": sum(1 for e in enriched if e["red_flag"]),
        "avg_wait_min": 14.5
    }

    return {
        "success": True,
        "count": len(enriched),
        "stats": stats,
        "patients": enriched
    }


@router.get("/patients/{patient_id}", summary="Get patient profile by ID")
async def get_patient_profile(patient_id: str):
    await ensure_medikiosk_demo_data()
    db = get_database()
    pat = None
    if db is not None:
        pat = await db.medikiosk_patients.find_one({"id": patient_id})
    if not pat:
        pat = next((p for p in db_manager._in_memory_collections["medikiosk_patients"] if p["id"] == patient_id), None)
    
    if not pat:
        raise HTTPException(status_code=404, detail="Patient profile not found")
    
    if "_id" in pat:
        pat["_id"] = str(pat["_id"])
    return pat


# =========================================================================
# 2. SESSION & DPDPA CONSENT MANAGEMENT APIS (P4 - P5)
# =========================================================================

@router.post("/sessions/create", summary="Create new kiosk session")
async def create_kiosk_session(req: SessionCreateRequest):
    await ensure_medikiosk_demo_data()
    db = get_database()
    session_id = f"ses-{uuid.uuid4().hex[:8]}"
    now_iso = datetime.now(timezone.utc).isoformat()

    session_doc = {
        "_id": session_id,
        "id": session_id,
        "session_id": session_id,
        "patient_id": req.patient_id,
        "kiosk_id": req.kiosk_id or "KIOSK-04",
        "language": req.language or "hi",
        "department": req.department or "General Medicine OPD",
        "visit_type": req.visit_type or "walk_in",
        "current_step": "CONSENT", # CONSENT -> COMPLAINT -> SOCRATES -> AYUSH -> MEDS -> UPLOAD -> SUMMARY -> TOKEN
        "progress_pct": 10,
        "created_at": now_iso
    }

    if db is not None:
        await db.medikiosk_sessions.insert_one(session_doc)
    db_manager._in_memory_collections["medikiosk_sessions"].append(session_doc)

    if "_id" in session_doc:
        session_doc["_id"] = str(session_doc["_id"])
    return session_doc


@router.post("/consent/grant", summary="Record patient consent under DPDPA 2023 & generate ABDM Artifact")
async def grant_consent(req: ConsentGrantRequest):
    await ensure_medikiosk_demo_data()
    db = get_database()
    consent_id = f"CONSENT-{uuid.uuid4().hex[:8].upper()}"
    now_iso = datetime.now(timezone.utc).isoformat()
    expiry_iso = (datetime.now(timezone.utc) + timedelta(days=365)).isoformat()

    consent_artifact = {
        "consent_id": consent_id,
        "patient_id": req.patient_id,
        "session_id": req.session_id,
        "consent_types_granted": req.consent_types,
        "dpdpa_notice_version": "2023.2-IN",
        "purpose": "OPD Pre-Consultation AI Clinical Intake & Physician Review",
        "valid_until": expiry_iso,
        "status": "ACTIVE_GRANTED",
        "signature_verification": req.signature_data,
        "audio_consent_verified": req.audio_consent_verified,
        "abdm_fhir_consent_id": f"ABDM-CNST-{uuid.uuid4().hex[:6].upper()}",
        "created_at": now_iso
    }

    if db is not None:
        await db.medikiosk_consents.insert_one(consent_artifact)
    db_manager._in_memory_collections["medikiosk_consents"].append(consent_artifact)

    # Log in system audit trail
    audit_entry = {
        "timestamp": now_iso,
        "event": "DPDPA 2023 Consent Granted",
        "user_or_patient": req.patient_id,
        "details": f"Scopes: {', '.join(req.consent_types)}",
        "status": "CRYPTOGRAPHICALLY SIGNED"
    }
    db_manager._in_memory_collections["medikiosk_audit_logs"].append(audit_entry)

    if "_id" in consent_artifact:
        consent_artifact["_id"] = str(consent_artifact["_id"])
    return {
        "success": True,
        "consent": consent_artifact,
        "message": "DPDPA 2023 compliance consent recorded and synchronized with ABDM Consent Manager."
    }


@router.get("/consent/{patient_id}", summary="Get active consents for a patient")
async def get_patient_consents(patient_id: str):
    await ensure_medikiosk_demo_data()
    consents = [c for c in db_manager._in_memory_collections["medikiosk_consents"] if c.get("patient_id") == patient_id]
    return {
        "patient_id": patient_id,
        "active_consents": consents or [
            {
                "consent_id": "CONSENT-DEFAULT-01",
                "consent_types_granted": ["voice_recording", "ocr_scanning", "doctor_sharing", "abha_link"],
                "status": "ACTIVE_GRANTED",
                "valid_until": (datetime.now(timezone.utc) + timedelta(days=180)).isoformat()
            }
        ]
    }


# =========================================================================
# 3. CONVERSATIONAL HISTORY INTERVIEW & SOCRATES AI ENGINE (P6 - P8)
# =========================================================================

@router.post("/history/start", summary="Start conversational history interview (SOCRATES framework)")
async def start_history_interview(req: HistoryStartRequest):
    await ensure_medikiosk_demo_data()
    interview_id = f"intvw-{uuid.uuid4().hex[:8]}"
    
    # Choose branch based on body site or department
    site_key = "chest"
    if req.body_site:
        b_lower = req.body_site.lower()
        if "head" in b_lower: site_key = "head"
        elif "abdomen" in b_lower or "stomach" in b_lower: site_key = "abdomen"
        elif "respiratory" in b_lower or "breath" in b_lower or "cough" in b_lower: site_key = "respiratory"
    
    questions = SOCRATES_TREES.get(site_key, SOCRATES_TREES["chest"])
    first_q = questions[0]

    interview_state = {
        "id": interview_id,
        "session_id": req.session_id,
        "department": req.department,
        "mode": req.mode,
        "tree_category": site_key,
        "current_question_index": 0,
        "total_questions": len(questions),
        "answers": {},
        "red_flags_detected": [],
        "completed": False,
        "started_at": datetime.now(timezone.utc).isoformat()
    }

    db_manager._in_memory_collections["medikiosk_history_interviews"].append(interview_state)

    return {
        "interview_id": interview_id,
        "step": 1,
        "total_steps": len(questions),
        "category": site_key,
        "question": first_q,
        "message": "AI Clinical Dialogue Manager initialized. Ready for voice or touch input."
    }


@router.post("/history/respond", summary="Submit answer to current SOCRATES question")
async def respond_history_question(req: HistoryRespondRequest):
    await ensure_medikiosk_demo_data()
    interview = next((i for i in db_manager._in_memory_collections["medikiosk_history_interviews"] if i["id"] == req.interview_id), None)
    
    if not interview:
        # Auto-create if lost
        interview = {
            "id": req.interview_id,
            "session_id": "ses-auto",
            "tree_category": "chest",
            "current_question_index": 0,
            "answers": {},
            "red_flags_detected": [],
            "completed": False
        }
        db_manager._in_memory_collections["medikiosk_history_interviews"].append(interview)

    # Save answer
    interview["answers"][req.question_id] = req.answer_text
    curr_idx = interview.get("current_question_index", 0)
    questions = SOCRATES_TREES.get(interview.get("tree_category", "chest"), SOCRATES_TREES["chest"])

    # Check for Red-Flag combinations in response
    detected_red_flags = []
    combined_text = " ".join([str(v) for v in interview["answers"].values()] + [req.answer_text]).lower()
    
    for rule in RED_FLAG_PATTERNS:
        match_count = sum(1 for kw in rule["keywords"] if kw in combined_text)
        if match_count >= 2:
            detected_red_flags.append({
                "flag": rule["flag"],
                "severity": rule["severity"],
                "action": rule["action"],
                "timestamp": datetime.now(timezone.utc).isoformat()
            })

    interview["red_flags_detected"] = detected_red_flags
    next_idx = curr_idx + 1

    if next_idx < len(questions):
        interview["current_question_index"] = next_idx
        next_q = questions[next_idx]
        progress_pct = int((next_idx / len(questions)) * 100)
        
        return {
            "completed": False,
            "next_question": next_q,
            "progress_pct": progress_pct,
            "step": next_idx + 1,
            "total_steps": len(questions),
            "red_flags": detected_red_flags
        }
    else:
        interview["completed"] = True
        return {
            "completed": True,
            "message": "Conversational history interview completed. Summary draft ready.",
            "progress_pct": 100,
            "red_flags": detected_red_flags,
            "answers_summary": interview["answers"]
        }


@router.post("/history/skip", summary="Skip current clinical question")
async def skip_history_question(req: HistoryRespondRequest):
    return await respond_history_question(HistoryRespondRequest(
        interview_id=req.interview_id,
        question_id=req.question_id,
        answer_text="Skipped / Patient preferred not to specify",
        input_mode="touch"
    ))


@router.get("/history/progress", summary="Get interview progress & red flags")
async def get_history_progress(interview_id: str):
    await ensure_medikiosk_demo_data()
    interview = next((i for i in db_manager._in_memory_collections["medikiosk_history_interviews"] if i["id"] == interview_id), None)
    if not interview:
        return {"progress_pct": 75, "completed": False, "red_flags": []}
    
    return {
        "interview_id": interview["id"],
        "completed": interview.get("completed", False),
        "answers_count": len(interview.get("answers", {})),
        "red_flags": interview.get("red_flags_detected", [])
    }


# =========================================================================
# 4. AYUSH / AYURVEDIC ASSESSMENT APIS (P9 & D9)
# =========================================================================

@router.post("/ayush/prakriti/start", summary="Start Prakriti (Dosha Constitution) questionnaire")
async def start_prakriti_assessment(session_id: str):
    await ensure_medikiosk_demo_data()
    return {
        "assessment_id": f"PRAK-{uuid.uuid4().hex[:6].upper()}",
        "questions": [
            {"id": "p_body", "param": "Body Build", "options": [{"text": "Thin, prominent joints, light frame", "dosha": "vata"}, {"text": "Medium build, muscular, balanced", "dosha": "pitta"}, {"text": "Broad frame, heavy bones, tends to gain weight", "dosha": "kapha"}]},
            {"id": "p_skin", "param": "Skin Nature", "options": [{"text": "Dry, rough, cool to touch", "dosha": "vata"}, {"text": "Warm, prone to redness, moles/freckles", "dosha": "pitta"}, {"text": "Smooth, oily, cool, thick", "dosha": "kapha"}]},
            {"id": "p_appetite", "param": "Appetite & Digestion", "options": [{"text": "Variable, irregular, gas/bloating", "dosha": "vata"}, {"text": "Strong, intense, irritable if delayed", "dosha": "pitta"}, {"text": "Constant, slow digestion, heavy feeling", "dosha": "kapha"}]},
            {"id": "p_sleep", "param": "Sleep Pattern", "options": [{"text": "Light, interrupted, vivid dreams", "dosha": "vata"}, {"text": "Moderate, sound, dreams of heat/fire", "dosha": "pitta"}, {"text": "Deep, heavy, difficulty waking up", "dosha": "kapha"}]}
        ]
    }


@router.post("/ayush/dashavidha", summary="Save Dashavidha Pariksha (Full 10 Parameters) record")
async def save_dashavidha_assessment(req: DashavidhaSubmissionRequest):
    await ensure_medikiosk_demo_data()
    db = get_database()
    now_iso = datetime.now(timezone.utc).isoformat()
    record = {
        "patient_id": req.patient_id,
        "dashavidha_parameters": {
            "1. Prakriti (Constitution)": req.prakriti,
            "2. Vikriti (Current Imbalance)": req.vikriti,
            "3. Sara (Tissue Quality)": req.sara,
            "4. Samhanana (Body Build)": req.samhanana,
            "5. Pramana (Proportions)": req.pramana,
            "6. Satmya (Adaptability)": req.satmya,
            "7. Sattva (Mental Resilience)": req.sattva,
            "8. Ahara Shakti (Digestive Power)": req.ahara_shakti,
            "9. Vyayama Shakti (Physical Capacity)": req.vyayama_shakti,
            "10. Vaya (Chronological Stage)": req.vaya
        },
        "namaste_code": "KVT-04 (Hridroga / Vata-Kaphaja Hridroga)",
        "chikitsa_sutra": "Hridya Dravya Sevana, Deepana-Pachana, Vata Anulomana",
        "updated_at": now_iso
    }

    if db is not None:
        await db.medikiosk_dashavidha.update_one({"patient_id": req.patient_id}, {"$set": record}, upsert=True)
    
    return {
        "success": True,
        "message": "Dashavidha Pariksha synchronized with AYUSH Clinical Portal",
        "data": record
    }


@router.get("/ayush/dashavidha/{patient_id}", summary="Get Dashavidha Pariksha for a patient")
async def get_dashavidha(patient_id: str):
    await ensure_medikiosk_demo_data()
    return {
        "patient_id": patient_id,
        "prakriti_radar": {"vata": 25, "pitta": 45, "kapha": 30, "dominant": "Pitta-Kapha"},
        "vikriti_status": "Vata-Pitta Dushti (Cardiovascular & Joint Involvement)",
        "dashavidha": {
            "1. Prakriti (Constitution)": "Pitta-Kapha Pradhana",
            "2. Vikriti (Current Imbalance)": "Vata-Pitta Dushti",
            "3. Sara (Tissue Quality)": "Rakta-Mamsa Madhyama Sara",
            "4. Samhanana (Body Build)": "Madhyama Samhanana",
            "5. Pramana (Proportions)": "Anurupa Pramana",
            "6. Satmya (Adaptability)": "Sarva-Rasa Satmya",
            "7. Sattva (Mental Resilience)": "Madhyama Sattva",
            "8. Ahara Shakti (Digestive Power)": "Manda Agni",
            "9. Vyayama Shakti (Physical Capacity)": "Madhyama Vyayama Shakti",
            "10. Vaya (Chronological Stage)": "Madhyama Vaya (48 yrs)"
        },
        "ahara_vihara": {
            "diet": "Mixed vegetarian, frequent sour/spicy meals",
            "sleep": "6 hours, restless",
            "exercise": "Sedentary"
        }
    }


# =========================================================================
# 5. MEDICAL DOCUMENT DIGITIZATION & OCR APIS (P14, P15, D5)
# =========================================================================

@router.post("/documents/upload", summary="Upload medical document or prescription for OCR processing")
async def upload_document(
    patient_id: str = Query("pat-rajesh-001"),
    session_id: Optional[str] = Query("ses-01"),
    doc_type: str = Query("prescription"),
    file: UploadFile = File(...)
):
    await ensure_medikiosk_demo_data()
    doc_id = f"DOC-{uuid.uuid4().hex[:6].upper()}"
    now_iso = datetime.now(timezone.utc).isoformat()
    
    # Process simulated AI4Bharat / Google Cloud Vision OCR
    content_bytes = await file.read()
    filename = file.filename or "prescription_scan.jpg"
    
    # Realistic extraction based on filename or type
    extracted_text = (
        f"AI4Bharat Indic-Vision OCR Extraction [File: {filename}]\n"
        "CLINICAL PRESCRIPTION / LAB NOTE\n"
        f"Date: {datetime.now().strftime('%d/%m/%Y')}\n"
        "Diagnoses identified: Essential Hypertension, Dyslipidemia\n"
        "Medications extracted: Tab Amlodipine 5mg OD, Tab Atorvastatin 10mg HS\n"
        "Lab findings: Fasting Blood Sugar 118 mg/dL, Total Cholesterol 210 mg/dL"
    )

    doc_record = {
        "id": doc_id,
        "patient_id": patient_id,
        "session_id": session_id,
        "title": f"Scanned {doc_type.replace('_', ' ').title()}: {filename}",
        "doc_type": doc_type,
        "image_url": "https://images.unsplash.com/photo-1584308666744-24d5c474f2ae?w=600",
        "ocr_text": extracted_text,
        "confidence": 94.8,
        "entities": {
            "medications": ["Tab Amlodipine 5mg OD", "Tab Atorvastatin 10mg HS"],
            "diagnoses": ["Essential Hypertension", "Dyslipidemia"],
            "abnormal_labs": [{"test": "Fasting Blood Sugar", "value": "118 mg/dL", "status": "ELEVATED"}]
        },
        "uploaded_at": now_iso
    }

    db_manager._in_memory_collections["medikiosk_documents"].append(doc_record)
    
    return {
        "success": True,
        "document": doc_record,
        "message": "Document successfully digitized via OCR pipeline and entities extracted."
    }


@router.get("/documents/patient/{patient_id}", summary="Get all digitized documents for a patient")
async def get_patient_documents(patient_id: str):
    await ensure_medikiosk_demo_data()
    docs = [d for d in db_manager._in_memory_collections["medikiosk_documents"] if d.get("patient_id") == patient_id]
    if not docs:
        docs = db_manager._in_memory_collections["medikiosk_documents"]
    return docs


# =========================================================================
# 6. MEDICAL TIMELINE & CLINICAL INTELLIGENCE (B4, B5, D4)
# =========================================================================

@router.get("/timeline/{patient_id}", summary="Get chronological medical timeline")
async def get_patient_timeline(patient_id: str):
    await ensure_medikiosk_demo_data()
    events = [
        {"date": "20 Sep 2026", "type": "OPD Intake", "title": "MediKiosk Intake: Chest tightness (2 days)", "details": "SOCRATES interview completed, ESI-3 Priority assigned", "color": "#059669"},
        {"date": "14 Nov 2025", "type": "OPD Visit", "title": "Hypertension & Diabetes Followup", "details": "BP 138/88. Prescribed Amlodipine 5mg OD + Metformin 500mg BD.", "color": "#0284C7"},
        {"date": "02 Dec 2025", "type": "Lab Report", "title": "Comprehensive Lipid & Glycemic Panel", "details": "HbA1c 7.8% (elevated), LDL 142 mg/dL (high), Creatinine 1.1 (normal).", "color": "#E11D48"},
        {"date": "15 Jun 2024", "type": "Cardiology Screening", "title": "Annual Resting 12-Lead ECG", "details": "Normal sinus rhythm, heart rate 74/min, no acute ST changes.", "color": "#D97706"},
        {"date": "10 Aug 2015", "type": "Surgery", "title": "Laparoscopic Appendectomy", "details": "Catarrhal appendicitis treated successfully. Uncomplicated recovery.", "color": "#7C3AED"}
    ]
    return {"patient_id": patient_id, "timeline": events, "events": events}


@router.get("/lab-values/{patient_id}/trends", summary="Get trending lab values")
async def get_lab_trends(patient_id: str, test_name: str = "HbA1c"):
    return {
        "patient_id": patient_id,
        "test_name": test_name,
        "unit": "%" if test_name == "HbA1c" else "mg/dL",
        "reference_range": "4.0 - 5.6 %",
        "data_points": [
            {"date": "15 Mar 2024", "value": 7.1, "is_abnormal": True},
            {"date": "10 Oct 2024", "value": 7.4, "is_abnormal": True},
            {"date": "02 Dec 2025", "value": 7.8, "is_abnormal": True},
            {"date": "20 Sep 2026", "value": 8.2, "is_abnormal": True}
        ],
        "trends": [
            {"date": "15 Mar 2024", "value": 7.1, "is_abnormal": True},
            {"date": "10 Oct 2024", "value": 7.4, "is_abnormal": True},
            {"date": "02 Dec 2025", "value": 7.8, "is_abnormal": True},
            {"date": "20 Sep 2026", "value": 8.2, "is_abnormal": True}
        ],
        "interpretation": "Upward trajectory over 18 months indicates deteriorating glycemic control. Intensification of oral hypoglycemic agent indicated."
    }


@router.get("/medications/{patient_id}/interactions", summary="Check drug-drug interactions (DDI)")
async def check_drug_interactions(patient_id: str):
    alerts = [
        {
            "drug_pair": "Tab Metformin 500mg + Tab Telmisartan 40mg",
            "severity": "MODERATE",
            "warning": "Check serum creatinine and eGFR periodically. Mild increased risk of lactic acidosis in impaired renal function.",
            "color": "#D97706"
        },
        {
            "drug_pair": "Tab Amlodipine 5mg + Atorvastatin 20mg",
            "severity": "MINOR / BENEFICIAL",
            "warning": "Commonly co-prescribed in cardiovascular risk reduction. Monitor for muscle tenderness.",
            "color": "#059669"
        }
    ]
    return {
        "patient_id": patient_id,
        "has_interactions": True,
        "alerts": alerts,
        "interactions": alerts
    }


# =========================================================================
# 7. STRUCTURED CLINICAL SUMMARY GENERATOR (C1, C2, D3)
# =========================================================================

@router.get("/summary/{summary_id}", summary="Get structured physician clinical summary")
async def get_clinical_summary(summary_id: str):
    await ensure_medikiosk_demo_data()
    summaries = db_manager._in_memory_collections.get("medikiosk_summaries", [])
    summary = next((s for s in summaries if s.get("id") == summary_id or summary_id in s.get("id", "")), None)
    if not summary:
        if summaries:
            summary = summaries[0]
        else:
            summary = {
                "_id": summary_id,
                "id": summary_id,
                "patient_id": "P001",
                "patient_name": "Rajesh Kumar",
                "department": "Cardiology Special OPD",
                "chief_complaint": "Chest tightness & exertional dyspnea x 2 days",
                "hpi": "48-year-old male presenting with gradual retrosternal chest heaviness for 2 days.",
                "past_medical_history": "• Essential Hypertension (5 years, on Tab Amlodipine 5mg OD)\n• Type 2 Diabetes Mellitus (3 years, on Tab Metformin 500mg BD)",
                "drug_allergy": "Penicillin (urticarial rash)",
                "family_history": "Father had Myocardial Infarction at age 54. Mother has Type 2 Diabetes.",
                "personal_history": "Non-smoker, mixed vegetarian diet.",
                "ros": "Cardiovascular: Positive exertional discomfort. Respiratory: Mild dyspnea.",
                "status": "DRAFT_READY"
            }
            db_manager._in_memory_collections.setdefault("medikiosk_summaries", []).append(summary)
    return summary


@router.put("/summary/{summary_id}/edit", summary="Physician section-by-section edit of summary")
async def edit_summary_section(req: SummarySectionEditRequest):
    await ensure_medikiosk_demo_data()
    summaries = db_manager._in_memory_collections.get("medikiosk_summaries", [])
    summary = next((s for s in summaries if s.get("id") == req.summary_id or req.summary_id in s.get("id", "")), None)
    if not summary:
        if summaries:
            summary = summaries[0]
        else:
            summary = await get_clinical_summary(req.summary_id)
    
    summary[req.section] = req.updated_content
    if "sections_edited" not in summary:
        summary["sections_edited"] = []
    if req.section not in summary["sections_edited"]:
        summary["sections_edited"].append(req.section)
        
    return {
        "success": True,
        "message": f"Section '{req.section}' updated by attending physician.",
        "summary": summary
    }


@router.post("/summary/{summary_id}/accept", summary="Physician one-click commit and sign-off")
async def accept_clinical_summary(summary_id: str, doctor_name: Optional[str] = "Dr. Ananya Sharma"):
    await ensure_medikiosk_demo_data()
    now_iso = datetime.now(timezone.utc).isoformat()
    return {
        "success": True,
        "summary_id": summary_id,
        "status": "FINAL_COMMITTED",
        "digitally_signed_by": doctor_name,
        "signature_timestamp": now_iso,
        "abdm_fhir_composition_id": f"COMP-{uuid.uuid4().hex[:6].upper()}",
        "message": "Summary signed off and synchronized with Hospital HIS & ABDM Health Records."
    }


# =========================================================================
# 8. DOCTOR / PHYSICIAN EMR APIS (D1 - D10)
# =========================================================================

@router.get("/doctor/dashboard", summary="Physician dashboard overview")
async def get_doctor_dashboard():
    await ensure_medikiosk_demo_data()
    queue = db_manager._in_memory_collections["medikiosk_queue"]
    alerts = db_manager._in_memory_collections["medikiosk_triage_alerts"]
    
    return {
        "doctor_name": "Dr. Ananya Sharma",
        "department": "Cardiology Special OPD",
        "room_no": "Room 104",
        "stats": {
            "patients_waiting": len(queue),
            "kiosk_intakes_ready": sum(1 for q in queue if "READY" in q.get("status", "")),
            "emergency_red_flags": sum(1 for a in alerts if a.get("severity") == "CRITICAL" and a.get("status") != "RESOLVED"),
            "avg_time_per_patient_min": 3.8,
            "time_saved_via_kiosk_hrs": 2.4
        },
        "queue_preview": queue[:5]
    }


@router.get("/doctor/queue", summary="Fetch real-time OPD patient queue")
async def get_doctor_queue(department: Optional[str] = None):
    await ensure_medikiosk_demo_data()
    queue = db_manager._in_memory_collections["medikiosk_queue"]
    if department:
        return [q for q in queue if department.lower() in q.get("department", "").lower()]
    return queue


@router.post("/doctor/queue/{token}/call", summary="Call patient into consultation room")
async def call_patient(token: str):
    await ensure_medikiosk_demo_data()
    item = next((q for q in db_manager._in_memory_collections["medikiosk_queue"] if q["token"] == token), None)
    if item:
        item["status"] = "IN CONSULTATION"
    return {
        "success": True,
        "token": token,
        "message": f"Patient {item.get('patient_name', token) if item else token} called to Consultation Room 104. Kiosk bell & display triggered."
    }


@router.post("/doctor/notes", summary="Save physical examination notes & dictation")
async def save_doctor_exam_notes(req: DoctorExamNotesRequest):
    await ensure_medikiosk_demo_data()
    record = {
        "encounter_id": req.encounter_id,
        "patient_id": req.patient_id,
        "general_exam": req.general_exam,
        "systemic_cvs": req.systemic_cvs,
        "systemic_rs": req.systemic_rs,
        "systemic_abdomen": req.systemic_abdomen,
        "systemic_cns": req.systemic_cns,
        "dictation": req.dictation_text,
        "recorded_at": datetime.now(timezone.utc).isoformat()
    }
    return {
        "success": True,
        "notes": record,
        "message": "Physical examination findings & voice clinical notes recorded."
    }


@router.post("/doctor/prescription", summary="Generate Allopathic + AYUSH Parallel Dual-Prescription")
async def generate_dual_prescription(req: DualPrescriptionRequest):
    await ensure_medikiosk_demo_data()
    rx_id = f"RX-DUAL-{uuid.uuid4().hex[:6].upper()}"
    now_iso = datetime.now(timezone.utc).isoformat()
    
    rx_record = {
        "prescription_id": rx_id,
        "encounter_id": req.encounter_id,
        "patient_id": req.patient_id,
        "allopathic_lens": {
            "icd11_codes": ["BA80 (Angina Pectoris)", "BA00 (Essential Hypertension)"],
            "snomed_ct": ["194828000 (Angina Pectoris)", "38341003 (Hypertensive disorder)"],
            "medications": req.allopathic_medications
        },
        "ayush_lens": {
            "namaste_code": "KVT-04 (Hridroga)",
            "chikitsa_sutra": "Hridya Dravya Sevana, Deepana-Pachana",
            "ayush_medications": req.ayush_medications
        },
        "investigations": req.investigations_ordered,
        "lifestyle_advice": req.lifestyle_advice,
        "follow_up_days": req.follow_up_days,
        "issued_at": now_iso,
        "status": "AUTHORIZED"
    }

    db_manager._in_memory_collections["medikiosk_prescriptions"].append(rx_record)

    return {
        "success": True,
        "prescription": rx_record,
        "message": "Dual-Path Parallel Prescription successfully created and sent to Hospital Pharmacy."
    }


# =========================================================================
# 9. TRIAGE & NURSING EMERGENCY CONSOLE APIS (T1 - T5)
# =========================================================================

@router.get("/triage/alerts", summary="Fetch active red-flag emergency triage alerts")
async def get_triage_alerts():
    await ensure_medikiosk_demo_data()
    return db_manager._in_memory_collections["medikiosk_triage_alerts"]


@router.post("/triage/alerts/{alert_id}/acknowledge", summary="Nurse acknowledges emergency alert")
async def acknowledge_alert(alert_id: str, responder: Optional[str] = "Sister Incharge (OPD Triage)"):
    await ensure_medikiosk_demo_data()
    alert = next((a for a in db_manager._in_memory_collections["medikiosk_triage_alerts"] if a["id"] == alert_id), None)
    if alert:
        alert["status"] = "NURSING ACKNOWLEDGED"
        alert["responder"] = responder
        alert["acknowledged_at"] = datetime.now(timezone.utc).isoformat()
    return {
        "success": True,
        "alert_id": alert_id,
        "message": f"Alert acknowledged by {responder}. Stretcher / resuscitation team notified."
    }


@router.post("/triage/alerts/{alert_id}/resolve", summary="Resolve emergency alert")
async def resolve_alert(alert_id: str, action_taken: str = "Patient stabilized in emergency cubicle"):
    await ensure_medikiosk_demo_data()
    alert = next((a for a in db_manager._in_memory_collections["medikiosk_triage_alerts"] if a["id"] == alert_id), None)
    if alert:
        alert["status"] = "RESOLVED"
        alert["action_taken"] = action_taken
        alert["resolved_at"] = datetime.now(timezone.utc).isoformat()
    return {"success": True, "alert_id": alert_id, "message": "Emergency alert resolved."}


@router.post("/triage/vitals", summary="Record patient physiological vitals at triage station")
async def record_triage_vitals(req: TriageVitalsRequest):
    await ensure_medikiosk_demo_data()
    
    # Calculate BMI
    bmi = 0.0
    if req.height_cm > 0:
        h_m = req.height_cm / 100.0
        bmi = round(req.weight_kg / (h_m * h_m), 1)

    abnormals = []
    if req.blood_pressure_sys >= 140 or req.blood_pressure_dia >= 90:
        abnormals.append(f"Hypertensive Reading: {req.blood_pressure_sys}/{req.blood_pressure_dia} mmHg")
    if req.spo2_pct < 95:
        abnormals.append(f"Hypoxia Alert: SpO2 {req.spo2_pct}%")
    if req.heart_rate_bpm > 100:
        abnormals.append(f"Tachycardia: {req.heart_rate_bpm} bpm")

    record = {
        "patient_id": req.patient_id,
        "blood_pressure": f"{req.blood_pressure_sys}/{req.blood_pressure_dia} mmHg",
        "heart_rate": req.heart_rate_bpm,
        "temperature_c": req.temperature_c,
        "spo2": f"{req.spo2_pct}%",
        "respiratory_rate": req.respiratory_rate,
        "bmi": bmi,
        "abnormal_flags": abnormals,
        "recorded_at": datetime.now(timezone.utc).isoformat()
    }

    db_manager._in_memory_collections["medikiosk_vitals"].append(record)

    return {
        "success": True,
        "vitals": record,
        "message": f"Vitals recorded. BMI: {bmi} ({'Overweight' if bmi > 25 else 'Normal'}). Abnormals: {len(abnormals)}"
    }


@router.post("/triage/esi", summary="Assign ESI (Emergency Severity Index 1-5) score")
async def assign_esi_score(req: EsiScoringRequest):
    return {
        "success": True,
        "patient_id": req.patient_id,
        "esi_level": req.esi_level,
        "esi_title": {
            1: "Resuscitation (Immediate)",
            2: "Emergent (High Risk)",
            3: "Urgent (Multiple resources required)",
            4: "Less Urgent (One resource)",
            5: "Non-Urgent (Clinical advice)"
        }.get(req.esi_level, "Urgent"),
        "routing": req.routing_department,
        "notes": req.notes,
        "status": "PRIORITY_ROUTED"
    }


# =========================================================================
# 10. HOSPITAL ADMINISTRATOR & ANALYTICS APIS (A1 - A8)
# =========================================================================

@router.get("/admin/dashboard", summary="Hospital Administrator OPD operational metrics")
async def get_admin_dashboard():
    await ensure_medikiosk_demo_data()
    return {
        "hospital_name": "Varanasi District Super-Speciality Hospital",
        "daily_throughput_target": 2500,
        "patients_served_today": 1842,
        "active_kiosks": 4,
        "avg_kiosk_duration_min": 7.8,
        "avg_doctor_consult_time_min": 3.4,
        "total_time_saved_doctor_hours": 92.1,
        "overall_completion_rate_pct": 91.4,
        "kpis": {
            "total_patients_intake": 1842,
            "avg_intake_time_mins": 7.8,
            "physician_time_saved_hrs": 92.1,
            "throughput_increase_pct": 34.2
        },
        "department_load": [
            {"dept": "General Medicine OPD", "load_pct": 88, "status": "HEAVY LOAD", "avg_wait_min": 28},
            {"dept": "Cardiology Special OPD", "load_pct": 45, "status": "MODERATE", "avg_wait_min": 12},
            {"dept": "Orthopedics OPD", "load_pct": 22, "status": "LOW", "avg_wait_min": 8},
            {"dept": "AYUSH Integrated OPD", "load_pct": 15, "status": "OPTIMAL", "avg_wait_min": 5}
        ]
    }


@router.get("/admin/analytics", summary="Deep-dive analytics: complaints, languages & dropouts")
async def get_admin_analytics():
    return {
        "top_chief_complaints": [
            {"complaint": "Chest Pain & Palpitations", "count": 312, "pct": 28.4},
            {"complaint": "Joint Pain & Arthralgia", "count": 245, "pct": 22.3},
            {"complaint": "Cough & Breathlessness", "count": 204, "pct": 18.6},
            {"complaint": "Headache & Dizziness", "count": 178, "pct": 16.2},
            {"complaint": "Fever & Chills", "count": 159, "pct": 14.5}
        ],
        "language_distribution": [
            {"language": "Hindi (हिन्दी)", "users": 1102, "pct": 59.8},
            {"language": "Bhojpuri (भोजपुरी Dialect)", "users": 384, "pct": 20.8},
            {"language": "English", "users": 184, "pct": 10.0},
            {"language": "Bengali (বাংলা)", "users": 92, "pct": 5.0},
            {"language": "Marathi (मराठी)", "users": 80, "pct": 4.4}
        ],
        "dropout_funnel": [
            {"stage": "1. Language Selection", "completion_pct": 99.2},
            {"stage": "2. ABHA / Registration", "completion_pct": 96.4},
            {"stage": "3. SOCRATES Dialogue", "completion_pct": 92.1},
            {"stage": "4. Document Upload", "completion_pct": 88.5},
            {"stage": "5. Token Issued", "completion_pct": 87.2}
        ]
    }


@router.get("/admin/kiosks", summary="Fleet management of physical and tablet kiosks")
async def get_kiosk_fleet():
    await ensure_medikiosk_demo_data()
    return db_manager._in_memory_collections["medikiosk_kiosks"]


@router.post("/admin/kiosks/{kiosk_id}/restart", summary="Remote restart of kiosk terminal")
async def restart_kiosk(kiosk_id: str):
    return {
        "success": True,
        "kiosk_id": kiosk_id,
        "status": "REBOOT_SIGNAL_SENT",
        "message": f"Kiosk terminal {kiosk_id} reboot command queued via MQTT/Websocket daemon."
    }


@router.post("/admin/feedback", summary="Submit patient experience feedback")
async def submit_feedback(req: PatientFeedbackRequest):
    await ensure_medikiosk_demo_data()
    fb = {
        "session_id": req.session_id,
        "patient_name": req.patient_name,
        "rating": req.rating,
        "ease_of_use": req.ease_of_use,
        "language_satisfaction": req.language_satisfaction,
        "comments": req.comments,
        "submitted_at": datetime.now(timezone.utc).isoformat()
    }
    db_manager._in_memory_collections["medikiosk_feedbacks"].append(fb)
    return {"success": True, "message": "Thank you! Feedback recorded."}


@router.get("/admin/feedback", summary="List patient feedback & sentiment")
async def list_feedback():
    await ensure_medikiosk_demo_data()
    feedbacks = db_manager._in_memory_collections["medikiosk_feedbacks"]
    if not feedbacks:
        feedbacks = [
            {"patient_name": "Rajesh Kumar", "rating": 5, "ease_of_use": "Very Easy", "comments": "Speaking in Hindi was very helpful!", "submitted_at": "10 mins ago"},
            {"patient_name": "Savitri Devi", "rating": 5, "ease_of_use": "Smooth", "comments": "AYUSH questions were thoroughly covered.", "submitted_at": "35 mins ago"},
            {"patient_name": "Sunita Verma", "rating": 4, "ease_of_use": "Good", "comments": "Loved the instant token generation.", "submitted_at": "1 hr ago"}
        ]
    return {
        "average_rating": 4.8,
        "total_feedbacks": len(feedbacks),
        "sentiment": "95% POSITIVE",
        "feedbacks": feedbacks
    }


# =========================================================================
# 11. SYSTEM & IT ADMIN, EPHEMERAL PURGE & ABDM FHIR APIS (S1 - S7)
# =========================================================================

@router.get("/system/health", summary="MediKiosk microservices health check")
async def get_system_health():
    return {
        "status": "HEALTHY",
        "services": {
            "database_mongodb": "ONLINE (Connected)",
            "asr_speech_to_text": "ONLINE (AI4Bharat IndicASR / Bhashini active)",
            "tts_text_to_speech": "ONLINE (IndicTTS active)",
            "ocr_vision_engine": "ONLINE (Google Cloud Vision & Local Tesseract fallback)",
            "clinical_ontology": "ONLINE (SOCRATES + SNOMED CT + ICD-11 ontology active)",
            "abdm_gateway_m1_m2_m3": "ONLINE (HIP ID: IN-UP-VAR-MEDIKIOSK-01)",
            "fhir_r4_converter": "ONLINE (HL7 FHIR R4 Bundle validator passing)"
        },
        "metrics": {
            "api_p95_latency_ms": 148,
            "asr_latency_ms": 320,
            "ocr_latency_ms": 680,
            "llm_socrates_latency_ms": 420
        }
    }


@router.get("/system/audit-logs", summary="DPDPA 2023 Cryptographic Audit Trail")
async def get_audit_logs():
    await ensure_medikiosk_demo_data()
    logs = db_manager._in_memory_collections["medikiosk_audit_logs"]
    if not logs:
        logs = [
            {"timestamp": "14:40:12", "event": "FHIR R4 Bundle Created", "user_or_patient": "pat-rajesh-001", "details": "Encounter + Condition (BA80) + MedicationStatement", "status": "ABDM M3 VERIFIED"},
            {"timestamp": "14:38:05", "event": "Ephemeral Memory Sanitized", "user_or_patient": "SYSTEM_DAEMON", "details": "Scrubbed 4.2MB raw ASR audio & prescription scan", "status": "ZERO-PERSISTENCE PASS"},
            {"timestamp": "14:15:20", "event": "NIC e-Hospital HIS Sync", "user_or_patient": "pat-savitri-002", "details": "HL7 v2 Message ACK received from CDAC MedSys", "status": "HIS SYNC SUCCESS"},
            {"timestamp": "13:50:00", "event": "DPDPA Consent Granted", "user_or_patient": "pat-rajesh-001", "details": "Granular scopes: voice, ocr, doctor, abha", "status": "CRYPTOGRAPHICALLY SIGNED"}
        ]
    return logs


@router.post("/system/sanitizer/purge", summary="Zero-Persistence Memory Sanitizer (DPDPA mandate)")
async def purge_ephemeral_memory():
    now_iso = datetime.now(timezone.utc).isoformat()
    log_entry = {
        "timestamp": now_iso,
        "event": "Ephemeral Memory Sanitized",
        "user_or_patient": "MANUAL_PURGE_TRIGGER",
        "details": "Scrubbed volatile audio streams, raw camera cache, and OCR temp buffers.",
        "status": "ZERO-PERSISTENCE PASS"
    }
    db_manager._in_memory_collections["medikiosk_audit_logs"].append(log_entry)
    return {
        "success": True,
        "bytes_scrubbed_mb": 14.8,
        "audio_buffers_cleared": 18,
        "scanner_temp_files_deleted": 6,
        "status": "ZERO_PERSISTENCE_VERIFIED",
        "message": "All temporary biometric, audio, and scanner cache wiped in compliance with DPDPA 2023 statutory mandate."
    }


@router.get("/fhir/bundle/{patient_id}", summary="Generate full ABDM FHIR R4 Bundle")
async def generate_fhir_bundle(patient_id: str):
    await ensure_medikiosk_demo_data()
    bundle_id = f"urn:uuid:{uuid.uuid4()}"
    return {
        "resourceType": "Bundle",
        "id": bundle_id,
        "type": "document",
        "timestamp": datetime.now(timezone.utc).isoformat(),
        "meta": {
            "profile": ["https://nrces.in/ndhm/fhir/r4/StructureDefinition/ClinicalArtifact"]
        },
        "entry": [
            {
                "fullUrl": f"urn:uuid:{uuid.uuid4()}",
                "resource": {
                    "resourceType": "Patient",
                    "id": patient_id,
                    "identifier": [{"system": "https://healthid.ndhm.gov.in", "value": "91-8842-1094-8812"}],
                    "name": [{"text": "Rajesh Kumar"}],
                    "gender": "male",
                    "birthDate": "1978-05-12"
                }
            },
            {
                "fullUrl": f"urn:uuid:{uuid.uuid4()}",
                "resource": {
                    "resourceType": "Encounter",
                    "id": "enc-001",
                    "status": "finished",
                    "class": {"code": "AMB", "display": "ambulatory"},
                    "serviceType": {"coding": [{"system": "http://snomed.info/sct", "code": "310000008", "display": "Cardiology service"}]}
                }
            },
            {
                "fullUrl": f"urn:uuid:{uuid.uuid4()}",
                "resource": {
                    "resourceType": "Condition",
                    "id": "cond-001",
                    "clinicalStatus": {"coding": [{"code": "active"}]},
                    "code": {"coding": [{"system": "http://id.who.int/icd/release/11/mms", "code": "BA80", "display": "Angina Pectoris"}]}
                }
            },
            {
                "fullUrl": f"urn:uuid:{uuid.uuid4()}",
                "resource": {
                    "resourceType": "Composition",
                    "id": "comp-001",
                    "status": "final",
                    "title": "MediKiosk Pre-Consultation Clinical Intake Record",
                    "section": [
                        {"title": "Chief Complaint", "text": {"div": "<div>Chest tightness & exertional dyspnea (2 days)</div>"}},
                        {"title": "History of Present Illness", "text": {"div": "<div>Onset 2 days ago, worse on climbing stairs, relieved by rest.</div>"}},
                        {"title": "Past Medical History", "text": {"div": "<div>Essential Hypertension, Type 2 DM</div>"}}
                    ]
                }
            }
        ]
    }
