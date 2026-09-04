"""
Cultural Mental Health Counselor & Family Health Graph Router
"""
from fastapi import APIRouter, Body
from typing import List, Optional, Dict, Any
from pydantic import BaseModel
from app.services.health_graph import compute_family_hereditary_risk

router = APIRouter()

class CounselorChatMessage(BaseModel):
    user_message: str
    target_persona: str = "COMPASSIONATE_COUNSELOR" # MILITARY_PEER / SC_ST_LEGAL_COUNSELOR / COMPASSIONATE_COUNSELOR
    language: str = "en"

class FamilyMemberNode(BaseModel):
    id: str
    name: str
    relation: str # self / father / mother / grandfather / brother / sister
    conditions: List[str] = []
    parents: List[str] = []

@router.post("/counselor-chat")
def chat_with_cultural_counselor(req: CounselorChatMessage = Body(...)):
    """
    Culturally competent, empathetic mental health conversation endpoint.
    Tailors response persona for military personnel, trauma survivors, or general patients.
    """
    msg = req.user_message.lower()
    
    if req.target_persona == "MILITARY_PEER":
        greeting = "Jai Hind, Comrade. I am standing by with complete confidentiality."
        empathy_response = "Serving under extreme stress takes a toll. You don't have to carry this operational burden alone."
    elif req.target_persona == "SC_ST_LEGAL_COUNSELOR":
        greeting = "Namaste. You are in a safe, trauma-informed space."
        empathy_response = "We understand the psychological distress caused by discrimination and systemic hardship. Legal aid and psychological support are guaranteed to you under the Act."
    else:
        greeting = "Namaste, I am your SvasthyaSetu Health & Mindfulness Companion."
        empathy_response = "Thank you for opening up. Taking care of your mind is just as vital as physical health."

    # Heuristic coping advice
    coping_strategies = [
        "4-7-8 Breathing Technique: Inhale for 4s, hold for 7s, exhale for 8s.",
        "Grounding 5-4-3-2-1 Technique: Identify 5 things you see, 4 you feel, 3 you hear, 2 you smell, 1 you taste.",
        "Guided Relaxation: Listen to calming ambient ragas or progressive muscle relaxation."
    ]

    return {
        "status": "SUCCESS",
        "persona": req.target_persona,
        "response": f"{greeting} {empathy_response}",
        "actionable_coping_strategies": coping_strategies,
        "24x7_helplines": {
            "KIRAN_Mental_Health": "1800-599-0019",
            "Tele_MANAS": "14416",
            "SvasthyaSetu_Crisis_Line": "1800-889-2026"
        }
    }

@router.post("/family-health-graph")
def calculate_family_health_graph(family_tree: List[FamilyMemberNode] = Body(...)):
    """
    Builds NetworkX hereditary risk graph across family lineage nodes.
    Calculates genetic vulnerability scores for cardiometabolic, anemia, and inter-generational trauma.
    """
    tree_dicts = [m.model_dump() for m in family_tree] if family_tree else []
    return compute_family_hereditary_risk(tree_dicts)

@router.get("/family-health-graph/demo")
def get_family_health_graph_demo():
    """Returns sample family health graph with hereditary risk computation."""
    return compute_family_hereditary_risk([])
