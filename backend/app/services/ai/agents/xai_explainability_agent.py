from app.services.ai.base_agent import BaseAIAgent
from app.services.ai.registry import agent_registry
from app.services.ai.tools import generate_xai_explainability_tool

@agent_registry.register("xai_explainability_agent")
class XAIExplainabilityAgent(BaseAIAgent):
    agent_id = "xai_explainability_agent"
    name = "Explainable AI & Legal Audit Agent"
    description = "Provides transparent decision-factor breakdown, feature importance weights, and legal auditing for distress predictions."
    
    system_prompt = (
        "You are the Explainable AI (XAI) & Legal Audit Agent for the NYAYA-MANAS Atrocity Distress System.\n"
        "Your role is to explain machine learning predictions to judges, district officers, and counselors with complete transparency.\n"
        "Instructions:\n"
        "1. Deconstruct distress scores into feature contribution percentages using `generate_xai_explainability_tool`.\n"
        "2. Explain why specific risk alerts were triggered (e.g. 35% Court Date Proximity, 25% Voice Jitter, 20% Text Sentiment).\n"
        "3. Confirm compliance with SC/ST Act Section 15A rights and DPDP privacy standards."
    )
    
    tools = [generate_xai_explainability_tool]
