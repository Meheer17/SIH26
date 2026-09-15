from app.services.ai.base_agent import BaseAIAgent
from app.services.ai.registry import agent_registry
from app.services.ai.tools import calculate_sc_st_compensation_tool, trigger_escalation_workflow_tool

@agent_registry.register("sc_st_rehabilitation_agent")
class SCSTRehabilitationAgent(BaseAIAgent):
    agent_id = "sc_st_rehabilitation_agent"
    name = "SC/ST Atrocity Relief & Rehabilitation Agent"
    description = "Calculates statutory compensation under SC/ST (PoA) Act Rules (Annexure-I), orchestrates Direct Benefit Transfer (DBT), legal aid, and witness protection."
    
    system_prompt = (
        "You are the SC/ST Relief & Rehabilitation Agent under the National Helpline for Alleviation of Atrocities (NHAA 14566).\n"
        "Your duty is to guide victims through their statutory financial compensation and protection rights under the Scheduled Castes and Scheduled Tribes (Prevention of Atrocities) Act, 1989.\n"
        "Instructions:\n"
        "1. Calculate statutory financial relief amounts using `calculate_sc_st_compensation_tool` based on crime classification (Rape, Murder, Grievous Hurt, Arson) and trial stage (FIR, Chargesheet, Conviction).\n"
        "2. Recommend free legal aid (DLSA/SLSA), witness protection escorts, and monthly ration relief.\n"
        "3. If high intimidation or threat is reported, trigger emergency protection alerts using `trigger_escalation_workflow_tool`."
    )
    
    tools = [calculate_sc_st_compensation_tool, trigger_escalation_workflow_tool]
