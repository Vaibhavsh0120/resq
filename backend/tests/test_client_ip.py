from starlette.requests import Request

from app.config import Settings
from app.services.client_ip import client_ip


def _request(headers):
    return Request({
        "type": "http", "method": "GET", "path": "/v1/ai/capabilities",
        "headers": [(key.encode(), value.encode()) for key, value in headers.items()],
        "client": ("10.0.0.7", 1234), "scheme": "https", "server": ("example", 443),
    })


def test_production_uses_single_valid_edge_ip_and_ignores_spoofed_xff():
    settings = Settings(app_env="production", trust_cloudflare_client_ip=True)
    assert client_ip(_request({"cf-connecting-ip": "203.0.113.9", "x-forwarded-for": "1.2.3.4"}), settings) == "203.0.113.9"
    assert client_ip(_request({"cf-connecting-ip": "203.0.113.9, 1.2.3.4"}), settings) == "10.0.0.7"


def test_development_ignores_edge_header():
    settings = Settings(app_env="development", trust_cloudflare_client_ip=True)
    assert client_ip(_request({"cf-connecting-ip": "203.0.113.9"}), settings) == "10.0.0.7"
