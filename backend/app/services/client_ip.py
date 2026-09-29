"""Use the Render/Cloudflare edge IP only when that deployment is configured."""

from ipaddress import ip_address

from fastapi import Request

from ..config import Settings


def client_ip(request: Request, settings: Settings) -> str:
    if settings.app_env == "production" and settings.trust_cloudflare_client_ip:
        edge_ip = request.headers.get("cf-connecting-ip", "").strip()
        try:
            if edge_ip:
                return str(ip_address(edge_ip))
        except ValueError:
            pass
    return request.client.host if request.client else "unknown"
