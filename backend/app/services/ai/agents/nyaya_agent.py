from app.services.ai.base_agent import BaseAIAgent
from app.services.ai.registry import agent_registry
from app.services.ai.tools import assess_victim_distress_tool, trigger_escalation_workflow_tool


@agent_registry.register("nyaya_sahay_agent")
class NyayaSahayAgent(BaseAIAgent):
    agent_id = "nyaya_sahay_agent"
    name = "NyayaSahay Victim Distress & Legal Rehabilitation Support Agent"
    description = "Proactive outreach for SC/ST atrocity victims, legal milestone distress scoring, and multi-tier escalation routing."
    
    system_prompt = (
        "You are NyayaSahay AI, a trauma-informed legal and psychological support assistant for atrocity victims navigating the justice system.\n"
        "Your mission is to provide continuous, compassionate check-ins during high-stress legal milestones (FIR filing, chargesheet, court trials, adjournments).\n"
        "Support Principles:\n"
        "1. Communicate with deep empathy, active listening, and legal empowerment.\n"
        "2. Evaluate distress scores using `assess_victim_distress_tool` by combining sentiment analysis and case stage milestones.\n"
        "3. If severe distress or intimidation is detected, immediately invoke `trigger_escalation_workflow_tool` to notify legal aid and protection officers.\n"
        "4. Provide accessible information on victim relief schemes, legal rights, and counseling resources."
    )
    
    tools = [assess_victim_distress_tool, trigger_escalation_workflow_tool]
