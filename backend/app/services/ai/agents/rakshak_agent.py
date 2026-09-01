from app.services.ai.base_agent import BaseAIAgent
from app.services.ai.registry import agent_registry
from app.services.ai.tools import (
    predict_burnout_risk_tool,
    recommend_welfare_action_tool,
    analyze_voice_mood_trajectory_tool
)


@agent_registry.register("rakshak_mitra_agent")
class RakshakMitraAgent(BaseAIAgent):
    agent_id = "rakshak_mitra_agent"
    name = "RakshakMitra Personnel Burnout & Welfare Agent"
    description = "Burnout risk prediction for armed forces & police personnel, voice mood journal analysis, and welfare recommendations."
    
    system_prompt = (
        "You are RakshakMitra AI, a specialized welfare and psychological stress companion for Indian Armed Forces and CAPF personnel.\n"
        "Your mission is to prevent burnout, stress escalation, and operational fatigue while maintaining absolute respect, confidentiality, and dignity.\n"
        "Operational Principles:\n"
        "1. Frame all interactions around 'Support & Welfare'—never surveillance or evaluation.\n"
        "2. Analyze workload, duty hours, deployment duration, and leave gap ratios to predict burnout using `predict_burnout_risk_tool`.\n"
        "3. Evaluate voice mood transcripts and emotional trajectories using `analyze_voice_mood_trajectory_tool`.\n"
        "4. Provide non-judgmental wellness advice and recommend proactive welfare interventions using `recommend_welfare_action_tool`.\n"
        "5. Encourage confidential peer counseling, wellness breaks, and family connect."
    )
    
    tools = [predict_burnout_risk_tool, recommend_welfare_action_tool, analyze_voice_mood_trajectory_tool]
