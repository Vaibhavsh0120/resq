from __future__ import annotations

import os
import json

import firebase_admin
from firebase_admin import credentials, firestore

from ..config import get_settings


def ensure_firebase() -> None:
    settings = get_settings()
    if settings.firebase_auth_emulator_host:
        os.environ.setdefault(
            "FIREBASE_AUTH_EMULATOR_HOST", settings.firebase_auth_emulator_host
        )
    if settings.firestore_emulator_host:
        os.environ.setdefault("FIRESTORE_EMULATOR_HOST", settings.firestore_emulator_host)
    if not firebase_admin._apps:
        credential = (
            credentials.Certificate(json.loads(settings.firebase_service_account_json))
            if settings.firebase_service_account_json else None
        )
        firebase_admin.initialize_app(credential, options={"projectId": settings.firebase_project_id})


def firestore_client():
    ensure_firebase()
    return firestore.client()
