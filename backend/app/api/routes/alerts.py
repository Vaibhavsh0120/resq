from datetime import UTC, datetime
from math import isfinite

from fastapi import APIRouter

from ...integrations.firebase import firestore_client
from ...integrations.official_alerts import matches_region
from ..dependencies import CurrentUser

router = APIRouter(prefix="/alerts", tags=["alerts"])


def _home_center(home: dict) -> dict[str, float] | None:
    latitude, longitude = home.get("latitude"), home.get("longitude")
    if isinstance(latitude, bool) or isinstance(longitude, bool):
        return None
    if not isinstance(latitude, (int, float)) or not isinstance(longitude, (int, float)):
        return None
    latitude, longitude = float(latitude), float(longitude)
    if not isfinite(latitude) or not isfinite(longitude) or not (6 <= latitude <= 38 and 68 <= longitude <= 98):
        return None
    return {"latitude": latitude, "longitude": longitude}


@router.get("/india")
async def india_events(user: CurrentUser) -> dict:
    """India-impacting GDACS events, independent of a user's home region."""
    database = firestore_client()
    now = datetime.now(UTC)
    documents = list(
        database.collection("indiaEvents")
        .where("relevanceEndsAt", ">", now)
        .order_by("relevanceEndsAt")
        .limit(200)
        .stream()
    )
    items = [{"id": item.id, **(item.to_dict() or {})} for item in documents]
    items.sort(key=lambda item: item.get("updatedAt") or now, reverse=True)
    health = database.collection("ingestionState").document("gdacs").get().to_dict() or {}
    return {
        "items": items[:50],
        "sourceHealth": {
            "source": "GDACS",
            "status": health.get("status", "not_run"),
            "lastCheckedAt": health.get("lastCheckedAt"),
            "lastSuccessAt": health.get("lastSuccessAt"),
            "truncated": bool(health.get("truncated")) or len(documents) >= 200,
        },
    }


@router.get("/nearby")
async def nearby_alerts(user: CurrentUser) -> dict:
    database = firestore_client()
    profile = database.collection("users").document(user.uid).get().to_dict() or {}
    home = profile.get("homeLocation") or {}
    state = str(home.get("state") or "").strip().casefold()
    city = str(home.get("city") or "").strip().casefold()
    home_center = _home_center(home) if state else None
    source_health = []
    for source in ("ndma", "imd"):
        item = database.collection("ingestionState").document(source).get().to_dict() or {}
        source_health.append(
            {"source": source.upper(), "status": item.get("status", "not_run"),
             "lastCheckedAt": item.get("lastCheckedAt"), "truncated": item.get("truncated", False)}
        )
    if not state:
        return {"items": [], "sourceHealth": source_health, "coverage": "home_region_missing", "homeCenter": None}
    now = datetime.now(UTC)
    documents = list(
        database.collection("publicAlerts")
        .where("verified", "==", True)
        .where("states", "array_contains", state)
        .where("expiresAt", ">", now)
        .order_by("expiresAt")
        .limit(201)
        .stream()
    )
    alerts = [
        {"id": item.id, **data}
        for item in documents[:200]
        if matches_region((data := item.to_dict() or {}), city=city, state=state)
    ]
    alerts.sort(key=lambda item: item.get("issuedAt") or now, reverse=True)
    return {
        "items": alerts, "sourceHealth": source_health,
        "coverage": "limited" if len(documents) > 200 else "matched",
        "homeCenter": home_center,
    }
