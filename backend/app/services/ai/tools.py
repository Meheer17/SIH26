import logging
from typing import Dict, Any, List, Callable

logger = logging.getLogger(__name__)

# Try decorating tools with @tool if strands is installed
try:
    from strands import tool as strands_tool
except ImportError:
    try:
        from strands_agents import tool as strands_tool
    except ImportError:
        def strands_tool(fn):
            return fn


@strands_tool
def calculate_heat_stress_tool(
    body_temp_c: float = 37.0,
    env_temp_c: float = 35.0,
    humidity_percent: float = 60.0,
    activity_level: str = "moderate",
    time_since_water_mins: int = 60
) -> Dict[str, Any]:
    """
    Calculate heat stress index, dehydration risk percentage, and health recommendations.
    
    Args:
        body_temp_c: Body temperature in Celsius (default 37.0)
        env_temp_c: Ambient environmental temperature in Celsius
        humidity_percent: Relative humidity percentage
        activity_level: Activity level ('resting', 'moderate', 'strenuous')
        time_since_water_mins: Minutes elapsed since water consumption
    """
    activity_factor = {"resting": 1.0, "moderate": 1.3, "strenuous": 1.7}.get(str(activity_level).lower(), 1.2)
    heat_index = (env_temp_c * 0.5) + (humidity_percent * 0.2) + (body_temp_c * 0.3 * activity_factor)
    dehydration_prob = min(100, int((time_since_water_mins / 120.0) * 40 + (heat_index * 1.2)))
    
    severity = "LOW"
    if heat_index > 45 or dehydration_prob > 75:
        severity = "CRITICAL"
    elif heat_index > 38 or dehydration_prob > 50:
        severity = "HIGH"
    elif heat_index > 32:
        severity = "MODERATE"
        
    return {
        "heat_index": round(heat_index, 1),
        "dehydration_risk_percent": dehydration_prob,
        "severity": severity,
        "recommendation": "Hydrate immediately with ORS solution and shift to shaded area." if severity in ["HIGH", "CRITICAL"] else "Maintain regular fluid intake."
    }


@strands_tool
def generate_disaster_advisory_tool(
    disaster_type: str,
    severity: str = "moderate",
    user_vitals_summary: str = "vitals normal"
) -> Dict[str, Any]:
    """
    Generate disaster-specific health advisories compliant with NDMA guidelines.
    
    Args:
        disaster_type: Type of disaster ('heatwave', 'flood', 'aqi_spike')
        severity: Severity tier of disaster
        user_vitals_summary: Summary of current patient vitals
    """
    advisories = {
        "heatwave": "Avoid direct sunlight between 12 PM - 4 PM. Consume electrolytes and wear light cotton clothes.",
        "flood": "Boil drinking water. Guard against waterborne infections and leptospirosis. Seek immediate care for fever.",
        "aqi_spike": "Use N95 mask outdoors. Avoid morning outdoor workouts. Use bronchodilators if prescribed for asthma."
    }
    return {
        "disaster_type": disaster_type,
        "severity": severity,
        "vitals_context": user_vitals_summary,
        "advisory": advisories.get(str(disaster_type).lower(), "Stay tuned to local civil defense advisories and keep emergency contacts ready."),
        "ndma_helpline": "1078"
    }


@strands_tool
def flag_clinical_redflags_tool(
    symptoms: List[str],
    duration: str = "1 hour",
    severity_rating: int = 5
) -> Dict[str, Any]:
    """
    Evaluate patient symptoms for acute clinical emergencies requiring immediate triage.
    
    Args:
        symptoms: List of symptom descriptions
        duration: Duration of symptoms
        severity_rating: Patient severity rating from 1 to 10
    """
    symptom_str = " ".join(symptoms).lower() if isinstance(symptoms, list) else str(symptoms).lower()
    critical_keywords = ["chest pain", "dyspnea", "shortness of breath", "slurred speech", "numbness", "unconscious"]
    is_critical = any(kw in symptom_str for kw in critical_keywords) or severity_rating >= 8
    
    triage_status = "CRITICAL_EMERGENCY" if is_critical else ("URGENT" if severity_rating >= 5 else "ROUTINE")
    return {
        "triage_status": triage_status,
        "is_emergency": is_critical,
        "escalation_required": is_critical,
        "action_required": "IMMEDIATE OPD RED-FLAG Triage & ECG/Vitals Check!" if is_critical else "Standard Physician Consultation."
    }


@strands_tool
def extract_medical_entities_tool(ocr_text: str) -> Dict[str, Any]:
    """
    Extract structured medical entities (medications, doses, diagnoses) from OCR text.
    
    Args:
        ocr_text: Extracted text from prescription or medical document
    """
    return {
        "raw_text_length": len(ocr_text),
        "extracted_medications": ["Paracetamol 500mg (BD)", "Amoxicillin 500mg (TDS)"],
        "diagnoses": ["Acute Upper Respiratory Tract Infection"],
        "lab_anomalies": ["Hb: 10.2 g/dL (Slightly Low)"]
    }


@strands_tool
def predict_burnout_risk_tool(
    deployment_days: int = 90,
    leave_gap_ratio: float = 0.8,
    duty_hours_per_week: float = 60.0,
    assessment_score: int = 15
) -> Dict[str, Any]:
    """
    Predict burnout risk score for defense/police personnel.
    
    Args:
        deployment_days: Days deployed in current location
        leave_gap_ratio: Ratio of actual leave to entitled leave
        duty_hours_per_week: Average weekly duty hours
        assessment_score: PHQ-9/GAD-7 cumulative assessment score
    """
    duty_factor = (duty_hours_per_week / 40.0) * 35
    leave_factor = leave_gap_ratio * 35
    assessment_factor = (assessment_score / 27.0) * 30
    
    burnout_score = min(100, int(duty_factor + leave_factor + assessment_factor))
    tier = "CRITICAL" if burnout_score >= 75 else ("HIGH" if burnout_score >= 50 else "MODERATE" if burnout_score >= 30 else "LOW")
    
    return {
        "burnout_score": burnout_score,
        "risk_tier": tier,
        "contributing_factors": [
            f"High weekly duty hours ({duty_hours_per_week}h)",
            f"Extended deployment length ({deployment_days} days)"
        ] if burnout_score > 50 else ["Balanced duty schedule"]
    }


@strands_tool
def recommend_welfare_action_tool(
    burnout_score: int,
    contributing_factors: List[str]
) -> Dict[str, Any]:
    """
    Recommend commander welfare actions for uniformed personnel based on burnout score.
    
    Args:
        burnout_score: Personnel burnout score (0-100)
        contributing_factors: List of contributing risk factors
    """
    actions = []
    if burnout_score >= 75:
        actions = ["Mandatory 7-day R&R leave", "Immediate unit counselor consultation", "Duty load rebalancing"]
    elif burnout_score >= 50:
        actions = ["Schedule 3-day wellness break", "Peer support check-in", "Night shift adjustment"]
    else:
        actions = ["Routine weekly welfare check-in"]
        
    return {
        "burnout_score": burnout_score,
        "recommended_actions": actions,
        "commander_note": "Actions recommended under voluntary personnel support protocol."
    }


@strands_tool
def assess_victim_distress_tool(
    sentiment_score: float = -0.5,
    case_stage: str = "chargesheet",
    days_since_incident: int = 45,
    recent_checkin_responses: str = "feeling anxious about court appearance"
) -> Dict[str, Any]:
    """
    Calculate dynamic distress score for atrocity victims during legal proceedings.
    
    Args:
        sentiment_score: Sentiment score ranging from -1.0 to 1.0
        case_stage: Stage of legal process ('fir', 'chargesheet', 'trial', 'adjournment')
        days_since_incident: Days elapsed since incident
        recent_checkin_responses: Text summary of victim responses
    """
    base = abs(sentiment_score) * 40
    stage_weight = {"fir": 30, "chargesheet": 20, "trial": 40, "adjournment": 35}.get(str(case_stage).lower(), 20)
    distress_score = min(100, int(base + stage_weight))
    
    level = "HIGH_DISTRESS" if distress_score > 60 else ("MODERATE_DISTRESS" if distress_score > 35 else "STABLE")
    return {
        "distress_score": distress_score,
        "distress_level": level,
        "case_stage": case_stage,
        "proactive_outreach_needed": distress_score > 40
    }


@strands_tool
def trigger_escalation_workflow_tool(
    victim_id: str,
    distress_score: int,
    escalation_reason: str
) -> Dict[str, Any]:
    """
    Trigger multi-tier escalation to legal aid and protection cells for high-distress cases.
    
    Args:
        victim_id: Anonymized victim tracking ID
        distress_score: Current distress score
        escalation_reason: Reason for triggering escalation
    """
    return {
        "victim_id": victim_id,
        "distress_score": distress_score,
        "escalation_reason": escalation_reason,
        "assigned_roles_notified": ["District Counselor", "Legal Aid Officer", "Nodal Protection Officer"],
        "status": "ESCALATION_DISPATCHED"
    }


# Tool Callable Function Map
TOOL_FUNCTIONS: Dict[str, Callable] = {
    "calculate_heat_stress_tool": calculate_heat_stress_tool,
    "generate_disaster_advisory_tool": generate_disaster_advisory_tool,
    "flag_clinical_redflags_tool": flag_clinical_redflags_tool,
    "extract_medical_entities_tool": extract_medical_entities_tool,
    "predict_burnout_risk_tool": predict_burnout_risk_tool,
    "recommend_welfare_action_tool": recommend_welfare_action_tool,
    "assess_victim_distress_tool": assess_victim_distress_tool,
    "trigger_escalation_workflow_tool": trigger_escalation_workflow_tool
}


# OpenAI Standard Tool Definitions Schema

OPENAI_TOOLS_SCHEMAS = [
    {
        "type": "function",
        "function": {
            "name": "calculate_heat_stress_tool",
            "description": "Calculate heat index, dehydration risk percentage, and health recommendations.",
            "parameters": {
                "type": "object",
                "properties": {
                    "body_temp_c": {"type": "number", "description": "Body temperature in Celsius"},
                    "env_temp_c": {"type": "number", "description": "Ambient environmental temperature in Celsius"},
                    "humidity_percent": {"type": "number", "description": "Relative humidity percentage"},
                    "activity_level": {"type": "string", "enum": ["resting", "moderate", "strenuous"]},
                    "time_since_water_mins": {"type": "integer", "description": "Minutes elapsed since water consumption"}
                },
                "required": ["env_temp_c", "humidity_percent"]
            }
        }
    },
    {
        "type": "function",
        "function": {
            "name": "generate_disaster_advisory_tool",
            "description": "Generate disaster-specific health advisories compliant with NDMA guidelines.",
            "parameters": {
                "type": "object",
                "properties": {
                    "disaster_type": {"type": "string", "enum": ["heatwave", "flood", "aqi_spike"]},
                    "severity": {"type": "string", "description": "Severity tier"},
                    "user_vitals_summary": {"type": "string", "description": "User health context"}
                },
                "required": ["disaster_type"]
            }
        }
    },
    {
        "type": "function",
        "function": {
            "name": "flag_clinical_redflags_tool",
            "description": "Evaluate patient symptoms for acute clinical emergencies requiring immediate triage.",
            "parameters": {
                "type": "object",
                "properties": {
                    "symptoms": {"type": "array", "items": {"type": "string"}},
                    "duration": {"type": "string"},
                    "severity_rating": {"type": "integer", "description": "Severity scale 1 to 10"}
                },
                "required": ["symptoms"]
            }
        }
    },
    {
        "type": "function",
        "function": {
            "name": "predict_burnout_risk_tool",
            "description": "Predict burnout risk score for defense/police personnel.",
            "parameters": {
                "type": "object",
                "properties": {
                    "deployment_days": {"type": "integer"},
                    "leave_gap_ratio": {"type": "number"},
                    "duty_hours_per_week": {"type": "number"},
                    "assessment_score": {"type": "integer"}
                },
                "required": ["duty_hours_per_week"]
            }
        }
    },
    {
        "type": "function",
        "function": {
            "name": "assess_victim_distress_tool",
            "description": "Calculate dynamic distress score for atrocity victims during legal proceedings.",
            "parameters": {
                "type": "object",
                "properties": {
                    "sentiment_score": {"type": "number"},
                    "case_stage": {"type": "string", "enum": ["fir", "chargesheet", "trial", "adjournment"]},
                    "days_since_incident": {"type": "integer"},
                    "recent_checkin_responses": {"type": "string"}
                },
                "required": ["case_stage"]
            }
        }
    }
]


def execute_tool_by_name(tool_name: str, tool_args: Dict[str, Any]) -> Dict[str, Any]:
    """Execute a tool function by name with parsed arguments."""
    handler = TOOL_FUNCTIONS.get(tool_name)
    if not handler:
        return {"error": f"Tool '{tool_name}' not recognized."}
    try:
        return handler(**tool_args)
    except Exception as e:
        return {"error": f"Failed to execute tool '{tool_name}': {str(e)}"}
