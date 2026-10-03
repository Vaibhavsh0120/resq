"""Bounded GDACS projections for India-impacting disaster events."""

from __future__ import annotations

from datetime import UTC, datetime, timedelta
from math import isfinite
from urllib.parse import urlparse

import httpx


GDACS_SEARCH = "https://www.gdacs.org/gdacsapi/api/Events/geteventlist/SEARCH"
EVENT_TYPES = {"EQ", "TC", "FL", "DR", "VO", "WF"}
MAX_FEATURES = 100
RELEVANCE_AFTER_END = timedelta(days=7)


def _datetime(value: object) -> datetime | None:
    if not isinstance(value, str) or not value.strip():
        return None
    try:
        parsed = datetime.fromisoformat(value.strip().replace("Z", "+00:00"))
    except ValueError:
        return None
    return parsed.replace(tzinfo=UTC) if parsed.tzinfo is None else parsed.astimezone(UTC)


def _number(value: object, low: float, high: float) -> float | None:
    if isinstance(value, bool) or not isinstance(value, (int, float)):
        return None
    number = float(value)
    return number if isfinite(number) and low <= number <= high else None


def parse_gdacs_feature(feature: dict, now: datetime) -> dict | None:
    """Accept only recent India-impacting events with genuine GDACS points."""
    if feature.get("type") != "Feature":
        return None
    props = feature.get("properties")
    geometry = feature.get("geometry")
    if not isinstance(props, dict) or not isinstance(geometry, dict) or geometry.get("type") != "Point":
        return None
    coordinates = geometry.get("coordinates")
    if not isinstance(coordinates, list) or len(coordinates) < 2:
        return None
    longitude = _number(coordinates[0], -180, 180)
    latitude = _number(coordinates[1], -90, 90)
    if latitude is None or longitude is None:
        return None

    country = str(props.get("country") or "").strip()
    iso3 = str(props.get("iso3") or "").upper()
    affected = props.get("affectedcountries")
    affected_india = isinstance(affected, list) and any(
        isinstance(item, dict) and str(item.get("iso3") or "").upper() == "IND"
        for item in affected
    )
    if country.casefold() != "india" and iso3 != "IND" and not affected_india:
        return None

    event_type = str(props.get("eventtype") or "").upper()
    event_id = str(props.get("eventid") or "")
    episode_id = str(props.get("episodeid") or "")
    if event_type not in EVENT_TYPES or not event_id.isdecimal() or not episode_id.isdecimal():
        return None
    started = _datetime(props.get("fromdate"))
    ended = _datetime(props.get("todate"))
    updated = _datetime(props.get("datemodified"))
    if not started or not ended or not updated or started > ended:
        return None
    if ended + RELEVANCE_AFTER_END <= now or ended > now + timedelta(days=90):
        return None

    urls = props.get("url")
    report = urls.get("report") if isinstance(urls, dict) else None
    if not isinstance(report, str):
        return None
    parsed_url = urlparse(report)
    if parsed_url.scheme != "https" or parsed_url.hostname not in {"gdacs.org", "www.gdacs.org"} or parsed_url.path != "/report.aspx":
        return None
    title = str(props.get("name") or props.get("eventname") or "").strip()[:160]
    if not title:
        return None

    event_key = f"gdacs-{event_type}-{event_id}-{episode_id}"
    return {
        "id": event_key,
        "title": title,
        "eventType": event_type,
        "latitude": latitude,
        "longitude": longitude,
        "sourceUrl": report,
        "source": "GDACS",
        "countryLabel": "India" if country.casefold() == "india" or iso3 == "IND" else "India-impacting",
        "startedAt": started,
        "endedAt": ended,
        "updatedAt": updated,
        "relevanceEndsAt": ended + RELEVANCE_AFTER_END,
        "alertLevel": str(props.get("alertlevel") or "Unknown").strip()[:24],
    }


async def _fetch_gdacs(now: datetime) -> dict:
    params = {
        "eventlist": ";".join(sorted(EVENT_TYPES)),
        "fromdate": (now - timedelta(days=30)).date().isoformat(),
        "todate": now.date().isoformat(),
        "pagesize": MAX_FEATURES,
    }
    async with httpx.AsyncClient(timeout=20, follow_redirects=False) as client:
        response = await client.get(GDACS_SEARCH, params=params)
        response.raise_for_status()
        if len(response.content) > 2_000_000:
            raise ValueError("GDACS result exceeds processing limit")
        result = response.json()
    if not isinstance(result, dict) or result.get("type") != "FeatureCollection" or not isinstance(result.get("features"), list):
        raise ValueError("GDACS result is not a feature collection")
    return result


def purge_old_india_events(database, *, now: datetime | None = None) -> int:
    """Delete irrelevant events in bounded batches on each refresh."""
    now = now or datetime.now(UTC)
    removed = 0
    for _ in range(10):
        rows = list(database.collection("indiaEvents").where("relevanceEndsAt", "<=", now).limit(500).stream())
        if not rows:
            break
        for row in rows:
            row.reference.delete()
            removed += 1
    return removed


async def ingest_gdacs(database, *, now: datetime | None = None) -> int:
    """Refresh event projections; preserve recent cache on source failure."""
    now = now or datetime.now(UTC)
    state = database.collection("ingestionState").document("gdacs")
    state.set({"lastCheckedAt": now}, merge=True)
    try:
        payload = await _fetch_gdacs(now)
        features = payload["features"]
        count = 0
        for feature in features[:MAX_FEATURES]:
            if not isinstance(feature, dict):
                continue
            item = parse_gdacs_feature(feature, now)
            if item is None:
                continue
            database.collection("indiaEvents").document(item["id"]).set(item)
            count += 1
        state.set({
            "status": "ok", "lastSuccessAt": now, "lastCheckedAt": now,
            "sourceCount": len(features), "storedCount": count,
            "truncated": len(features) >= MAX_FEATURES,
        }, merge=True)
        return count
    except Exception as exc:
        state.set({
            "status": "error", "lastCheckedAt": now,
            "lastError": type(exc).__name__, "lastErrorAt": now,
        }, merge=True)
        raise
    finally:
        purge_old_india_events(database, now=now)
