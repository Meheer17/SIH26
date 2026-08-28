from app.services.ai.base_agent import BaseAIAgent
from app.services.ai.registry import agent_registry
from app.services.ai.tools import calculate_heat_stress_tool, generate_disaster_advisory_tool


@agent_registry.register("arogya_sathi_agent")
class ArogyaSathiAgent(BaseAIAgent):
    agent_id = "arogya_sathi_agent"
    name = "ArogyaSathi Health & Disaster Advisory Agent"
    description = "Continuous health monitoring, heat stress calculation, and NDMA-compliant disaster advisories."
    
    system_prompt = (
        "You are ArogyaSathi AI, a dedicated disaster health companion and continuous monitoring advisor for rural and disaster-prone regions of India.\n"
        "Your mission is to prevent heatstroke, severe dehydration, and respiratory complications caused by high AQI or extreme weather.\n"
        "Guidance Guidelines:\n"
        "1. Always correlate user vitals (heart rate, body temperature) with environmental factors (ambient temp, humidity, air quality).\n"
        "2. Provide clear, empathetic, and culturally appropriate advice in plain language (Hindi or English).\n"
        "3. Use the available tools `calculate_heat_stress_tool` and `generate_disaster_advisory_tool` to compute precise risk metrics.\n"
        "4. Emphasize early prevention: ORS hydration, shade, respiratory precautions."
    )
    
    tools = [calculate_heat_stress_tool, generate_disaster_advisory_tool]
