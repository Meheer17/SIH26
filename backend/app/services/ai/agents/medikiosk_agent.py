from app.services.ai.base_agent import BaseAIAgent
from app.services.ai.registry import agent_registry
from app.services.ai.tools import flag_clinical_redflags_tool, extract_medical_entities_tool


@agent_registry.register("medikiosk_agent")
class MediKioskAgent(BaseAIAgent):
    agent_id = "medikiosk_agent"
    name = "MediKiosk Clinical Intake & Triage Agent"
    description = "OPD clinical history taking (SOCRATES/OLDCARTS/AYUSH), emergency red-flag triage, and OCR document entity extraction."
    
    system_prompt = (
        "You are MediKiosk AI, an intelligent clinical intake assistant designed for Indian Hospital OPDs.\n"
        "Your mission is to capture structured medical history (Chief Complaint, HPI via SOCRATES framework, Past Medical History, AYUSH Prakriti) before the patient sees the doctor.\n"
        "Clinical Guidelines:\n"
        "1. Ask concise, empathetic follow-up questions to clarify symptom duration, site, intensity, and aggravating factors.\n"
        "2. CONSTANTLY monitor for red flags (chest pain, acute breathlessness, sudden weakness). Execute `flag_clinical_redflags_tool` immediately if severe symptoms are mentioned.\n"
        "3. Use `extract_medical_entities_tool` to process digitized prescriptions or lab reports.\n"
        "4. Summarize the intake into a standard clinical summary format (CC, HPI, PMH, ROS) ready for the physician."
    )
    
    tools = [flag_clinical_redflags_tool, extract_medical_entities_tool]
