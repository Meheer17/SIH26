# Automatically import and register all specialized agents
from app.services.ai.agents.arogya_agent import ArogyaSathiAgent
from app.services.ai.agents.medikiosk_agent import MediKioskAgent
from app.services.ai.agents.rakshak_agent import RakshakMitraAgent
from app.services.ai.agents.nyaya_agent import NyayaSahayAgent
from app.services.ai.agents.sc_st_rehabilitation_agent import SCSTRehabilitationAgent
from app.services.ai.agents.xai_explainability_agent import XAIExplainabilityAgent
from app.services.ai.agents.general_agent import GeneralAssistantAgent

__all__ = [
    "ArogyaSathiAgent",
    "MediKioskAgent",
    "RakshakMitraAgent",
    "NyayaSahayAgent",
    "SCSTRehabilitationAgent",
    "XAIExplainabilityAgent",
    "GeneralAssistantAgent"
]

