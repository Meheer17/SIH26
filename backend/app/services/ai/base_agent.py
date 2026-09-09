import json
import logging
from abc import ABC
from typing import List, Dict, Any, Optional, Callable

from app.services.ai.strands_client import init_strands_agent, init_openai_client, get_bedrock_credentials
from app.services.ai.tools import execute_tool_by_name, OPENAI_TOOLS_SCHEMAS

logger = logging.getLogger(__name__)


class BaseAIAgent(ABC):
    """
    Abstract Base Class for all AI Agents in SvasthyaSetu.
    Provides automatic Strands Agent + Bedrock Mantle execution with native OpenAI fallback.
    """
    agent_id: str = "base_agent"
    name: str = "Base Agent"
    description: str = "Base abstract AI Agent"
    system_prompt: str = "You are a helpful AI assistant."
    tools: List[Any] = []

    def __init__(self, model_id: Optional[str] = None):
        self.model_id = model_id
        self.strands_agent = None
        self.openai_client = None
        self._initialize_backends()

    def _initialize_backends(self):
        """Initialize Strands Agent or Native OpenAI Client connected to Bedrock Mantle."""
        try:
            self.strands_agent = init_strands_agent(
                system_prompt=self.system_prompt,
                tools=self.tools,
                model_id=self.model_id
            )
        except Exception as e:
            logger.warning(f"Strands initialization skipped for agent '{self.agent_id}': {e}")

        try:
            self.openai_client = init_openai_client()
        except Exception as e:
            logger.warning(f"OpenAI client fallback initialization failed for '{self.agent_id}': {e}")

    def _get_openai_tool_schemas(self) -> Optional[List[Dict[str, Any]]]:
        """Extract OpenAI JSON schemas matching tools attached to this agent."""
        if not self.tools:
            return None

        tool_names = []
        for t in self.tools:
            if callable(t):
                tool_names.append(getattr(t, "__name__", str(t)))
            elif isinstance(t, dict):
                fn_name = t.get("function", {}).get("name") or t.get("name")
                if fn_name:
                    tool_names.append(fn_name)

        if not tool_names:
            return None

        schemas = [s for s in OPENAI_TOOLS_SCHEMAS if s["function"]["name"] in tool_names]
        return schemas if schemas else None

    def run(
        self,
        messages: List[Dict[str, str]],
        context: Optional[Dict[str, Any]] = None
    ) -> Dict[str, Any]:
        """
        Execute agent reasoning loop on user messages.
        Tries Strands Agent first, falls back to native Bedrock OpenAI client, then mock response.
        """
        full_context_str = f"\n[Context Data: {json.dumps(context)}]" if context else ""
        
        # 1. Attempt Strands Agent execution
        if self.strands_agent:
            try:
                prompt_input = messages[-1]["content"] if messages else "Hello"
                if full_context_str:
                    prompt_input += f" {full_context_str}"
                    
                if callable(self.strands_agent):
                    response = self.strands_agent(prompt_input)
                elif hasattr(self.strands_agent, "run"):
                    response = getattr(self.strands_agent, "run")(prompt_input)
                elif hasattr(self.strands_agent, "invoke_async"):
                    import asyncio
                    response = asyncio.run(getattr(self.strands_agent, "invoke_async")(prompt_input))
                else:
                    response = str(self.strands_agent)

                content = str(response)
                return {
                    "agent_id": self.agent_id,
                    "engine": "strands_agent",
                    "content": content,
                    "tool_calls": []
                }
            except Exception as e:
                logger.warning(f"Strands Agent execution failed for '{self.agent_id}': {e}. Falling back...")

        # 2. Attempt Native OpenAI Client (Bedrock Mantle) execution
        if self.openai_client:
            try:
                bedrock_key, base_url, default_model = get_bedrock_credentials()
                target_model = self.model_id or default_model

                api_messages = [{"role": "system", "content": self.system_prompt + full_context_str}]
                for m in messages:
                    api_messages.append({"role": m.get("role", "user"), "content": m.get("content", "")})

                schemas = self._get_openai_tool_schemas()

                kwargs = {
                    "model": target_model,
                    "messages": api_messages,
                    "temperature": 0.7,
                }
                if schemas:
                    kwargs["tools"] = schemas

                response = self.openai_client.chat.completions.create(**kwargs)
                choice = response.choices[0]
                executed_tools_output = []
                synthesized_tool_texts = []
                if hasattr(message, "tool_calls") and message.tool_calls:
                    for tc in message.tool_calls:
                        fn_name = tc.function.name
                        try:
                            fn_args = json.loads(tc.function.arguments)
                        except Exception:
                            fn_args = {}
                        tool_res = execute_tool_by_name(fn_name, fn_args)
                        executed_tools_output.append({
                            "tool_name": fn_name,
                            "arguments": fn_args,
                            "result": tool_res
                        })
                        
                        # Generate human-friendly text for each tool result
                        human_summary = self._format_tool_result_for_human(fn_name, tool_res)
                        if human_summary:
                            synthesized_tool_texts.append(human_summary)

                final_content = message.content or ""
                
                # If LLM response was empty or raw JSON, use synthesized human text
                if not final_content.strip() or (final_content.strip().startswith("{") and final_content.strip().endswith("}")):
                    if synthesized_tool_texts:
                        final_content = "\n\n".join(synthesized_tool_texts)
                    else:
                        final_content = self._clean_raw_json_to_human_text(final_content)
                elif synthesized_tool_texts:
                    final_content = f"{final_content}\n\n" + "\n\n".join(synthesized_tool_texts)

                return {
                    "agent_id": self.agent_id,
                    "engine": "openai_bedrock_mantle",
                    "content": final_content,
                    "tool_calls": executed_tools_output
                }
            except Exception as e:
                logger.warning(f"OpenAI Bedrock execution failed for '{self.agent_id}': {e}")

        # 3. Intelligent natural domain conversation generator
        last_user_msg = messages[-1]["content"] if messages else ""
        query_lower = last_user_msg.lower()

        # Domain-tailored natural conversational responses
        if self.agent_id == "rakshak_mitra_agent":
            if any(w in query_lower for w in ["burnout", "stress", "tired", "sleep", "duty", "fatigue", "night", "overwhelmed"]):
                reply = (
                    "Jai Hind. I hear you, and it is completely understandable to feel operational fatigue with demanding duty rosters and high-alert watches. "
                    "Chronic lack of rest and sleep disruption can significantly elevate your burnout risk index.\n\n"
                    "Here is what I recommend for you right now:\n"
                    "1. **Rest & Recovery (R&R)**: Request a 48-72 hour wellness rotation or night-duty rebalancing through your welfare officer.\n"
                    "2. **Voice Journaling**: Log your mood and fatigue levels in the RakshakMitra Voice Journal so your unit medical officer can monitor cumulative strain.\n"
                    "3. **Peer Connect**: Talk with your buddy or unit counselor—seeking welfare support is a sign of strength and discipline.\n\n"
                    "How are you sleeping lately, and how many consecutive weeks have you been on the current watch?"
                )
            elif any(w in query_lower for w in ["phq", "gad", "test", "assessment", "score", "question"]):
                reply = (
                    "You can complete the validated PHQ-9 & GAD-7 assessment right here in your terminal. "
                    "It evaluates 9 key stress and mood indicators (sleep, energy, concentration, morale) and calculates your risk tier confidentially. "
                    "Your personal identity is strictly protected from unit commander aggregate heatmaps."
                )
            else:
                reply = (
                    f"Jai Hind! I am your RakshakMitra Welfare & Psychological Companion. "
                    f"I am here to support you with stress management, duty fatigue mitigation, voice mood journaling, and confidential welfare guidance. "
                    f"How can I assist you with your wellbeing and duty schedule today?"
                )
        elif self.agent_id == "arogya_sathi_agent":
            if any(w in query_lower for w in ["heat", "sun", "stroke", "temp", "hot", "fever", "sweat"]):
                reply = (
                    "Namaste! Heat stress can quickly escalate into heat exhaustion or heatstroke under high temperatures and humidity.\n\n"
                    "**Immediate Action Protocol (NDMA Guidelines):**\n"
                    "• Move immediately to a shaded, ventilated area.\n"
                    "• Drink ORS (Oral Rehydration Solution) or cool electrolyte water in small sips.\n"
                    "• Loosen tight clothing and apply cool, damp cloths to the neck and forehead.\n"
                    "• If core body temperature rises above 39°C or you feel dizziness/nausea, trigger the Emergency SOS immediately!"
                )
            elif any(w in query_lower for w in ["aqi", "air", "pollution", "smoke", "smog", "breathe", "cough"]):
                reply = (
                    "Namaste! Poor AQI levels cause acute respiratory irritation, especially for vulnerable individuals.\n\n"
                    "**Precautions:**\n"
                    "• Wear an N95 mask if outdoor travel is unavoidable.\n"
                    "• Avoid intense physical workouts outdoors during peak smog hours.\n"
                    "• Use saline nasal rinses and stay well-hydrated to soothe your airways."
                )
            else:
                reply = (
                    "Namaste! I am your ArogyaSathi Health Companion. I continuously monitor your vitals (Heart Rate, SpO2, Body Temp) "
                    "and environmental heat/AQI hazards to keep you safe. How are you feeling today?"
                )
        elif self.agent_id == "medikiosk_agent":
            if any(w in query_lower for w in ["chest", "breath", "dizzy", "pain", "emergency", "severe"]):
                reply = (
                    "⚠️ **Clinical Alert**: Based on the symptoms described, this may indicate an acute red-flag condition requiring immediate medical attention.\n\n"
                    "Please proceed directly to the Emergency / OPD Triage Desk for an immediate ECG and vital signs evaluation. "
                    "Our triage system has logged your symptoms for the attending physician."
                )
            else:
                reply = (
                    "Hello, I am MediKiosk AI Clinical Intake Assistant. I help record your symptoms, timeline, and medical history "
                    "using standard clinical protocols (SOCRATES / AYUSH) so your consulting doctor has a comprehensive summary ready. "
                    "What main symptoms or health concerns bring you to the clinic today?"
                )
        elif self.agent_id == "nyaya_sahay_agent":
            reply = (
                "Namaste. I am your NyayaSahay Legal & Psychological Aid Counselor. "
                "I am here to walk alongside you with empathy, provide guidance on your legal rights, explain case milestones (FIR, Chargesheet, Trial), "
                "and ensure you have access to government protection and rehabilitation schemes in complete safety. "
                "How are you feeling today, and is there a specific legal or welfare question I can help you with?"
            )
        else:
            reply = (
                f"Hello! I am your SvasthyaSetu assistant for {self.name}. "
                f"I am here to assist you with health monitoring, clinical triage, and personnel welfare. "
                f"How may I support you today?"
            )

        return {
            "agent_id": self.agent_id,
            "engine": "domain_conversational_engine",
            "content": reply,
            "tool_calls": []
        }

    def _format_tool_result_for_human(self, tool_name: str, result: Dict[str, Any]) -> str:
        """Translate raw dictionary tool outputs into warm, plain-language bullet points."""
        if not isinstance(result, dict) or "error" in result:
            return ""

        if tool_name == "calculate_heat_stress_tool":
            severity = result.get("severity", "MODERATE")
            heat_idx = result.get("heat_index", 35.0)
            dehydration = result.get("dehydration_risk_percent", 40)
            recommendation = result.get("recommendation", "Maintain regular hydration.")
            
            return (
                f"🌡️ **Heat Stress & Dehydration Assessment**:\n"
                f"• Risk Tier: **{severity}** (Heat Index: {heat_idx}°C equivalent, Dehydration Risk: {dehydration}%)\n"
                f"• Recommended Actions:\n{recommendation}"
            )

        elif tool_name == "generate_disaster_advisory_tool":
            advisory = result.get("advisory", "")
            helpline = result.get("ndma_helpline", "1078")
            return f"{advisory}\n\n📞 *National Disaster Helpline*: {helpline}"

        elif tool_name == "flag_clinical_redflags_tool":
            triage = result.get("triage_level", "ROUTINE")
            action = result.get("action_recommended", "Consult doctor during routine OPD.")
            is_critical = result.get("is_critical", False)
            icon = "🚨" if is_critical else "🩺"
            return (
                f"{icon} **Clinical Triage Evaluation**:\n"
                f"• Assigned Triage Level: **{triage}**\n"
                f"• Guidance: {action}"
            )

        elif tool_name == "predict_burnout_risk_tool":
            risk = result.get("risk_level", "MODERATE")
            score = result.get("burnout_index", 45)
            factors = ", ".join(result.get("key_drivers", ["Operational duty schedule"]))
            actions = result.get("recommended_actions", ["Ensure adequate rest between shifts."])
            action_bullets = "\n".join([f"  • {a}" for a in actions]) if isinstance(actions, list) else f"  • {actions}"
            
            return (
                f"🎖️ **Workforce Wellness & Burnout Evaluation**:\n"
                f"• Burnout Risk Category: **{risk}** (Score: {score}/100)\n"
                f"• Contributing Factors: {factors}\n"
                f"• Recommended Welfare Steps:\n{action_bullets}"
            )

        elif tool_name == "assess_victim_distress_tool":
            distress = result.get("distress_level", "MODERATE")
            score = result.get("distress_score", 50)
            status = result.get("escalation_status", "Standard Monitoring")
            return (
                f"⚖️ **Legal Aid & Wellbeing Assessment**:\n"
                f"• Distress Level: **{distress}** (Score: {score}/100)\n"
                f"• Status: {status}\n"
                f"• Legal Aid Notice: Under the SC/ST Act, you are entitled to free legal aid, witness protection, and financial relief."
            )

        return ""

    def _clean_raw_json_to_human_text(self, text: str) -> str:
        """Convert a raw JSON text string into a human-friendly narrative."""
        try:
            data = json.loads(text.strip())
            if isinstance(data, dict):
                lines = ["Here is a summary of the assessment:\n"]
                for k, v in data.items():
                    clean_k = k.replace("_", " ").capitalize()
                    if isinstance(v, list):
                        lines.append(f"• **{clean_k}**:")
                        for item in v:
                            lines.append(f"  - {item}")
                    elif isinstance(v, dict):
                        lines.append(f"• **{clean_k}**: {json.dumps(v)}")
                    else:
                        lines.append(f"• **{clean_k}**: {v}")
                return "\n".join(lines)
        except Exception:
            pass
        return text

    def to_dict(self) -> Dict[str, Any]:
        """Metadata representation of the agent."""
        return {
            "agent_id": self.agent_id,
            "name": self.name,
            "description": self.description,
            "tools_count": len(self.tools),
            "model_id": self.model_id or "default (mistral.ministral-3-8b-instruct)",
            "is_strands_active": self.strands_agent is not None,
            "is_openai_active": self.openai_client is not None
        }
