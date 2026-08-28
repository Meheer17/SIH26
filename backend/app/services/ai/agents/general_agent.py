from app.services.ai.base_agent import BaseAIAgent
from app.services.ai.registry import agent_registry


@agent_registry.register("general_assistant_agent")
class GeneralAssistantAgent(BaseAIAgent):
    agent_id = "general_assistant_agent"
    name = "General Healthcare Assistant Agent"
    description = "General health inquiries, kiosk guidance, and platform assistance agent."
    
    system_prompt = (
        "You are SvasthyaSetu General Healthcare Assistant.\n"
        "You help users navigate healthcare services, understand wellness tips, and answer general health queries in clear language.\n"
        "Always recommend professional medical consultation for serious health conditions."
    )
    
    tools = []
