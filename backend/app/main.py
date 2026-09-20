from uuid import uuid4

from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware

from .api.routes import ai, circles, devices, health, reports, sos
from .config import get_settings

settings = get_settings()
app = FastAPI(title="ResQ API", version="0.1.0")
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.cors_origins,
    allow_credentials=True,
    allow_methods=["GET", "POST", "OPTIONS"],
    allow_headers=["Authorization", "Content-Type", "X-Request-ID"],
)


@app.middleware("http")
async def request_id(request: Request, call_next):
    response = await call_next(request)
    response.headers["X-Request-ID"] = request.headers.get("X-Request-ID", str(uuid4()))
    return response


app.include_router(health.router, prefix="/v1")
app.include_router(ai.router, prefix="/v1")
app.include_router(reports.router, prefix="/v1")
app.include_router(circles.router, prefix="/v1")
app.include_router(sos.router, prefix="/v1")
app.include_router(devices.router, prefix="/v1")
