import os

from fastapi import APIRouter
from fastapi.responses import JSONResponse

from ...config import get_settings

router = APIRouter(tags=["operations"])


@router.get("/health")
async def health() -> JSONResponse:
    settings = get_settings()
    configured = settings.app_env != "production" or bool(
        settings.firebase_service_account_json and settings.cloudinary_url
    )
    return JSONResponse(status_code=200 if configured else 503, content={
        "status": "ok" if configured else "degraded",
        "service": "resq-api",
        "environment": settings.app_env,
        "ai_available": bool(settings.ai_api_key),
        "commit": settings.resq_release_commit or os.getenv("VERCEL_GIT_COMMIT_SHA") or os.getenv("RENDER_GIT_COMMIT", "local"),
    })
