import logging
from typing import Dict, Type, List, Any, Optional
from app.services.ai.base_agent import BaseAIAgent

logger = logging.getLogger(__name__)


class AgentRegistry:
    """
    Extensible Registry for AI Agents.
    Allows easy addition of new AI agents into the application ecosystem.
    """

    def __init__(self):
        self._registry: Dict[str, Type[BaseAIAgent]] = {}
        self._instances: Dict[str, BaseAIAgent] = {}

    def register(self, agent_id: Optional[str] = None):
        """
        Decorator or direct method to register an AI Agent class.
        
        Usage as decorator:
            @agent_registry.register("my_custom_agent")
            class MyAgent(BaseAIAgent):
                ...
        """
        def decorator(cls: Type[BaseAIAgent]):
            target_id = agent_id or getattr(cls, "agent_id", cls.__name__.lower())
            self._registry[target_id] = cls
            logger.info(f"Registered AI Agent '{target_id}' -> {cls.__name__}")
            return cls
        return decorator

    def register_class(self, agent_cls: Type[BaseAIAgent], agent_id: Optional[str] = None):
        """Directly register an agent class."""
        target_id = agent_id or getattr(agent_cls, "agent_id", agent_cls.__name__.lower())
        self._registry[target_id] = agent_cls
        logger.info(f"Directly registered AI Agent '{target_id}' -> {agent_cls.__name__}")

    def get_agent(self, agent_id: str, model_id: Optional[str] = None) -> Optional[BaseAIAgent]:
        """
        Get an instantiated AI agent by agent_id.
        Caches instances for reuse or creates a new instance if model_id overrides default.
        """
        if agent_id not in self._registry:
            logger.warning(f"Requested agent '{agent_id}' is not registered.")
            return None

        if model_id:
            # Create fresh instance with model override
            return self._registry[agent_id](model_id=model_id)

        if agent_id not in self._instances:
            self._instances[agent_id] = self._registry[agent_id]()

        return self._instances[agent_id]

    def list_agents(self) -> List[Dict[str, Any]]:
        """List metadata for all registered AI agents."""
        agent_list = []
        for agent_id in self._registry:
            instance = self.get_agent(agent_id)
            if instance:
                agent_list.append(instance.to_dict())
        return agent_list

    def is_registered(self, agent_id: str) -> bool:
        """Check if an agent_id is registered."""
        return agent_id in self._registry


# Global Singleton Registry Instance
agent_registry = AgentRegistry()
