from fastapi import APIRouter

from ...ai.providers.factory import get_ai_provider
from ...config import get_settings

router = APIRouter(tags=["operations"])


@router.get("/health")
async def health() -> dict[str, str]:
    settings = get_settings()
    return {
        "status": "ok",
        "service": "resq-api",
        "environment": settings.app_env,
        "ai_provider": get_ai_provider().name,
    }
