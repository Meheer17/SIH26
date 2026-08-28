from typing import List
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    PROJECT_NAME: str = "SIH 2026 Unified Platform API"
    VERSION: str = "1.0.0"
    API_V1_STR: str = "/api/v1"
    
    # JWT Auth Configuration
    SECRET_KEY: str = "svasthya_setu_super_secret_jwt_key_2026_sih_production"
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 60 * 24 * 7  # 7 days
    
    # MongoDB Configuration
    MONGODB_URL: str = "mongodb://localhost:27017"
    MONGODB_DB_NAME: str = "svasthya_setu_db"

    # CORS Origins allowed to communicate with this backend
    ALLOWED_ORIGINS: List[str] = [
        "http://localhost:3000",
        "http://127.0.0.1:3000",
        "http://localhost:8080",
        "http://localhost",
        "*"
    ]

    # AWS Bedrock Mantle / OpenAI Model Credentials
    OPENAI_API_KEY: str = ""
    OPENAI_BASE_URL: str = "https://bedrock-mantle.ap-south-1.api.aws/v1"
    DEFAULT_LLM_MODEL: str = "mistral.ministral-3-8b-instruct"

    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        case_sensitive=True
    )


settings = Settings()

