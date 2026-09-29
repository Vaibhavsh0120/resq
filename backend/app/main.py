from collections import defaultdict, deque
import json
import logging
import time
from uuid import uuid4

from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse

from .api.routes import account, admin, ai, alerts, circles, devices, health, places, reports, sos
from .config import get_settings
from .services.client_ip import client_ip

settings = get_settings()
logger = logging.getLogger("resq.api")
logging.basicConfig(level=logging.INFO, format="%(message)s")
_request_windows: dict[str, deque[float]] = defaultdict(deque)
app = FastAPI(title="ResQ API", version="0.1.0")
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.cors_origins,
    allow_credentials=True,
    allow_methods=["GET", "POST", "DELETE", "OPTIONS"],
    allow_headers=["Authorization", "Content-Type", "X-Request-ID"],
)


@app.middleware("http")
async def request_id(request: Request, call_next):
    started = time.monotonic()
    request_id = request.headers.get("X-Request-ID", str(uuid4()))
    client = client_ip(request, settings)
    bucket = f"{client}:{'ai' if request.url.path.startswith('/v1/ai/') else 'api'}"
    limit = (
        settings.ai_rate_limit_per_minute
        if request.url.path.startswith("/v1/ai/")
        else settings.rate_limit_per_minute
    )
    now = time.monotonic()
    window = _request_windows[bucket]
    while window and window[0] <= now - 60:
        window.popleft()
    safety_route = request.url.path == "/v1/sos" or (
        request.url.path.startswith("/v1/circles/")
        and request.url.path.endswith("/check-ins")
    )
    if not safety_route and len(window) >= limit:
        response = JSONResponse(
            status_code=429,
            content={
                "detail": {"code": "rate_limited", "requestId": request_id}
            },
            headers={"Retry-After": "60"},
        )
    else:
        if not safety_route:
            window.append(now)
        response = await call_next(request)
    response.headers["X-Request-ID"] = request_id
    logger.info(
        json.dumps(
            {
                "event": "http_request",
                "requestId": request_id,
                "method": request.method,
                "path": request.url.path,
                "status": response.status_code,
                "durationMs": round((time.monotonic() - started) * 1000, 2),
            }
        )
    )
    return response


app.include_router(health.router, prefix="/v1")
app.include_router(ai.router, prefix="/v1")
app.include_router(reports.router, prefix="/v1")
app.include_router(circles.router, prefix="/v1")
app.include_router(sos.router, prefix="/v1")
app.include_router(devices.router, prefix="/v1")
app.include_router(places.router, prefix="/v1")
app.include_router(admin.router, prefix="/v1")
app.include_router(account.router, prefix="/v1")
app.include_router(alerts.router, prefix="/v1")
