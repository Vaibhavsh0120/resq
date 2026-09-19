from fastapi.testclient import TestClient

from app.main import app


def test_health_exposes_service_and_provider() -> None:
    response = TestClient(app).get("/v1/health")

    assert response.status_code == 200
    assert response.json()["service"] == "resq-api"
    assert response.json()["ai_provider"] in {"openai", "openai_compatible"}
