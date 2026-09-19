from __future__ import annotations

import firebase_admin
from firebase_admin import firestore

from ..config import get_settings


def ensure_firebase() -> None:
    if not firebase_admin._apps:
        firebase_admin.initialize_app(options={"projectId": get_settings().firebase_project_id})


def firestore_client():
    ensure_firebase()
    return firestore.client()
