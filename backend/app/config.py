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
    firebase_auth_emulator_host: str = ""
    firestore_emulator_host: str = ""
    allowed_origins: str = "http://localhost:3000,http://localhost:8080"
    app_universal_link_base: str = "https://resq.app/invite"
    object_storage_endpoint: str = ""
    object_storage_region: str = ""
    object_storage_bucket: str = ""
    object_storage_access_key: str = ""
    object_storage_secret_key: str = ""
    local_upload_dir: str = ".local/uploads"
    ndma_feed_url: str = ""
    imd_district_warning_url: str = ""
    imd_district_ids: str = ""
    admin_api_key: str = ""
    clamav_host: str = ""
    clamav_port: int = 3310
    rate_limit_per_minute: int = 120
    ai_rate_limit_per_minute: int = 30

    @property
    def cors_origins(self) -> list[str]:
        return [origin.strip() for origin in self.allowed_origins.split(",") if origin.strip()]


@lru_cache
def get_settings() -> Settings:
    return Settings()
