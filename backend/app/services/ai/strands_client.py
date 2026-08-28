import os
import logging
from typing import Optional, List, Dict, Any

from app.core.config import settings

# Logger setup
logger = logging.getLogger(__name__)

# Check Strands availability
IS_STRANDS_AVAILABLE = False
StrandsAgent = None
StrandsOpenAIModel = None

try:
    from strands import Agent as StrandsAgent
    from strands.models.openai import OpenAIModel as StrandsOpenAIModel
    IS_STRANDS_AVAILABLE = True
    logger.info("Strands SDK is available.")
except ImportError:
    try:
        from strands_agents import Agent as StrandsAgent
        from strands_agents.models.openai import OpenAIModel as StrandsOpenAIModel
        IS_STRANDS_AVAILABLE = True
        logger.info("Strands Agents SDK is available.")
    except ImportError:
        IS_STRANDS_AVAILABLE = False
        logger.info("Strands SDK is not installed. Native OpenAI fallback will be used.")

# Check OpenAI availability
IS_OPENAI_AVAILABLE = False
openai_module = None

try:
    import openai
    openai_module = openai
    IS_OPENAI_AVAILABLE = True
except ImportError:
    IS_OPENAI_AVAILABLE = False
    logger.warning("OpenAI SDK is not installed.")


def get_bedrock_credentials():
    """Retrieve Bedrock Mantle API key and base URL from environment or settings."""
    bedrock_key = os.getenv("OPENAI_API_KEY", settings.OPENAI_API_KEY)
    base_url = os.getenv("OPENAI_BASE_URL", settings.OPENAI_BASE_URL)
    model_id = os.getenv("DEFAULT_LLM_MODEL", settings.DEFAULT_LLM_MODEL)
    return bedrock_key, base_url, model_id


def init_strands_agent(
    system_prompt: str,
    tools: Optional[List[Any]] = None,
    model_id: Optional[str] = None
) -> Optional[Any]:
    """
    Initialize a Strands Agent backed by AWS Bedrock Mantle OpenAIModel.
    """
    if not IS_STRANDS_AVAILABLE or StrandsAgent is None or StrandsOpenAIModel is None:
        logger.debug("Strands SDK unavailable, skipping strands initialization.")
        return None

    bedrock_key, base_url, default_model = get_bedrock_credentials()
    target_model = model_id or default_model
    tools_list = tools or []

    try:
        llm_model = StrandsOpenAIModel(
            model_id=target_model,
            client_args={
                "base_url": base_url,
                "api_key": bedrock_key or "dummy_key_for_initialization",
                "timeout": 30.0,
                "max_retries": 2
            }
        )
        agent = StrandsAgent(
            model=llm_model,
            tools=tools_list,
            system_prompt=system_prompt
        )
        logger.info(f"Successfully initialized Strands Agent with model '{target_model}' on Bedrock Mantle!")
        return agent
    except Exception as e:
        logger.warning(f"Could not initialize Strands Agent: {e}")
        return None


def init_openai_client() -> Optional[Any]:
    """
    Initialize native OpenAI client pointing to Bedrock Mantle endpoint.
    """
    if not IS_OPENAI_AVAILABLE or openai_module is None:
        return None

    bedrock_key, base_url, _ = get_bedrock_credentials()
    try:
        client = openai_module.OpenAI(
            base_url=base_url,
            api_key=bedrock_key or "dummy_key_for_initialization",
            timeout=30.0,
            max_retries=2
        )
        logger.info("Successfully initialized native OpenAI client for Bedrock Mantle.")
        return client
    except Exception as e:
        logger.warning(f"Could not initialize native OpenAI client: {e}")
        return None
