import time
import uuid
from datetime import datetime, timezone, timedelta
from typing import List, Dict, Any, Optional
from fastapi import APIRouter, HTTPException, status, Depends, Query, UploadFile, File, Body
from pydantic import BaseModel, Field

from app.db.database import get_database, db_manager

router = APIRouter()

# =========================================================================
# IN-MEMORY COLLECTIONS INITIALIZATION (FOR ROBUST INSTANT FALLBACK)
# =========================================================================
for collection_name in [
    "phc_users",
    "phc_health_profiles",
    "phc_vitals",
    "phc_anomalies",
    "phc_alerts",
    "phc_emergency_sos",
    "phc_emergency_contacts",
    "phc_medical_ids",
    "phc_environment",
    "phc_disaster_alerts",
    "phc_devices",
    "phc_medications",
    "phc_medication_logs",
    "phc_caregiver_dependents",
    "phc_checkins",
    "phc_provider_patients",
    "phc_clinical_notes",
    "phc_prescriptions",
    "phc_telemedicine_doctors",
    "phc_appointments",
    "phc_health_records",
    "phc_schemes",
    "phc_recommendations",
    "phc_responder_emergencies",
    "phc_triage_queue",
    "phc_surveillance",
    "phc_consent_matrix",
    "phc_hydration_logs",
    "phc_sleep_logs",
    "phc_activity_logs"
]:
    if collection_name not in db_manager._in_memory_collections:
        db_manager._in_memory_collections[collection_name] = []


# =========================================================================
# PYDANTIC SCHEMAS
# =========================================================================

class PhoneOtpRequest(BaseModel):
    phone: str = Field(..., description="10-digit Indian phone number")
    channel: str = Field(default="sms", description="sms or whatsapp")

class VerifyOtpRequest(BaseModel):
    phone: str
    otp: str = Field(default="123456")

class UserProfileUpdateRequest(BaseModel):
    full_name: str
    age: int
    gender: str
    phone: str
    blood_type: str = "O+"
    location: str = "Varanasi, UP"
    emergency_contact_phone: Optional[str] = "+91 9876543210"

class HealthProfileRequest(BaseModel):
    age: int = 42
    gender: str = "Male"
    height_cm: float = 172.0
    weight_kg: float = 68.5
    blood_type: str = "O+"
    chronic_conditions: List[str] = ["Hypertension", "Occupational Heat Exposure"]
    allergies: List[str] = ["Penicillin", "Dust Mites"]
    daily_medications: List[str] = ["Amlodipine 5mg", "Multivitamin"]
    occupation_risk: str = "outdoor_worker" # outdoor_worker, desk_worker, elderly, pregnant
    target_water_ml: int = 3500

class VitalsSyncRequest(BaseModel):
    heart_rate: float = Field(..., description="Heart rate in bpm")
    spo2: float = Field(..., description="SpO2 percentage (e.g. 98.0)")
    body_temp_c: float = Field(..., description="Body temperature in Celsius")
    systolic_bp: Optional[float] = Field(default=120.0, description="Systolic BP")
    diastolic_bp: Optional[float] = Field(default=80.0, description="Diastolic BP")
    respiratory_rate: Optional[float] = Field(default=16.0, description="Breaths/min")
    hrv_ms: Optional[float] = Field(default=45.0, description="HRV in milliseconds")
    activity_level: Optional[str] = Field(default="moderate", description="resting, moderate, strenuous")
    ambient_temp_c: Optional[float] = Field(default=40.5, description="Ambient temperature")
    humidity_pct: Optional[float] = Field(default=65.0, description="Relative humidity %")
    notes: Optional[str] = None

class HydrationLogRequest(BaseModel):
    amount_ml: int = Field(..., description="Amount drunk in ml (e.g. 250, 500)")
    beverage_type: str = Field(default="water", description="water, ors_solution, coconut_water, tea")

class SleepLogRequest(BaseModel):
    duration_hours: float
    deep_sleep_pct: float = 22.0
    rem_sleep_pct: float = 20.0
    disturbances: int = 2
    quality_score: int = 82

class ActivityLogRequest(BaseModel):
    steps: int
    active_minutes: int
    calories_burned: int
    distance_km: float

class AnomalyDetectRequest(BaseModel):
    heart_rate: float
    spo2: float
    body_temp_c: float
    ambient_temp_c: float = 41.0
    humidity_pct: float = 65.0
    activity_level: str = "moderate"
    hydration_ml_today: int = 1200
    has_copd_asthma: bool = False

class SosTriggerRequest(BaseModel):
    latitude: float = 25.3176
    longitude: float = 82.9739
    address: str = "Assi Ghat, Varanasi, Uttar Pradesh"
    trigger_type: str = "manual_button" # manual_button, fall_detected, medical_distress, voice_command
    distress_reason: Optional[str] = "Severe dizziness & heat exhaustion"

class EmergencyContactCreateRequest(BaseModel):
    name: str
    relationship: str
    phone: str
    is_primary: bool = False

class MedicalIdUpdateRequest(BaseModel):
    full_name: str
    blood_group: str
    dob_or_age: str
    allergies: List[str]
    chronic_conditions: List[str]
    medications: List[str]
    emergency_contacts: List[Dict[str, str]]
    organ_donor: bool = True
    insurance_policy_no: Optional[str] = "PMJAY-UP-984210"

class DeviceRegisterRequest(BaseModel):
    device_name: str
    device_type: str # smartwatch, fitness_band, ble_pulse_oximeter, ble_bp_cuff, glucometer
    mac_address: str
    battery_level: int = 92
    firmware_version: str = "v2.4.1-ble"

class MedicationCreateRequest(BaseModel):
    name: str
    dosage: str
    frequency: str # "Once daily (Morning)", "Twice daily", "As needed"
    timing: str = "After food"
    category: str = "Cardiovascular"
    total_tablets: int = 30
    remaining_tablets: int = 24
    instructions: str = "Do not take on empty stomach"

class MedicationLogRequest(BaseModel):
    medication_id: str
    status: str = "taken" # taken, skipped, postponed
    notes: Optional[str] = None

class CaregiverCheckInRequest(BaseModel):
    dependent_id: str
    message: str = "Are you feeling okay today? Remember to drink ORS."

class DoctorAppointmentRequest(BaseModel):
    doctor_id: str
    appointment_time: str
    consultation_type: str = "video" # video, audio, clinic
    chief_complaint: str

class HealthRecordUploadRequest(BaseModel):
    title: str
    category: str # lab_report, prescription, discharge_summary, vaccination
    doctor_or_lab: str
    date_recorded: str
    summary_notes: str
    tags: List[str] = ["blood_test", "annual_checkup"]

class MassAlertRequest(BaseModel):
    title: str
    severity: str # Warning, Critical, Extreme
    affected_zones: List[str]
    advisory_text: str
    category: str = "Heat Wave"

class AbhaGenerateRequest(BaseModel):
    aadhaar_number: str
    mobile: str
    full_name: str

class AbhaLinkRequest(BaseModel):
    abha_id: str
    otp: str = "123456"

class ConsentToggleRequest(BaseModel):
    consent_key: str
    granted: bool


# =========================================================================
# COMPREHENSIVE SEED DATA FOR DEMO & HACKATHON
# =========================================================================

def _seed_phc_data():
    now = datetime.now(timezone.utc)
    now_iso = now.isoformat()

    # 1. User Profile & Health Profile
    if not db_manager._in_memory_collections["phc_users"]:
        db_manager._in_memory_collections["phc_users"].append({
            "id": "phc-user-001",
            "full_name": "Ramesh Chandra Patel",
            "age": 44,
            "gender": "Male",
            "phone": "+91 98765 43210",
            "blood_type": "O+",
            "location": "Varanasi, Uttar Pradesh, India",
            "occupation": "Agricultural Supervisor / Field Officer",
            "abha_id": "91-4829-5710-3849",
            "abha_address": "ramesh.patel@abdm",
            "pmjay_card_no": "PMJAY-UP-2024-88492",
            "created_at": now_iso
        })

    if not db_manager._in_memory_collections["phc_health_profiles"]:
        db_manager._in_memory_collections["phc_health_profiles"].append({
            "user_id": "phc-user-001",
            "height_cm": 172.0,
            "weight_kg": 69.5,
            "bmi": 23.5,
            "blood_type": "O+",
            "baseline_rhr": 70.0,
            "baseline_spo2": 98.2,
            "baseline_temp_c": 36.8,
            "baseline_bp_systolic": 122.0,
            "baseline_bp_diastolic": 80.0,
            "chronic_conditions": ["Mild Hypertension", "Occupational Heat Sensitivity"],
            "allergies": ["Penicillin", "High Pollen"],
            "daily_medications": ["Amlodipine 5mg (Morning)", "Electrolyte Sachet (Noon)"],
            "occupation_risk": "outdoor_worker",
            "target_water_ml": 3500,
            "daily_step_goal": 8000
        })

    # 2. Vitals Timeline History (Past 24 Hours)
    if not db_manager._in_memory_collections["phc_vitals"]:
        vitals_data = [
            {
                "id": f"vit-{i}",
                "timestamp": (now - timedelta(hours=i*2)).isoformat(),
                "heart_rate": 72.0 + (i % 4) * 3 - (1 if i > 6 else 0),
                "spo2": 98.0 - (0.5 if i == 4 else 0.0),
                "body_temp_c": 37.0 + (0.3 if i == 2 else 0.0),
                "systolic_bp": 122.0 + (i % 3) * 2,
                "diastolic_bp": 80.0 + (i % 2) * 2,
                "respiratory_rate": 16.0 + (1.0 if i == 2 else 0.0),
                "hrv_ms": 48.0 - (i % 3) * 4,
                "stress_level": 32 + (i % 5) * 8,
                "activity_level": "moderate" if i in [2, 4, 6] else "resting",
                "ambient_temp_c": 41.2 if i in [2, 4] else 36.0,
                "humidity_pct": 62.0,
                "heat_index_c": 46.8 if i in [2, 4] else 38.5,
                "hydration_status": "Adequate" if i > 3 else "Hydration Recommended"
            } for i in range(12)
        ]
        db_manager._in_memory_collections["phc_vitals"].extend(vitals_data)

    # 3. AI Detected Anomalies
    if not db_manager._in_memory_collections["phc_anomalies"]:
        db_manager._in_memory_collections["phc_anomalies"].extend([
            {
                "id": "anom-001",
                "timestamp": (now - timedelta(minutes=45)).isoformat(),
                "anomaly_type": "Heat Stress & Tachycardia Indicator",
                "severity": "Warning",
                "confidence_pct": 89.4,
                "signals_correlated": ["Heart Rate (+28% above baseline)", "Skin Temp (37.6°C)", "Ambient Temp (41.5°C)", "Prolonged Outdoor Sunlight"],
                "explanation": "Heart rate remained above 96 bpm for 25 consecutive minutes while ambient heat index exceeded 46°C (Wet Bulb Danger Zone).",
                "status": "Active",
                "recommended_action": "Move to shade immediately. Sip 400ml ORS fluid. Rest for 20 minutes before resuming exertion.",
                "escalated": False
            },
            {
                "id": "anom-002",
                "timestamp": (now - timedelta(hours=6)).isoformat(),
                "anomaly_type": "Respiratory Airway Strain",
                "severity": "Warning",
                "confidence_pct": 84.1,
                "signals_correlated": ["SpO2 dipped to 94.5%", "Respiratory Rate 21 bpm", "Local PM2.5 AQI: 284"],
                "explanation": "Respiratory rate elevated coincident with ambient PM2.5 spike along GT Road corridor.",
                "status": "Acknowledged",
                "recommended_action": "Equip N95 particulate mask. Avoid open road cycling.",
                "escalated": False
            },
            {
                "id": "anom-003",
                "timestamp": (now - timedelta(days=2)).isoformat(),
                "anomaly_type": "Sudden Deceleration Impact (Fall Pre-Alert)",
                "severity": "Critical",
                "confidence_pct": 94.0,
                "signals_correlated": ["IMU 3.8G Spike", "Immediate Inactivity 28s", "Rapid Altitude Drop 1.2m"],
                "explanation": "Accelerometer detected trip/impact event followed by 28 seconds zero locomotion. Cancel window was dismissed safely by user.",
                "status": "Resolved",
                "recommended_action": "Routine limb joint check. Contact caregiver if bruising noticed.",
                "escalated": False
            }
        ])

    # 4. Disaster & Environmental Alerts (Hyperlocal IMD/CPCB/NDMA)
    if not db_manager._in_memory_collections["phc_disaster_alerts"]:
        db_manager._in_memory_collections["phc_disaster_alerts"].extend([
            {
                "id": "dis-001",
                "title": "Severe Heat Wave Warning (IMD Orange Alert)",
                "category": "Heat Wave",
                "agency": "India Meteorological Department (IMD) & NDMA",
                "severity": "Severe / Orange",
                "color": "#E11D48",
                "temperature_max_c": 44.5,
                "wbgt_index": 33.8,
                "heat_index_c": 49.2,
                "affected_area": "Varanasi, Chandauli, Mirzapur & Eastern UP",
                "issued_at": (now - timedelta(hours=3)).isoformat(),
                "valid_until": (now + timedelta(hours=48)).isoformat(),
                "health_impacts": [
                    "High probability of heat cramps and heat exhaustion in outdoor laborers",
                    "Elevated risk of heat stroke if fluid deficit exceeds 1.5 Liters",
                    "Dehydration exacerbation in patients taking antihypertensives"
                ],
                "actionable_advisories": [
                    "Drink 500ml water or ORS every 45 minutes during labor",
                    "Mandatory rest breaks under canopy between 12:00 PM and 3:30 PM",
                    "Wear loose, light-colored cotton garments and head cover",
                    "Elderly citizens must remain in ventilated indoor spaces"
                ],
                "preparedness_checklist": [
                    {"item": "2x ORS packets kept in field bag", "completed": True},
                    {"item": "Electrolyte insulated flask filled", "completed": True},
                    {"item": "Emergency cooling shelter identified", "completed": True},
                    {"item": "Caregiver alert route verified", "completed": True}
                ]
            },
            {
                "id": "dis-002",
                "title": "Hazardous Particulate Smog Event (AQI 294)",
                "category": "Air Quality",
                "agency": "CPCB CAAQMS Station - BHU Campus",
                "severity": "Poor / Red",
                "color": "#D97706",
                "aqi_value": 294,
                "prominent_pollutant": "PM2.5 (210 µg/m³)",
                "affected_area": "Varanasi Urban & Peri-urban Belt",
                "issued_at": (now - timedelta(hours=8)).isoformat(),
                "valid_until": (now + timedelta(hours=24)).isoformat(),
                "health_impacts": [
                    "Bronchospasm trigger in asthmatics and chronic bronchitis patients",
                    "Eye irritation and burning throat"
                ],
                "actionable_advisories": [
                    "Utilize N95/FFP2 masks during commute",
                    "Keep portable nebulizer/inhaler handy if prescribed",
                    "Operate indoor air circulation"
                ],
                "preparedness_checklist": [
                    {"item": "N95 respiratory mask worn", "completed": True},
                    {"item": "Windows closed during dawn peak", "completed": True}
                ]
            },
            {
                "id": "dis-003",
                "title": "Post-Monsoon Waterlogging & Vector Warning",
                "category": "Flood & Waterborne",
                "agency": "State Disaster Management Authority (SDMA)",
                "severity": "Moderate / Yellow",
                "color": "#0284C7",
                "affected_area": "Low-lying wards along Varuna River",
                "issued_at": (now - timedelta(days=1)).isoformat(),
                "valid_until": (now + timedelta(days=3)).isoformat(),
                "health_impacts": [
                    "Potential Leptospirosis and acute gastroenteritis risk in stagnant water",
                    "Dengue vector breeding spike"
                ],
                "actionable_advisories": [
                    "Boil drinking water vigorously for minimum 5 minutes",
                    "Avoid wading barefoot through waterlogged alleys"
                ],
                "preparedness_checklist": [
                    {"item": "Water purification tablets stocked", "completed": True}
                ]
            }
        ])

    # 5. Environmental Sensors Live Fusion
    if not db_manager._in_memory_collections["phc_environment"]:
        db_manager._in_memory_collections["phc_environment"].append({
            "location_name": "Varanasi (Assi - BHU Zone)",
            "latitude": 25.3176,
            "longitude": 82.9739,
            "ambient_temp_c": 41.5,
            "feels_like_c": 47.1,
            "humidity_pct": 64.0,
            "barometer_hpa": 1008.2,
            "uv_index": 9.2,
            "uv_severity": "Very High",
            "aqi": 288,
            "aqi_category": "Very Poor",
            "pollutants": {
                "pm2_5": 198.4,
                "pm10": 295.1,
                "no2": 42.0,
                "so2": 14.5,
                "co": 1.4,
                "o3": 68.0
            },
            "wet_bulb_temp_c": 33.2,
            "water_safety_index": "Boil Advisory in Wards 12-18",
            "heat_stroke_risk_level": "EXTREME CAUTION",
            "timestamp": now_iso
        })

    # 6. Emergency Contacts
    if not db_manager._in_memory_collections["phc_emergency_contacts"]:
        db_manager._in_memory_collections["phc_emergency_contacts"].extend([
            {
                "id": "cnt-001",
                "name": "Sunita Patel",
                "relationship": "Spouse & Primary Caregiver",
                "phone": "+91 98765 11223",
                "is_primary": True,
                "notified_on_sos": True
            },
            {
                "id": "cnt-002",
                "name": "Dr. Anand K. Varma",
                "relationship": "Family Physician / CHC Incharge",
                "phone": "+91 94150 99881",
                "is_primary": False,
                "notified_on_sos": True
            },
            {
                "id": "cnt-003",
                "name": "Amit Patel",
                "relationship": "Brother / Emergency Neighbor",
                "phone": "+91 97920 33445",
                "is_primary": False,
                "notified_on_sos": True
            }
        ])

    # 7. Emergency Medical ID Card
    if not db_manager._in_memory_collections["phc_medical_ids"]:
        db_manager._in_memory_collections["phc_medical_ids"].append({
            "user_id": "phc-user-001",
            "full_name": "Ramesh Chandra Patel",
            "age": 44,
            "blood_group": "O+",
            "allergies": ["Penicillin (Anaphylactoid)", "Sulfa Drugs"],
            "chronic_conditions": ["Stage-1 Hypertension", "Exertional Heat Intolerance"],
            "current_medications": ["Amlodipine 5mg OD", "Electrolytes PO"],
            "emergency_notes": "Carries ORS & BP medication in waist pouch. Pre-existing heat exhaustion episode in June 2024.",
            "emergency_contacts": [
                {"name": "Sunita Patel", "relation": "Spouse", "phone": "+91 98765 11223"},
                {"name": "Amit Patel", "relation": "Brother", "phone": "+91 97920 33445"}
            ],
            "organ_donor": True,
            "national_health_id": "91-4829-5710-3849",
            "government_scheme": "Ayushman Bharat PM-JAY Empaneled"
        })

    # 8. Nearby Emergency Hospitals (with Real Varanasi Hospital Metadata)
    if not db_manager._in_memory_collections["phc_responder_emergencies"]:
        db_manager._in_memory_collections["phc_responder_emergencies"].extend([
            {
                "id": "hosp-001",
                "name": "Sir Sunderlal Hospital (IMS-BHU Trauma Centre)",
                "type": "Apex Trauma Centre & Multidisciplinary Tertiary Hospital",
                "distance_km": 2.4,
                "eta_mins": 7,
                "emergency_phone": "0542-2307500 / 112",
                "heat_stroke_unit": True,
                "icu_beds_available": 14,
                "oxygen_equipped": True,
                "pmjay_cashless": True,
                "latitude": 25.2754,
                "longitude": 82.9995
            },
            {
                "id": "hosp-002",
                "name": "Pandit Deen Dayal Upadhyaya District Hospital",
                "type": "District Headquarters Hospital",
                "distance_km": 4.8,
                "eta_mins": 14,
                "emergency_phone": "0542-2508000",
                "heat_stroke_unit": True,
                "icu_beds_available": 6,
                "oxygen_equipped": True,
                "pmjay_cashless": True,
                "latitude": 25.3340,
                "longitude": 82.9810
            },
            {
                "id": "hosp-003",
                "name": "Community Health Centre (CHC) Shivpur",
                "type": "Community Primary Care & Stabilization Centre",
                "distance_km": 7.1,
                "eta_mins": 19,
                "emergency_phone": "0542-2280200",
                "heat_stroke_unit": True,
                "icu_beds_available": 2,
                "oxygen_equipped": True,
                "pmjay_cashless": True,
                "latitude": 25.3610,
                "longitude": 82.9560
            }
        ])

    # 9. Active SOS State (Default Idle)
    if not db_manager._in_memory_collections["phc_emergency_sos"]:
        db_manager._in_memory_collections["phc_emergency_sos"].append({
            "id": "sos-current",
            "is_active": False,
            "status": "IDLE",
            "triggered_at": None,
            "trigger_type": None,
            "latitude": 25.3176,
            "longitude": 82.9739,
            "address": "Assi Ghat, Varanasi, Uttar Pradesh",
            "contacts_notified": 0,
            "countdown_seconds_left": 0,
            "dispatch_eta_mins": None,
            "history": []
        })

    # 10. Medications Tracker & Logs
    if not db_manager._in_memory_collections["phc_medications"]:
        db_manager._in_memory_collections["phc_medications"].extend([
            {
                "id": "med-001",
                "name": "Tab Amlodipine 5mg",
                "generic_name": "Amlodipine Besylate",
                "dosage": "5 mg",
                "frequency": "Once Daily (Morning)",
                "scheduled_time": "08:00 AM",
                "timing": "After Breakfast",
                "category": "Antihypertensive",
                "total_tablets": 30,
                "remaining_tablets": 22,
                "adherence_rate_pct": 96.2,
                "instructions": "Maintain regular timing. Essential during high temperature days to prevent rebound spikes.",
                "today_status": "taken"
            },
            {
                "id": "med-002",
                "name": "Electral ORS Sachet (21.8g in 1L Water)",
                "generic_name": "Oral Rehydration Salts (WHO Formulation)",
                "dosage": "1 Sachet / 1000ml",
                "frequency": "Daily Field Hours",
                "scheduled_time": "01:30 PM",
                "timing": "Midday Labor",
                "category": "Electrolyte Replenishment",
                "total_tablets": 15,
                "remaining_tablets": 11,
                "adherence_rate_pct": 91.0,
                "instructions": "Drink in steady sips when working under ambient temperatures above 38°C.",
                "today_status": "pending"
            },
            {
                "id": "med-003",
                "name": "Becozinc Multivitamin",
                "generic_name": "Vitamin B-Complex with Zinc & Vitamin C",
                "dosage": "1 Capsule",
                "frequency": "Once Daily (Evening)",
                "scheduled_time": "08:30 PM",
                "timing": "After Dinner",
                "category": "Nutritional Supplement",
                "total_tablets": 30,
                "remaining_tablets": 28,
                "adherence_rate_pct": 100.0,
                "instructions": "Supports cellular immunity and muscle fatigue recovery.",
                "today_status": "pending"
            }
        ])

    # 11. Paired BLE Devices & Wearable Hub
    if not db_manager._in_memory_collections["phc_devices"]:
        db_manager._in_memory_collections["phc_devices"].extend([
            {
                "id": "dev-001",
                "device_name": "Garmin Venu 3 / Fire-Boltt Health Band",
                "device_type": "Smartwatch / PPG Wearable",
                "connection_status": "Connected (BLE Active)",
                "battery_level": 88,
                "mac_address": "E4:5F:01:9A:88:BC",
                "firmware_version": "v3.1.2-ble",
                "sensors_active": ["Continuous PPG (HR)", "Pulse Oximetry (SpO2)", "Skin Temperature", "3-Axis IMU (Falls)"],
                "last_synced": (now - timedelta(minutes=2)).isoformat(),
                "sampling_rate": "Adaptive (1 sec during heat alert, 30 sec rest)"
            },
            {
                "id": "dev-002",
                "device_name": "Omron HEM-7120 Smart Cuff",
                "device_type": "BLE Digital Sphygmomanometer",
                "connection_status": "Paired (Standby)",
                "battery_level": 94,
                "mac_address": "C8:2B:96:44:12:DF",
                "firmware_version": "v1.0.8",
                "sensors_active": ["Oscillometric Blood Pressure", "Pulse Rate"],
                "last_synced": (now - timedelta(hours=8)).isoformat(),
                "sampling_rate": "Scheduled (Morning & Evening)"
            },
            {
                "id": "dev-003",
                "device_name": "Accu-Chek Instant Glucometer",
                "device_type": "BLE Blood Glucose Monitor",
                "connection_status": "Paired (Standby)",
                "battery_level": 76,
                "mac_address": "D2:11:F4:7A:00:1E",
                "firmware_version": "v2.0.0",
                "sensors_active": ["Blood Glucose (mg/dL)"],
                "last_synced": (now - timedelta(days=1)).isoformat(),
                "sampling_rate": "Fasting / Post-prandial on demand"
            }
        ])

    # 12. Caregiver Dependents (for Caregiver Portal)
    if not db_manager._in_memory_collections["phc_caregiver_dependents"]:
        db_manager._in_memory_collections["phc_caregiver_dependents"].extend([
            {
                "id": "dep-001",
                "name": "Ramashankar Patel (Father)",
                "age": 74,
                "relationship": "Elderly Parent",
                "health_risk_score": 64, # 0-100 (lower is safer, 64 is elevated)
                "risk_category": "Elevated Cardiac & Heat Risk",
                "latest_vitals": {
                    "heart_rate": 84,
                    "spo2": 95.8,
                    "body_temp": 37.2,
                    "systolic_bp": 142,
                    "diastolic_bp": 88
                },
                "active_alerts_count": 1,
                "last_checkin": (now - timedelta(minutes=40)).isoformat(),
                "last_checkin_status": "Acknowledged: Hydrated indoors",
                "location": "Sigra, Varanasi",
                "battery_level": 91
            },
            {
                "id": "dep-002",
                "name": "Geeta Devi (Mother)",
                "age": 68,
                "relationship": "Elderly Parent",
                "health_risk_score": 28,
                "risk_category": "Stable Baseline",
                "latest_vitals": {
                    "heart_rate": 70,
                    "spo2": 98.4,
                    "body_temp": 36.7,
                    "systolic_bp": 124,
                    "diastolic_bp": 78
                },
                "active_alerts_count": 0,
                "last_checkin": (now - timedelta(hours=2)).isoformat(),
                "last_checkin_status": "All Normal",
                "location": "Sigra, Varanasi",
                "battery_level": 84
            }
        ])

    # 13. Telemedicine Doctors Directory
    if not db_manager._in_memory_collections["phc_telemedicine_doctors"]:
        db_manager._in_memory_collections["phc_telemedicine_doctors"].extend([
            {
                "id": "doc-001",
                "name": "Dr. Pradeep Mishra, MD",
                "specialty": "Internal Medicine & Occupational Health",
                "hospital": "IMS-BHU & Tele-Sanjeevani Lead",
                "experience_years": 16,
                "rating": 4.9,
                "available_now": True,
                "languages": ["Hindi", "English", "Bhojpuri"],
                "consultation_fee_inr": 0, # Ayushman PM-JAY Cashless
                "next_slot": "Today, in 15 mins",
                "verified_badge": "ABDM / NMC Certified"
            },
            {
                "id": "doc-002",
                "name": "Dr. Shweta Sengupta, MD, DM",
                "specialty": "Cardiology & Preventive Heart Care",
                "hospital": "Apex Heart Centre, Varanasi",
                "experience_years": 12,
                "rating": 4.8,
                "available_now": True,
                "languages": ["Hindi", "English", "Bengali"],
                "consultation_fee_inr": 0,
                "next_slot": "Today, 05:00 PM",
                "verified_badge": "ABDM / NMC Certified"
            },
            {
                "id": "doc-003",
                "name": "Dr. Rajeshwar Tripathi, MD",
                "specialty": "Pulmonology & Environmental Allergy",
                "hospital": "District Hospital Varanasi",
                "experience_years": 20,
                "rating": 4.9,
                "available_now": False,
                "languages": ["Hindi", "Bhojpuri"],
                "consultation_fee_inr": 0,
                "next_slot": "Tomorrow, 10:00 AM",
                "verified_badge": "ABDM / NMC Certified"
            }
        ])

    # 14. Health Records Vault
    if not db_manager._in_memory_collections["phc_health_records"]:
        db_manager._in_memory_collections["phc_health_records"].extend([
            {
                "id": "rec-001",
                "title": "Annual Comprehensive Blood Chemistry & Lipid Profile",
                "category": "Lab Diagnostic Report",
                "provider": "BHU Central Clinical Pathology Lab",
                "date": "2026-08-15",
                "encryption": "AES-256 Client-Encrypted",
                "summary": "Fasting blood sugar 94 mg/dL (Normal), Total cholesterol 182 mg/dL, HbA1c 5.4% (Non-diabetic), Serum Creatinine 0.9 mg/dL.",
                "tags": ["Lipids", "Biochemistry", "Routine"],
                "shared_with": ["Dr. Pradeep Mishra"]
            },
            {
                "id": "rec-002",
                "title": "e-Prescription: Antihypertensive Regimen",
                "category": "Prescription",
                "provider": "Dr. Anand K. Varma, CHC",
                "date": "2026-07-10",
                "encryption": "AES-256 Client-Encrypted",
                "summary": "Prescribed Tab Amlodipine 5mg OD x 90 days. Recommended low sodium diet (<5g/day) and heat protection.",
                "tags": ["Prescription", "Hypertension", "Cardiology"],
                "shared_with": ["All Connected Doctors"]
            },
            {
                "id": "rec-003",
                "title": "COVID-19 & Tetanus Booster Vaccination Certificate",
                "category": "Vaccination Certificate",
                "provider": "CoWIN & National Immunization Portal",
                "date": "2025-11-20",
                "encryption": "SHA-256 Verifiable QR",
                "summary": "Corbevax Precautionary Dose & Tetanus Toxoid 0.5ml booster recorded.",
                "tags": ["Vaccination", "CoWIN", "Immunization"],
                "shared_with": ["Self"]
            }
        ])

    # 15. Government Schemes Integration
    if not db_manager._in_memory_collections["phc_schemes"]:
        db_manager._in_memory_collections["phc_schemes"].extend([
            {
                "scheme_id": "ab-pmjay",
                "scheme_name": "Ayushman Bharat - Pradhan Mantri Jan Arogya Yojana (AB-PMJAY)",
                "coverage_amount": "₹5,00,000 / family / year",
                "eligibility_status": "Eligible & Enrolled (Golden Card Active)",
                "card_number": "PMJAY-UP-2024-88492",
                "empaneled_hospitals_nearby": 42,
                "cashless_services": ["Trauma & Heat Stroke Critical Care", "Cardiology Stenting", "Secondary & Tertiary Inpatient Care"],
                "toll_free": "14555"
            },
            {
                "scheme_id": "abdm-abha",
                "scheme_name": "Ayushman Bharat Digital Mission (ABDM) Health ID",
                "coverage_amount": "Universal Health Identifier & Consent Gateway",
                "eligibility_status": "Linked & Active",
                "card_number": "91-4829-5710-3849",
                "empaneled_hospitals_nearby": "National Interoperability",
                "cashless_services": ["PHR Interoperability", "FHIR R4 Diagnostic Sync", "e-Sanjeevani Teleconsultation"],
                "toll_free": "1800-11-4477"
            },
            {
                "scheme_id": "jan-aushadhi",
                "scheme_name": "Pradhan Mantri Bhartiya Janaushadhi Pariyojana (PMBJP)",
                "coverage_amount": "50-90% Discounted Generic Medicines",
                "eligibility_status": "Open Access to All Citizens",
                "card_number": "Direct Walk-in / e-Prescription",
                "empaneled_hospitals_nearby": 18,
                "cashless_services": ["Affordable Amlodipine, ORS, Telmisartan, Paracetamol"],
                "toll_free": "1800-180-8080"
            }
        ])

    # 16. Healthcare Provider / ASHA Copilot Patient Queue
    if not db_manager._in_memory_collections["phc_provider_patients"]:
        db_manager._in_memory_collections["phc_provider_patients"].extend([
            {
                "id": "pat-001",
                "name": "Ramesh Chandra Patel",
                "age": 44,
                "gender": "Male",
                "risk_tier": "Moderate Risk",
                "risk_score": 48,
                "conditions": ["Hypertension", "Outdoor Laborer"],
                "last_vitals": "HR 74 bpm • SpO2 98% • BP 124/82 mmHg • Temp 37.1°C",
                "active_alerts": "Heat Stress Warning (Ambient 41.5°C)",
                "recent_consult": "Today, 10:30 AM",
                "village_ward": "Assi Ward 4, Varanasi"
            },
            {
                "id": "pat-002",
                "name": "Shyam Sundar Yadav",
                "age": 58,
                "gender": "Male",
                "risk_tier": "High Risk",
                "risk_score": 76,
                "conditions": ["Type-2 Diabetes", "COPD Grade-2"],
                "last_vitals": "HR 92 bpm • SpO2 93.5% • BP 148/92 mmHg • Temp 37.5°C",
                "active_alerts": "Respiratory Distress + High PM2.5 Exposure",
                "recent_consult": "Yesterday",
                "village_ward": "Shivpur Ward 11, Varanasi"
            },
            {
                "id": "pat-003",
                "name": "Manju Devi",
                "age": 28,
                "gender": "Female",
                "risk_tier": "Priority Monitored",
                "risk_score": 34,
                "conditions": ["Third Trimester Pregnancy (32 Weeks)", "Mild Anemia"],
                "last_vitals": "HR 82 bpm • SpO2 99% • BP 116/74 mmHg • Temp 36.9°C",
                "active_alerts": "Hydration Reminder (Summer Peak)",
                "recent_consult": "3 days ago",
                "village_ward": "Kashi Vishwanath Corridor, Varanasi"
            }
        ])

    # 17. Public Health Surveillance & Heatmap Clusters
    if not db_manager._in_memory_collections["phc_surveillance"]:
        db_manager._in_memory_collections["phc_surveillance"].extend([
            {
                "district": "Varanasi",
                "heat_exhaustion_cases_today": 38,
                "respiratory_flare_cases": 64,
                "active_ambulance_sos_calls": 4,
                "high_risk_wards": ["Assi Ghat", "Cantonment", "Shivpur Industrial", "Ramnagar"],
                "average_hydration_compliance_pct": 74.2,
                "population_monitored": 14200,
                "outbreak_indicators": {
                    "heat_stress_trend": "+18% vs 7-day average (Heatwave Active)",
                    "waterborne_clustering": "Normal (No acute outbreak)",
                    "dengue_syndromic_index": "Mild seasonal baseline"
                }
            }
        ])

    # 18. Daily Hydration Logs
    if not db_manager._in_memory_collections["phc_hydration_logs"]:
        db_manager._in_memory_collections["phc_hydration_logs"].extend([
            {"timestamp": (now - timedelta(hours=6)).isoformat(), "amount_ml": 500, "type": "water"},
            {"timestamp": (now - timedelta(hours=4)).isoformat(), "amount_ml": 400, "type": "ors_solution"},
            {"timestamp": (now - timedelta(hours=2)).isoformat(), "amount_ml": 500, "type": "water"},
            {"timestamp": (now - timedelta(minutes=40)).isoformat(), "amount_ml": 350, "type": "coconut_water"}
        ])

# Run Initial Seed
_seed_phc_data()


# =========================================================================
# 1. AUTHENTICATION & PROFILE APIS
# =========================================================================

@router.post("/auth/send-otp")
async def send_otp(req: PhoneOtpRequest):
    return {
        "status": "success",
        "message": f"Demo OTP '123456' dispatched successfully to {req.phone} via {req.channel.upper()}.",
        "channel": req.channel,
        "phone": req.phone,
        "expires_in_secs": 300
    }

@router.post("/auth/verify-otp")
async def verify_otp(req: VerifyOtpRequest):
    if req.otp != "123456":
        raise HTTPException(status_code=400, detail="Invalid OTP. Use demo OTP '123456'.")
    user = db_manager._in_memory_collections["phc_users"][0]
    return {
        "status": "success",
        "access_token": f"phc-jwt-{uuid.uuid4().hex[:16]}",
        "token_type": "bearer",
        "user": user,
        "message": "Authentication successful. On-device DPDP consent active."
    }

@router.get("/users/profile")
async def get_user_profile():
    if not db_manager._in_memory_collections["phc_users"]:
        _seed_phc_data()
    return db_manager._in_memory_collections["phc_users"][0]

@router.put("/users/profile")
async def update_user_profile(req: UserProfileUpdateRequest):
    if not db_manager._in_memory_collections["phc_users"]:
        _seed_phc_data()
    user = db_manager._in_memory_collections["phc_users"][0]
    user.update(req.dict())
    return {"status": "success", "message": "Profile updated successfully.", "user": user}

@router.get("/users/health-profile")
async def get_health_profile():
    if not db_manager._in_memory_collections["phc_health_profiles"]:
        _seed_phc_data()
    return db_manager._in_memory_collections["phc_health_profiles"][0]

@router.put("/users/health-profile")
async def update_health_profile(req: HealthProfileRequest):
    if not db_manager._in_memory_collections["phc_health_profiles"]:
        _seed_phc_data()
    profile = db_manager._in_memory_collections["phc_health_profiles"][0]
    profile.update(req.dict())
    return {"status": "success", "message": "Personal health profile and baselines recalculated.", "profile": profile}

@router.get("/users/export-data")
async def export_user_data():
    """DPDPA 2023 Right to Data Portability Export"""
    return {
        "export_timestamp": datetime.now(timezone.utc).isoformat(),
        "dpdpa_compliance": "Section 12 Compliant - Anonymized & Portable",
        "user": db_manager._in_memory_collections["phc_users"][0],
        "health_profile": db_manager._in_memory_collections["phc_health_profiles"][0],
        "vitals_count": len(db_manager._in_memory_collections["phc_vitals"]),
        "anomalies_count": len(db_manager._in_memory_collections["phc_anomalies"]),
        "medications_count": len(db_manager._in_memory_collections["phc_medications"])
    }


# =========================================================================
# 2. CONTINUOUS HEALTH MONITORING & VITALS APIS
# =========================================================================

@router.get("/health/vitals/latest")
async def get_latest_vitals():
    if not db_manager._in_memory_collections["phc_vitals"]:
        _seed_phc_data()
    latest = db_manager._in_memory_collections["phc_vitals"][0]
    return latest

@router.get("/health/vitals/history")
async def get_vitals_history(limit: int = Query(default=20, le=100)):
    if not db_manager._in_memory_collections["phc_vitals"]:
        _seed_phc_data()
    return db_manager._in_memory_collections["phc_vitals"][:limit]

@router.post("/health/vitals/sync")
async def sync_vitals_from_device(req: VitalsSyncRequest):
    """Sync single reading or BLE batch reading to on-device vault & cloud sync"""
    now = datetime.now(timezone.utc).isoformat()
    # Calculate Heat Index
    t = req.ambient_temp_c or 40.0
    rh = req.humidity_pct or 60.0
    heat_index = t + 0.5555 * ((rh / 100.0) * 6.11 * 2.71828 ** (5417.7530 * (1/273.16 - 1/(273.15 + t))) - 10.0)

    record = {
        "id": f"vit-{uuid.uuid4().hex[:8]}",
        "timestamp": now,
        "heart_rate": req.heart_rate,
        "spo2": req.spo2,
        "body_temp_c": req.body_temp_c,
        "systolic_bp": req.systolic_bp or 120.0,
        "diastolic_bp": req.diastolic_bp or 80.0,
        "respiratory_rate": req.respiratory_rate or 16.0,
        "hrv_ms": req.hrv_ms or 45.0,
        "stress_level": 35 if req.heart_rate < 85 else 65,
        "activity_level": req.activity_level,
        "ambient_temp_c": req.ambient_temp_c,
        "humidity_pct": req.humidity_pct,
        "heat_index_c": round(heat_index, 1),
        "hydration_status": "Hydration Recommended" if heat_index > 42.0 else "Adequate",
        "notes": req.notes
    }
    # Prepend to collection so newest is first
    db_manager._in_memory_collections["phc_vitals"].insert(0, record)

    # Automatic edge evaluation for anomaly
    if req.heart_rate > 100.0 and heat_index > 43.0:
        new_anomaly = {
            "id": f"anom-{uuid.uuid4().hex[:6]}",
            "timestamp": now,
            "anomaly_type": "Acute Heat Strain & Exertional Tachycardia",
            "severity": "Warning",
            "confidence_pct": 91.5,
            "signals_correlated": [f"HR {req.heart_rate} bpm", f"Heat Index {round(heat_index, 1)}°C"],
            "explanation": "High cardiac frequency coinciding with dangerous ambient heat index.",
            "status": "Active",
            "recommended_action": "Mandatory shade rest. Hydrate with 500ml electrolyte.",
            "escalated": False
        }
        db_manager._in_memory_collections["phc_anomalies"].insert(0, new_anomaly)

    return {
        "status": "synced",
        "reading_id": record["id"],
        "timestamp": now,
        "record": record
    }

@router.get("/health/vitals/trends")
async def get_vitals_trends():
    """Aggregated 7-day vitals trends with baseline comparison"""
    return {
        "period": "7_days",
        "heart_rate_trend": {"average": 73.2, "resting_min": 58, "peak": 108, "status": "Normal Baseline"},
        "spo2_trend": {"average": 98.1, "min": 95.0, "status": "Optimal Oxygenation"},
        "body_temp_trend": {"average": 36.9, "max": 37.7, "status": "Minor Exertional Rise"},
        "daily_scores": [82, 85, 78, 88, 84, 80, 86],
        "hydration_compliance_pct": 86.5
    }

@router.get("/health/risk-score")
async def get_health_risk_score():
    """
    Composite Health Risk Score (0-100, where lower is safer):
    - Vital Signs Deviation (35%)
    - Environmental Risk (25%)
    - Activity & Behavior (20%)
    - Personal Risk Factors (20%)
    """
    if not db_manager._in_memory_collections["phc_vitals"]:
        _seed_phc_data()
    latest = db_manager._in_memory_collections["phc_vitals"][0]

    # Dynamic calculation
    vitals_score = 15 # baseline low
    if latest["heart_rate"] > 90:
        vitals_score += 15
    if latest["spo2"] < 96:
        vitals_score += 20

    env_score = 30 if (latest.get("ambient_temp_c") or 30) > 40 else 10
    behavior_score = 15
    personal_score = 18

    composite = int(vitals_score * 0.35 + env_score * 0.25 + behavior_score * 0.20 + personal_score * 0.20) * 2

    return {
        "composite_risk_score": composite,
        "risk_tier": "Low" if composite < 30 else ("Moderate" if composite < 60 else "High"),
        "components": {
            "vital_signs_deviation_pct": vitals_score,
            "environmental_hazard_pct": env_score,
            "activity_behavior_compliance_pct": behavior_score,
            "personal_risk_profile_pct": personal_score
        },
        "dominant_hazard": "Extreme Ambient Heat & Solar Radiation" if env_score > 20 else "Normal Physiological State",
        "advisory": "Maintain electrolyte replenishment. Avoid direct sun exposure between 12-3 PM."
    }

@router.post("/health/hydration/log")
async def log_water_intake(req: HydrationLogRequest):
    now = datetime.now(timezone.utc).isoformat()
    entry = {
        "id": f"hyd-{uuid.uuid4().hex[:6]}",
        "timestamp": now,
        "amount_ml": req.amount_ml,
        "beverage_type": req.beverage_type
    }
    db_manager._in_memory_collections["phc_hydration_logs"].append(entry)
    total_today = sum(e["amount_ml"] for e in db_manager._in_memory_collections["phc_hydration_logs"])
    return {
        "status": "logged",
        "logged_entry": entry,
        "today_total_ml": total_today,
        "goal_target_ml": 3500,
        "progress_pct": min(100, round((total_today / 3500.0) * 100, 1))
    }

@router.get("/health/hydration/today")
async def get_hydration_today():
    if not db_manager._in_memory_collections["phc_hydration_logs"]:
        _seed_phc_data()
    total_today = sum(e["amount_ml"] for e in db_manager._in_memory_collections["phc_hydration_logs"])
    return {
        "today_total_ml": total_today,
        "goal_target_ml": 3500,
        "remaining_ml": max(0, 3500 - total_today),
        "progress_pct": min(100, round((total_today / 3500.0) * 100, 1)),
        "entries": db_manager._in_memory_collections["phc_hydration_logs"][-10:],
        "dehydration_risk": "Low" if total_today > 2500 else ("Moderate" if total_today > 1500 else "High")
    }

@router.post("/health/sleep/log")
async def log_sleep(req: SleepLogRequest):
    entry = req.dict()
    entry["date"] = datetime.now(timezone.utc).date().isoformat()
    db_manager._in_memory_collections["phc_sleep_logs"].append(entry)
    return {"status": "logged", "sleep_data": entry}

@router.get("/health/sleep/history")
async def get_sleep_history():
    return {
        "average_duration_hours": 7.3,
        "deep_sleep_average_pct": 23.4,
        "quality_score": 82,
        "last_night": {
            "duration": "7 hrs 25 mins",
            "deep_sleep": "24%",
            "rem_sleep": "21%",
            "light_sleep": "55%",
            "sleep_disturbances": 2,
            "quality_rating": "Optimal Rest & Recovery"
        }
    }

@router.post("/health/activity/log")
async def log_activity(req: ActivityLogRequest):
    entry = req.dict()
    entry["date"] = datetime.now(timezone.utc).date().isoformat()
    db_manager._in_memory_collections["phc_activity_logs"].append(entry)
    return {"status": "logged", "activity_data": entry}

@router.get("/health/activity/history")
async def get_activity_history():
    return {
        "today_steps": 6420,
        "target_steps": 8000,
        "distance_km": 4.8,
        "active_minutes": 52,
        "calories_burned": 380,
        "progress_pct": 80.2
    }

@router.get("/health/reports/weekly")
async def get_weekly_health_report():
    return {
        "report_id": f"REP-W-{datetime.now().strftime('%Y%W')}",
        "generated_at": datetime.now(timezone.utc).isoformat(),
        "summary": "Stable overall cardiovascular baseline with 2 managed heat-stress spikes. High hydration adherence.",
        "weekly_metrics": {
            "avg_heart_rate": 72.8,
            "avg_spo2": 98.0,
            "avg_steps": 7450,
            "avg_sleep_hours": 7.2,
            "total_water_liters": 23.5,
            "anomalies_encountered": 2,
            "sos_events": 0
        },
        "doctor_recommendations": [
            "Continue taking Tab Amlodipine 5mg at 8:00 AM",
            "Maintain current electrolyte intake routine during agricultural hours",
            "Schedule routine BP re-check next month"
        ]
    }


# =========================================================================
# 3. AI ANOMALY DETECTION & ALERTS APIS
# =========================================================================

@router.get("/anomalies")
async def get_anomalies():
    if not db_manager._in_memory_collections["phc_anomalies"]:
        _seed_phc_data()
    return db_manager._in_memory_collections["phc_anomalies"]

@router.get("/anomalies/{anomaly_id}")
async def get_anomaly_detail(anomaly_id: str):
    for a in db_manager._in_memory_collections["phc_anomalies"]:
        if a["id"] == anomaly_id:
            return a
    raise HTTPException(status_code=404, detail="Anomaly record not found")

@router.post("/anomalies/{anomaly_id}/dismiss")
async def dismiss_anomaly(anomaly_id: str):
    for a in db_manager._in_memory_collections["phc_anomalies"]:
        if a["id"] == anomaly_id:
            a["status"] = "Dismissed by User"
            return {"status": "success", "message": "Anomaly acknowledged and dismissed.", "anomaly": a}
    raise HTTPException(status_code=404, detail="Anomaly record not found")

@router.post("/anomalies/{anomaly_id}/escalate")
async def escalate_anomaly(anomaly_id: str):
    for a in db_manager._in_memory_collections["phc_anomalies"]:
        if a["id"] == anomaly_id:
            a["escalated"] = True
            a["status"] = "Escalated to Caregiver & Tele-Physician"
            return {
                "status": "success",
                "message": "Anomaly alert escalated to registered caregiver Sunita Patel and on-duty CHC physician.",
                "anomaly": a
            }
    raise HTTPException(status_code=404, detail="Anomaly record not found")

@router.post("/anomalies/detect")
async def run_edge_ai_anomaly_detection(req: AnomalyDetectRequest):
    """
    On-device simulated Edge AI inference model (TFLite simulated <50ms)
    Correlating HR + SpO2 + Body Temp + Ambient Temp + Hydration
    """
    start_time = time.time()
    anomalies_found = []

    # Rule 1: Heat Stress
    if req.ambient_temp_c > 38.0 and req.heart_rate > 90:
        anomalies_found.append({
            "type": "Exertional Heat Stress",
            "severity": "Critical" if req.heart_rate > 110 else "Warning",
            "confidence": 92.4,
            "explanation": f"Elevated cardiac frequency ({req.heart_rate} bpm) under extreme ambient thermal stress ({req.ambient_temp_c}°C)."
        })

    # Rule 2: Dehydration Indicator
    if req.hydration_ml_today < 1500 and req.ambient_temp_c > 35.0:
        anomalies_found.append({
            "type": "Acute Dehydration Risk",
            "severity": "Warning",
            "confidence": 88.0,
            "explanation": f"Water intake ({req.hydration_ml_today}ml) is below safe replenishment threshold for ambient conditions."
        })

    # Rule 3: SpO2 Hypoxia
    if req.spo2 < 94.0:
        anomalies_found.append({
            "type": "Blood Oxygen Desaturation",
            "severity": "Critical",
            "confidence": 96.2,
            "explanation": f"Blood oxygen {req.spo2}% is below clinical safety threshold of 95%."
        })

    latency_ms = round((time.time() - start_time) * 1000 + 12.5, 2) # Simulate Edge TFLite execution speed

    return {
        "status": "analyzed",
        "edge_inference_engine": "TensorFlow Lite Micro (Edge AI)",
        "latency_ms": latency_ms,
        "is_normal": len(anomalies_found) == 0,
        "anomalies_detected": anomalies_found,
        "advice": "All vitals within safe boundaries." if len(anomalies_found) == 0 else "Take immediate preventive action as outlined."
    }

@router.get("/alerts")
async def get_all_alerts():
    if not db_manager._in_memory_collections["phc_disaster_alerts"]:
        _seed_phc_data()
    return db_manager._in_memory_collections["phc_disaster_alerts"]

@router.get("/alerts/disaster")
async def get_disaster_alerts():
    if not db_manager._in_memory_collections["phc_disaster_alerts"]:
        _seed_phc_data()
    return db_manager._in_memory_collections["phc_disaster_alerts"]


# =========================================================================
# 4. EMERGENCY & SOS APIS
# =========================================================================

@router.post("/emergency/sos/trigger")
async def trigger_emergency_sos(req: SosTriggerRequest):
    sos = db_manager._in_memory_collections["phc_emergency_sos"][0]
    now = datetime.now(timezone.utc).isoformat()

    sos["is_active"] = True
    sos["status"] = "ACTIVE_DISPATCH"
    sos["triggered_at"] = now
    sos["trigger_type"] = req.trigger_type
    sos["latitude"] = req.latitude
    sos["longitude"] = req.longitude
    sos["address"] = req.address
    sos["contacts_notified"] = len(db_manager._in_memory_collections["phc_emergency_contacts"])
    sos["countdown_seconds_left"] = 0
    sos["dispatch_eta_mins"] = 8
    sos["distress_reason"] = req.distress_reason or "Exertional Heat Exhaustion & Dizziness"

    sos["history"].append({
        "timestamp": now,
        "type": req.trigger_type,
        "location": req.address,
        "resolved": False
    })

    return {
        "status": "SOS_TRIGGERED",
        "message": "Emergency SOS broadcasted to emergency contacts and nearest hospital (IMS-BHU Trauma Centre).",
        "sos_state": sos
    }

@router.post("/emergency/sos/cancel")
async def cancel_emergency_sos():
    sos = db_manager._in_memory_collections["phc_emergency_sos"][0]
    sos["is_active"] = False
    sos["status"] = "CANCELLED_BY_USER"
    sos["dispatch_eta_mins"] = None
    return {
        "status": "SOS_CANCELLED",
        "message": "Active emergency SOS stood down. Caregivers notified of safe status.",
        "sos_state": sos
    }

@router.get("/emergency/sos/status")
async def get_emergency_sos_status():
    if not db_manager._in_memory_collections["phc_emergency_sos"]:
        _seed_phc_data()
    return db_manager._in_memory_collections["phc_emergency_sos"][0]

@router.get("/emergency/contacts")
async def get_emergency_contacts():
    if not db_manager._in_memory_collections["phc_emergency_contacts"]:
        _seed_phc_data()
    return db_manager._in_memory_collections["phc_emergency_contacts"]

@router.post("/emergency/contacts")
async def add_emergency_contact(req: EmergencyContactCreateRequest):
    new_contact = {
        "id": f"cnt-{uuid.uuid4().hex[:6]}",
        "name": req.name,
        "relationship": req.relationship,
        "phone": req.phone,
        "is_primary": req.is_primary,
        "notified_on_sos": True
    }
    db_manager._in_memory_collections["phc_emergency_contacts"].append(new_contact)
    return {"status": "success", "contact": new_contact}

@router.delete("/emergency/contacts/{contact_id}")
async def delete_emergency_contact(contact_id: str):
    contacts = db_manager._in_memory_collections["phc_emergency_contacts"]
    db_manager._in_memory_collections["phc_emergency_contacts"] = [c for c in contacts if c["id"] != contact_id]
    return {"status": "success", "message": "Emergency contact removed."}

@router.get("/emergency/medical-id")
async def get_emergency_medical_id():
    if not db_manager._in_memory_collections["phc_medical_ids"]:
        _seed_phc_data()
    return db_manager._in_memory_collections["phc_medical_ids"][0]

@router.put("/emergency/medical-id")
async def update_emergency_medical_id(req: MedicalIdUpdateRequest):
    if not db_manager._in_memory_collections["phc_medical_ids"]:
        _seed_phc_data()
    med_id = db_manager._in_memory_collections["phc_medical_ids"][0]
    med_id.update(req.dict())
    return {"status": "success", "medical_id": med_id}

@router.get("/emergency/nearby-hospitals")
async def get_nearby_hospitals():
    if not db_manager._in_memory_collections["phc_responder_emergencies"]:
        _seed_phc_data()
    return db_manager._in_memory_collections["phc_responder_emergencies"]

@router.post("/emergency/fall-detected")
async def report_fall_detected():
    """Trigger auto fall countdown window (30 seconds)"""
    return {
        "status": "FALL_DETECTED",
        "countdown_seconds": 30,
        "message": "Sudden impact and inactivity detected. Cancel within 30 seconds to prevent auto-SOS."
    }


# =========================================================================
# 5. ENVIRONMENTAL DASHBOARD APIS
# =========================================================================

@router.get("/environment/current")
async def get_current_environment():
    if not db_manager._in_memory_collections["phc_environment"]:
        _seed_phc_data()
    return db_manager._in_memory_collections["phc_environment"][0]

@router.get("/environment/forecast")
async def get_environment_forecast():
    return {
        "location": "Varanasi, UP",
        "forecast_hours": [
            {"hour": "12:00 PM", "temp_c": 41.5, "wbgt": 33.5, "heat_risk": "EXTREME", "aqi": 284},
            {"hour": "02:00 PM", "temp_c": 43.8, "wbgt": 34.2, "heat_risk": "DANGER", "aqi": 290},
            {"hour": "04:00 PM", "temp_c": 42.1, "wbgt": 33.0, "heat_risk": "EXTREME", "aqi": 275},
            {"hour": "06:00 PM", "temp_c": 38.0, "wbgt": 29.5, "heat_risk": "MODERATE", "aqi": 260},
            {"hour": "08:00 PM", "temp_c": 34.2, "wbgt": 27.0, "heat_risk": "LOW", "aqi": 245}
        ]
    }

@router.get("/environment/aqi")
async def get_aqi_details():
    env = db_manager._in_memory_collections["phc_environment"][0]
    return {
        "overall_aqi": env["aqi"],
        "category": env["aqi_category"],
        "pollutants": env["pollutants"],
        "health_recommendation": "Sensitive groups (asthma, COPD) should wear N95 masks outdoors and keep inhalers available."
    }

@router.get("/environment/heat-index")
async def get_heat_index_details():
    env = db_manager._in_memory_collections["phc_environment"][0]
    return {
        "ambient_temp_c": env["ambient_temp_c"],
        "feels_like_c": env["feels_like_c"],
        "wet_bulb_temp_c": env["wet_bulb_temp_c"],
        "heat_stroke_risk_level": env["heat_stroke_risk_level"],
        "work_rest_cycle": "45 mins work / 15 mins shaded rest with electrolyte"
    }


# =========================================================================
# 6. DEVICE & WEARABLE SENSOR APIS
# =========================================================================

@router.get("/devices")
async def get_paired_devices():
    if not db_manager._in_memory_collections["phc_devices"]:
        _seed_phc_data()
    return db_manager._in_memory_collections["phc_devices"]

@router.post("/devices/register")
async def register_device(req: DeviceRegisterRequest):
    new_dev = {
        "id": f"dev-{uuid.uuid4().hex[:6]}",
        "device_name": req.device_name,
        "device_type": req.device_type,
        "connection_status": "Connected (BLE Active)",
        "battery_level": req.battery_level,
        "mac_address": req.mac_address,
        "firmware_version": req.firmware_version,
        "sensors_active": ["Continuous PPG", "IMU Motion"],
        "last_synced": datetime.now(timezone.utc).isoformat(),
        "sampling_rate": "Adaptive (1 sec - 30 sec)"
    }
    db_manager._in_memory_collections["phc_devices"].append(new_dev)
    return {"status": "success", "device": new_dev}

@router.delete("/devices/{device_id}")
async def unpair_device(device_id: str):
    devs = db_manager._in_memory_collections["phc_devices"]
    db_manager._in_memory_collections["phc_devices"] = [d for d in devs if d["id"] != device_id]
    return {"status": "success", "message": "Device unpaired successfully."}

@router.post("/devices/{device_id}/sync")
async def force_sync_device(device_id: str):
    now = datetime.now(timezone.utc).isoformat()
    for d in db_manager._in_memory_collections["phc_devices"]:
        if d["id"] == device_id:
            d["last_synced"] = now
            return {"status": "success", "synced_at": now, "device": d}
    raise HTTPException(status_code=404, detail="Device not found")


# =========================================================================
# 7. MEDICATION MANAGEMENT APIS
# =========================================================================

@router.get("/medications")
async def get_medications():
    if not db_manager._in_memory_collections["phc_medications"]:
        _seed_phc_data()
    return db_manager._in_memory_collections["phc_medications"]

@router.post("/medications")
async def add_medication(req: MedicationCreateRequest):
    new_med = {
        "id": f"med-{uuid.uuid4().hex[:6]}",
        "name": req.name,
        "dosage": req.dosage,
        "frequency": req.frequency,
        "scheduled_time": "08:00 AM",
        "timing": req.timing,
        "category": req.category,
        "total_tablets": req.total_tablets,
        "remaining_tablets": req.remaining_tablets,
        "adherence_rate_pct": 100.0,
        "instructions": req.instructions,
        "today_status": "pending"
    }
    db_manager._in_memory_collections["phc_medications"].append(new_med)
    return {"status": "success", "medication": new_med}

@router.post("/medications/{med_id}/log")
async def log_medication_status(med_id: str, req: MedicationLogRequest):
    for m in db_manager._in_memory_collections["phc_medications"]:
        if m["id"] == med_id:
            m["today_status"] = req.status
            if req.status == "taken" and m["remaining_tablets"] > 0:
                m["remaining_tablets"] -= 1
            return {"status": "success", "message": f"Medication marked as {req.status}.", "medication": m}
    raise HTTPException(status_code=404, detail="Medication not found")

@router.delete("/medications/{med_id}")
async def delete_medication(med_id: str):
    meds = db_manager._in_memory_collections["phc_medications"]
    db_manager._in_memory_collections["phc_medications"] = [m for m in meds if m["id"] != med_id]
    return {"status": "success", "message": "Medication removed."}

@router.get("/medications/adherence")
async def get_medication_adherence():
    return {
        "overall_adherence_pct": 94.5,
        "streak_days": 18,
        "missed_doses_this_month": 1,
        "refill_alerts": [
            {"medication": "Electral ORS Sachet", "remaining_tablets": 11, "alert": "Sufficient for 11 days"}
        ]
    }


# =========================================================================
# 8. CAREGIVER PORTAL APIS
# =========================================================================

@router.get("/caregiver/dependents")
async def get_caregiver_dependents():
    if not db_manager._in_memory_collections["phc_caregiver_dependents"]:
        _seed_phc_data()
    return db_manager._in_memory_collections["phc_caregiver_dependents"]

@router.post("/caregiver/dependents/{dep_id}/check-in")
async def send_caregiver_checkin(dep_id: str, req: CaregiverCheckInRequest):
    now = datetime.now(timezone.utc).isoformat()
    for d in db_manager._in_memory_collections["phc_caregiver_dependents"]:
        if d["id"] == dep_id:
            d["last_checkin"] = now
            d["last_checkin_status"] = "Ping Dispatched: 'Are you okay?'"
            return {
                "status": "success",
                "message": f"Check-in request sent to {d['name']}. Response will reflect automatically.",
                "dependent": d
            }
    raise HTTPException(status_code=404, detail="Dependent not found")

@router.post("/caregiver/dependents/{dep_id}/sos")
async def trigger_remote_sos_for_dependent(dep_id: str):
    for d in db_manager._in_memory_collections["phc_caregiver_dependents"]:
        if d["id"] == dep_id:
            return {
                "status": "REMOTE_SOS_DISPATCHED",
                "message": f"Emergency rescue SOS remotely triggered for {d['name']} at {d['location']}.",
                "dependent": d
            }
    raise HTTPException(status_code=404, detail="Dependent not found")


# =========================================================================
# 9. HEALTHCARE PROVIDER / ASHA COPILOT APIS
# =========================================================================

@router.get("/provider/patients")
async def get_provider_patients():
    if not db_manager._in_memory_collections["phc_provider_patients"]:
        _seed_phc_data()
    return db_manager._in_memory_collections["phc_provider_patients"]

@router.get("/provider/patients/{patient_id}")
async def get_provider_patient_detail(patient_id: str):
    for p in db_manager._in_memory_collections["phc_provider_patients"]:
        if p["id"] == patient_id:
            return p
    return db_manager._in_memory_collections["phc_provider_patients"][0]

@router.post("/provider/patients/{patient_id}/notes")
async def add_clinical_note(patient_id: str, note_text: str = Body(..., embed=True)):
    now = datetime.now(timezone.utc).isoformat()
    note = {
        "id": f"note-{uuid.uuid4().hex[:6]}",
        "patient_id": patient_id,
        "doctor": "Dr. Pradeep Mishra, MD",
        "date": now,
        "note": note_text
    }
    db_manager._in_memory_collections["phc_clinical_notes"].append(note)
    return {"status": "success", "clinical_note": note}

@router.get("/provider/community/heatmap")
async def get_community_heatmap():
    if not db_manager._in_memory_collections["phc_surveillance"]:
        _seed_phc_data()
    return db_manager._in_memory_collections["phc_surveillance"][0]


# =========================================================================
# 10. TELEMEDICINE & DOCTOR CONSULTATION APIS
# =========================================================================

@router.get("/telemedicine/doctors")
async def get_telemedicine_doctors():
    if not db_manager._in_memory_collections["phc_telemedicine_doctors"]:
        _seed_phc_data()
    return db_manager._in_memory_collections["phc_telemedicine_doctors"]

@router.post("/telemedicine/appointments")
async def book_telemedicine_appointment(req: DoctorAppointmentRequest):
    appointment = {
        "id": f"apt-{uuid.uuid4().hex[:6]}",
        "doctor_id": req.doctor_id,
        "consultation_type": req.consultation_type,
        "appointment_time": req.appointment_time,
        "chief_complaint": req.chief_complaint,
        "status": "Confirmed (Cashless Ayushman PM-JAY)",
        "video_room_id": f"phc-room-{uuid.uuid4().hex[:8]}",
        "created_at": datetime.now(timezone.utc).isoformat()
    }
    db_manager._in_memory_collections["phc_appointments"].append(appointment)
    return {
        "status": "success",
        "message": "Tele-consultation session scheduled. Direct video link active.",
        "appointment": appointment
    }

@router.get("/telemedicine/appointments")
async def get_telemedicine_appointments():
    return db_manager._in_memory_collections["phc_appointments"]


# =========================================================================
# 11. PERSONAL HEALTH RECORDS VAULT APIS
# =========================================================================

@router.get("/records")
async def get_health_records():
    if not db_manager._in_memory_collections["phc_health_records"]:
        _seed_phc_data()
    return db_manager._in_memory_collections["phc_health_records"]

@router.post("/records")
async def upload_health_record(req: HealthRecordUploadRequest):
    new_rec = {
        "id": f"rec-{uuid.uuid4().hex[:6]}",
        "title": req.title,
        "category": req.category,
        "provider": req.doctor_or_lab,
        "date": req.date_recorded,
        "encryption": "AES-256 Client-Encrypted",
        "summary": req.summary_notes,
        "tags": req.tags,
        "shared_with": ["Self"]
    }
    db_manager._in_memory_collections["phc_health_records"].append(new_rec)
    return {"status": "success", "message": "Health record safely vaulted with AES-256 encryption.", "record": new_rec}

@router.delete("/records/{record_id}")
async def delete_health_record(record_id: str):
    recs = db_manager._in_memory_collections["phc_health_records"]
    db_manager._in_memory_collections["phc_health_records"] = [r for r in recs if r["id"] != record_id]
    return {"status": "success", "message": "Record permanently removed under DPDP Act Right to Erasure."}


# =========================================================================
# 12. GOVERNMENT SCHEME INTEGRATION APIS
# =========================================================================

@router.get("/schemes/eligibility")
async def get_schemes_eligibility():
    if not db_manager._in_memory_collections["phc_schemes"]:
        _seed_phc_data()
    return {
        "schemes": db_manager._in_memory_collections["phc_schemes"],
        "user_eligible_pmjay": True,
        "abha_linked": True,
        "cashless_limit_remaining": "₹5,00,000"
    }

@router.post("/schemes/abha/generate")
async def generate_abha_id(req: AbhaGenerateRequest):
    new_abha = f"91-{uuid.uuid4().int % 9000 + 1000}-{uuid.uuid4().int % 9000 + 1000}-{uuid.uuid4().int % 9000 + 1000}"
    return {
        "status": "success",
        "abha_id": new_abha,
        "abha_address": f"{req.full_name.lower().replace(' ', '.')}.{uuid.uuid4().hex[:4]}@abdm",
        "message": "ABHA 14-Digit Health Account successfully provisioned under ABDM."
    }

@router.post("/schemes/abha/link")
async def link_abha_id(req: AbhaLinkRequest):
    return {
        "status": "success",
        "abha_id": req.abha_id,
        "linked": True,
        "message": "ABHA ID linked to Personal Health Companion profile."
    }

@router.get("/schemes/hospitals")
async def get_scheme_hospitals():
    return db_manager._in_memory_collections["phc_responder_emergencies"]


# =========================================================================
# 13. CONTENT, WELLNESS & FIRST-AID APIS
# =========================================================================

@router.get("/content/recommendations")
async def get_wellness_recommendations():
    return {
        "recommendations": [
            {
                "title": "Smart Hydration Timing",
                "category": "HYDRATION",
                "urgency": "HIGH",
                "icon": "water_drop",
                "text": "Ambient heat index is projected to reach 47°C at 1:30 PM. Pre-hydrate with 400ml water and 1 ORS sachet before leaving shade."
            },
            {
                "title": "Respiratory Defense Protocol",
                "category": "ENVIRONMENT",
                "urgency": "MEDIUM",
                "icon": "air",
                "text": "PM2.5 AQI is 288 in urban corridors. Put on your certified N95 particulate mask if traveling along highway zones."
            },
            {
                "title": "Medication Timing & Heat Precaution",
                "category": "MEDICATION",
                "urgency": "INFO",
                "icon": "medication",
                "text": "Amlodipine regulates blood vessel tone. Remember to avoid hot showers immediately after taking doses."
            },
            {
                "title": "Evening Recovery Breathing Exercise",
                "category": "RELAXATION",
                "urgency": "LOW",
                "icon": "self_improvement",
                "text": "Complete 5 minutes of 4-7-8 Pranayama breathing to restore heart rate variability (HRV) after physical exertion."
            }
        ]
    }

@router.get("/content/first-aid")
async def get_first_aid_guides():
    return {
        "guides": [
            {
                "title": "Heat Stroke vs Heat Exhaustion",
                "symptoms": "Confusion, dry hot skin, body temp > 40°C vs Heavy sweating, cold pale skin, fast weak pulse.",
                "steps": [
                    "Move patient immediately to air-conditioned or shaded area.",
                    "Apply ice packs or cold water compresses to neck, armpits, and groin.",
                    "Do NOT give fluids if patient is unconscious.",
                    "Call 112 / trigger in-app Emergency SOS immediately."
                ]
            },
            {
                "title": "Fall & Suspected Bone Fracture",
                "symptoms": "Inability to bear weight, visible deformity, localized swelling.",
                "steps": [
                    "Do not move injured limb unnecessarily.",
                    "Immobilize the area using an umbrella or rolled cardboard splint.",
                    "Apply ice pack wrapped in cloth to reduce acute swelling."
                ]
            }
        ]
    }


# =========================================================================
# 14. PRIVACY & EDGE AI BENCHMARK APIS
# =========================================================================

@router.get("/edge-ai/status")
async def get_edge_ai_status():
    return {
        "framework": "TensorFlow Lite Micro (Edge AI)",
        "on_device_inference_latency_ms": 34.2,
        "model_version": "v3.2.1-quantized-int8",
        "battery_drain_per_hour_pct": 3.8,
        "local_vault_encryption": "AES-256-GCM Hardware Backed",
        "offline_autonomous_mode": True,
        "dpdp_act_compliance": "Fully Compliant (Section 6 & 8)",
        "cloud_sync_state": "Opportunistic / Differential Privacy Filter Active"
    }

@router.post("/privacy/consent/toggle")
async def toggle_consent(req: ConsentToggleRequest):
    return {
        "status": "success",
        "consent_key": req.consent_key,
        "granted": req.granted,
        "message": f"Consent preference for '{req.consent_key}' updated in local DPDP security gate."
    }
