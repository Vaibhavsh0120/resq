from functools import lru_cache
from typing import Literal

from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env", extra="ignore")

    app_env: Literal["development", "staging", "production"] = "development"
    ai_provider: Literal["openai", "openai_compatible"] = "openai"
    ai_api_key: str = ""
    ai_base_url: str | None = None
    ai_text_model: str = "gpt-5.6-luna"
    ai_voice_model: str = "gpt-realtime-2.1"
    firebase_project_id: str = "resq-106ed"
    allowed_origins: str = "http://localhost:3000,http://localhost:8080"
    app_universal_link_base: str = "https://resq.app/invite"

    @property
    def cors_origins(self) -> list[str]:
        return [origin.strip() for origin in self.allowed_origins.split(",") if origin.strip()]


@lru_cache
def get_settings() -> Settings:
    return Settings()
