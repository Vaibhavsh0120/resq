from fastapi.testclient import TestClient

from app.main import app
from app.config import Settings
from app.api.routes import health as health_route


def test_health_exposes_service_and_provider() -> None:
    response = TestClient(app).get("/v1/health")

    assert response.status_code == 200
    assert response.json()["service"] == "resq-api"
    assert "ai_provider" not in response.json()
    assert isinstance(response.json()["ai_available"], bool)


def test_production_health_rejects_missing_core_services(monkeypatch) -> None:
    monkeypatch.setattr(health_route, "get_settings", lambda: Settings(app_env="production", _env_file=None))
    response = TestClient(app).get("/v1/health")
    assert response.status_code == 503
    assert response.json()["status"] == "degraded"
