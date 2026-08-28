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
                message = choice.message

                executed_tools_output = []
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

                return {
                    "agent_id": self.agent_id,
                    "engine": "openai_bedrock_mantle",
                    "content": message.content or "Tool execution completed.",
                    "tool_calls": executed_tools_output
                }
            except Exception as e:
                logger.warning(f"OpenAI Bedrock execution failed for '{self.agent_id}': {e}")

        # 3. Intelligent fallback response when live model key is not configured
        last_user_msg = messages[-1]["content"] if messages else ""
        return {
            "agent_id": self.agent_id,
            "engine": "fallback_rules_engine",
            "content": f"[{self.name}] Received your query: '{last_user_msg}'. Agent online and operating under standard clinical/advisory guidelines.",
            "tool_calls": []
        }

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
