from datetime import UTC, datetime

from fastapi import APIRouter

from ...integrations.firebase import firestore_client
from ...integrations.official_alerts import matches_region
from ..dependencies import CurrentUser

router = APIRouter(prefix="/alerts", tags=["alerts"])


@router.get("/nearby")
async def nearby_alerts(user: CurrentUser) -> dict:
    database = firestore_client()
    profile = database.collection("users").document(user.uid).get().to_dict() or {}
    home = profile.get("homeLocation") or {}
    state = str(home.get("state") or "").strip().casefold()
    city = str(home.get("city") or "").strip().casefold()
    source_health = []
    for source in ("ndma", "imd"):
        item = database.collection("ingestionState").document(source).get().to_dict() or {}
        source_health.append(
            {"source": source.upper(), "status": item.get("status", "not_run"),
             "lastCheckedAt": item.get("lastCheckedAt"), "truncated": item.get("truncated", False)}
        )
    if not state:
        return {"items": [], "sourceHealth": source_health, "coverage": "home_region_missing"}
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
    }
