from functools import lru_cache
from typing import Literal

from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env", extra="ignore")

    app_env: Literal["development", "staging", "production"] = "development"
    resq_release_commit: str = ""
    ai_provider: Literal["openai", "groq", "gemini", "claude", "openai_compatible"] = "openai"
    ai_api_key: str = ""
    ai_base_url: str | None = None
    ai_text_model: str = ""
    firebase_project_id: str = "resq-106ed"
    firebase_service_account_json: str = ""
    firebase_auth_emulator_host: str = ""
    firestore_emulator_host: str = ""
    allowed_origins: str = "http://localhost:3000,http://localhost:8080"
    app_universal_link_base: str = "https://resq-106ed.web.app/invite"
    cloudinary_url: str = ""
    local_upload_dir: str = ".local/uploads"
    ndma_feed_url: str = "https://sachet.ndma.gov.in/cap_public_website/rss/rss_india.xml"
    imd_district_warning_url: str = "https://mausam.imd.gov.in/api/warnings_district_api.php?id={id}"
    imd_district_ids: str = ""
    admin_api_key: str = ""
    clamav_host: str = ""
    clamav_port: int = 3310
    rate_limit_per_minute: int = 120
    ai_rate_limit_per_minute: int = 30
    ai_guest_daily_limit: int = 5
    ai_guest_ip_daily_limit: int = 30
    ai_registered_daily_limit: int = 20
    trust_cloudflare_client_ip: bool = False

    @property
    def cors_origins(self) -> list[str]:
        return [origin.strip() for origin in self.allowed_origins.split(",") if origin.strip()]


@lru_cache
def get_settings() -> Settings:
    return Settings()
