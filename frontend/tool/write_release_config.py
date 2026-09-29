"""Write build-time, public Flutter defines after validating production URL."""

from __future__ import annotations

import json
import os
import sys
from pathlib import Path
from urllib.parse import urlparse


def main() -> None:
    if len(sys.argv) != 2:
        raise SystemExit("Usage: write_release_config.py OUTPUT_PATH")
    api_url = os.getenv("RESQ_API_BASE_URL", "").rstrip("/")
    parsed = urlparse(api_url)
    hostname = (parsed.hostname or "").lower()
    if (
        parsed.scheme != "https"
        or not hostname
        or parsed.username
        or parsed.password
        or hostname in {"localhost", "127.0.0.1", "::1"}
        or any(part in hostname for part in ("placeholder", "example", "invalid"))
    ):
        raise SystemExit("RESQ_API_BASE_URL must be the deployed HTTPS API URL")
    config = {
        "RESQ_APP_ENV": "production",
        "RESQ_API_BASE_URL": api_url,
        "RESQ_USE_FIREBASE_EMULATORS": False,
        "RESQ_FCM_VAPID_KEY": os.getenv("RESQ_FCM_VAPID_KEY", ""),
    }
    destination = Path(sys.argv[1])
    destination.parent.mkdir(parents=True, exist_ok=True)
    destination.write_text(json.dumps(config), encoding="utf-8")
    print(f"Wrote production Flutter config for {parsed.hostname}")


if __name__ == "__main__":
    main()
