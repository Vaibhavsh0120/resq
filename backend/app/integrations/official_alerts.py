"""Best-effort official feeds. Only alerts with documented areas enter local views."""

from __future__ import annotations

import hashlib
from datetime import UTC, datetime, timedelta
from email.utils import parsedate_to_datetime
from urllib.parse import urlparse

import feedparser
import httpx
from defusedxml import ElementTree

from ..config import Settings
from .firebase import firestore_client

CAP = "{urn:oasis:names:tc:emergency:cap:1.2}"
INDIAN_STATES = {
    "andaman and nicobar islands", "andhra pradesh", "arunachal pradesh", "assam",
    "bihar", "chandigarh", "chhattisgarh", "dadra and nagar haveli and daman and diu",
    "delhi", "goa", "gujarat", "haryana", "himachal pradesh", "jammu and kashmir",
    "jharkhand", "karnataka", "kerala", "ladakh", "lakshadweep", "madhya pradesh",
    "maharashtra", "manipur", "meghalaya", "mizoram", "nagaland", "odisha",
    "puducherry", "punjab", "rajasthan", "sikkim", "tamil nadu", "telangana",
    "tripura", "uttar pradesh", "uttarakhand", "west bengal",
}
IMD_WARNING_CODES = {
    "2": "Heavy rain", "3": "Heavy snow", "4": "Thunderstorm, lightning or squall",
    "5": "Hailstorm", "6": "Dust storm", "7": "Dust raising winds",
    "8": "Strong surface winds", "9": "Heat wave", "10": "Hot day",
    "11": "Warm night", "12": "Cold wave", "13": "Cold day",
    "14": "Ground frost", "15": "Fog", "16": "Very heavy rain",
    "17": "Extremely heavy rain",
}


def _imd_severity(color: str) -> str:
    normalized = color.strip().casefold()
    return "critical" if normalized in {"1", "red"} else "warning" if normalized in {"2", "orange"} else "info"


def _imd_warning_text(value: str) -> str | None:
    codes = [part.strip() for part in value.split(",") if part.strip()]
    if not codes or codes == ["1"] or any(code not in IMD_WARNING_CODES for code in codes):
        return None
    return ", ".join(IMD_WARNING_CODES[code] for code in codes)


def stable_id(source: str, external_id: str) -> str:
    return hashlib.sha256(f"{source}:{external_id}".encode()).hexdigest()[:32]


def _date(value: str | None) -> datetime | None:
    if not value:
        return None
    try:
        return datetime.fromisoformat(value.replace("Z", "+00:00")).astimezone(UTC)
    except ValueError:
        return None


def _areas(info) -> list[dict[str, str]]:
    result = []
    for area in info.findall(f"{CAP}area"):
        description = (area.findtext(f"{CAP}areaDesc") or "").strip()
        parts = [part.strip() for part in description.split(",") if part.strip()]
        if not parts or parts[-1].casefold() not in INDIAN_STATES:
            continue
        result.append(
            {"description": description, "state": parts[-1].casefold(),
             "district": parts[-2].casefold() if len(parts) > 1 else ""}
        )
    return result


def parse_cap(content: bytes, source_url: str, external_id: str) -> dict | None:
    root = ElementTree.fromstring(content)
    if root.tag != f"{CAP}alert":
        return None
    if root.findtext(f"{CAP}status") != "Actual" or root.findtext(f"{CAP}scope") != "Public":
        return None
    info = next((item for item in root.findall(f"{CAP}info")
                 if (item.findtext(f"{CAP}language") or "en").startswith("en")), None)
    if info is None:
        return None
    expires = _date(info.findtext(f"{CAP}expires"))
    issued = _date(root.findtext(f"{CAP}sent"))
    if not expires or not issued or expires <= datetime.now(UTC):
        return None
    severity = (info.findtext(f"{CAP}severity") or "Unknown").casefold()
    severity = "critical" if severity == "extreme" else "warning" if severity == "severe" else "info"
    areas = _areas(info)
    if not areas:
        return None
    return {
        "source": "NDMA SACHET", "sourceUrl": source_url, "externalId": external_id,
        "title": {"en": info.findtext(f"{CAP}headline") or "Official safety alert"},
        "summary": {"en": info.findtext(f"{CAP}description") or ""},
        "severity": severity, "issuedAt": issued, "expiresAt": expires,
        "affectedArea": "; ".join(item["description"] for item in areas),
        "regions": areas, "states": sorted({item["state"] for item in areas}),
        "verified": True, "ingestedAt": datetime.now(UTC),
    }


async def _cached_get(client: httpx.AsyncClient, database, state_id: str, url: str) -> tuple[bytes, bool]:
    state_ref = database.collection("ingestionState").document(state_id)
    previous = state_ref.get().to_dict() or {}
    headers = {"If-None-Match": previous["etag"]} if previous.get("etag") else {}
    response = await client.get(url, headers=headers)
    now = datetime.now(UTC)
    if response.status_code == 304:
        cached = previous.get("cachedXml")
        if cached is None:
            raise RuntimeError("Official source returned 304 without a local cache")
        state_ref.set({"lastCheckedAt": now, "status": "ok"}, merge=True)
        return cached.encode(), False
    response.raise_for_status()
    if len(response.content) > 850_000:
        raise RuntimeError("Official feed exceeds the safe Firestore cache size")
    state_ref.set(
        {"etag": response.headers.get("etag"), "cachedXml": response.text,
         "lastCheckedAt": now, "lastChangedAt": now, "status": "ok", "url": url},
        merge=True,
    )
    return response.content, True


async def ingest_ndma(settings: Settings) -> int:
    if not settings.ndma_feed_url:
        return 0
    database = firestore_client()
    updated = 0
    async with httpx.AsyncClient(timeout=20, follow_redirects=True) as client:
        try:
            xml, _ = await _cached_get(client, database, "ndma", settings.ndma_feed_url)
            feed = feedparser.parse(xml)
            if feed.bozo:
                raise RuntimeError("SACHET RSS could not be parsed")
            for entry in feed.entries[:100]:
                external_id = entry.get("id") or entry.get("guid")
                url = entry.get("link", "")
                if not external_id or urlparse(url).hostname != "sachet.ndma.gov.in":
                    continue
                try:
                    cap, changed = await _cached_get(client, database, f"cap-{stable_id('ndma', external_id)}", url)
                    ref = database.collection("publicAlerts").document(stable_id("ndma", external_id))
                    if not changed:
                        # A previous run may have cached the CAP but failed before
                        # writing its public projection. Recreate that missing row.
                        if ref.get().exists:
                            parse_cap(cap, url, external_id)
                            continue
                    alert = parse_cap(cap, url, external_id)
                    if alert:
                        ref.set(alert)
                        if alert["severity"] in {"critical", "warning"}:
                            database.collection("emergencyEvents").document(ref.id).set(
                                {"sourceAlertId": ref.id, "title": alert["title"],
                                 "expiresAt": alert["expiresAt"], "issuedAt": alert["issuedAt"],
                                 "source": alert["source"], "status": "active"}, merge=True
                            )
                        updated += 1
                    else:
                        ref.delete()
                except Exception as exc:
                    database.collection("ingestionState").document("ndma").set(
                        {"status": "partial", "lastError": type(exc).__name__, "lastErrorAt": datetime.now(UTC)}, merge=True
                    )
            database.collection("ingestionState").document("ndma").set(
                {"feedEntries": len(feed.entries), "processedLimit": 100,
                 "truncated": len(feed.entries) > 100, "lastRunAt": datetime.now(UTC)}, merge=True
            )
        except Exception as exc:
            database.collection("ingestionState").document("ndma").set(
                {"status": "error", "lastError": type(exc).__name__, "lastErrorAt": datetime.now(UTC)}, merge=True
            )
            raise
    return updated


async def ingest_imd(settings: Settings) -> int:
    if not settings.imd_district_ids:
        firestore_client().collection("ingestionState").document("imd").set(
            {"status": "unconfigured", "lastCheckedAt": datetime.now(UTC)}, merge=True
        )
        return 0
    database = firestore_client()
    updated = 0
    # Entries use id:district:state. The operator must supply the district IDs
    # from IMD's official API list; unknown regions are never shown locally.
    entries = [item.split(":", 2) for item in settings.imd_district_ids.split(",")]
    if len(entries) > 50:
        database.collection("ingestionState").document("imd").set(
            {"status": "error", "truncated": True, "districtsConfigured": len(entries),
             "lastError": "IMD district list exceeds the 50-ID run limit",
             "lastErrorAt": datetime.now(UTC)}, merge=True
        )
        raise ValueError("IMD district list exceeds the 50-ID run limit")
    async with httpx.AsyncClient(timeout=20, follow_redirects=True) as client:
        for entry in entries:
            if len(entry) != 3 or entry[2].strip().casefold() not in INDIAN_STATES:
                continue
            district_id, district, state = [part.strip() for part in entry]
            url = settings.imd_district_warning_url.format(id=district_id)
            response = await client.get(url)
            response.raise_for_status()
            payload = response.json()
            for record in payload if isinstance(payload, list) else [payload]:
                if not isinstance(record, dict):
                    continue
                if str(record.get("Obj_id") or district_id) != district_id:
                    continue
                if str(record.get("District") or district).strip().casefold() != district.casefold():
                    continue
                warning = str(record.get("Day_1") or "").strip()
                warning_text = _imd_warning_text(warning)
                color = str(record.get("Day1_Color") or "").casefold()
                if not warning_text or color not in {"1", "2", "3", "red", "orange", "yellow"}:
                    continue
                issued = datetime.now(UTC)
                severity = _imd_severity(color)
                alert_id = stable_id("imd", f"{district_id}:{issued.date().isoformat()}:{warning}")
                database.collection("publicAlerts").document(alert_id).set(
                    {"source": "India Meteorological Department", "sourceUrl": url,
                     "externalId": district_id, "title": {"en": f"IMD weather warning for {district}"},
                     "summary": {"en": warning_text}, "severity": severity,
                     "issuedAt": issued, "expiresAt": issued + timedelta(days=1),
                     "affectedArea": f"{district}, {state}",
                     "states": [state.casefold()],
                     "regions": [{"description": f"{district}, {state}", "district": district.casefold(), "state": state.casefold()}],
                     "verified": True, "ingestedAt": issued}, merge=True
                )
                if severity in {"critical", "warning"}:
                    database.collection("emergencyEvents").document(alert_id).set(
                        {"sourceAlertId": alert_id, "title": {"en": f"IMD weather warning for {district}"},
                         "expiresAt": issued + timedelta(days=1), "issuedAt": issued,
                         "source": "India Meteorological Department", "status": "active"}, merge=True
                    )
                updated += 1
    database.collection("ingestionState").document("imd").set(
        {"status": "ok", "truncated": False, "lastCheckedAt": datetime.now(UTC),
         "districtsConfigured": len(entries)}, merge=True
    )
    return updated


def matches_region(alert: dict, *, city: str | None, state: str | None) -> bool:
    if not state:
        return False
    state_name = state.strip().casefold()
    city_name = (city or "").strip().casefold()
    for region in alert.get("regions") or []:
        if region.get("state") != state_name:
            continue
        district = region.get("district", "")
        if not district or (city_name and district == city_name):
            return True
    return False


def expire_old_alerts(database, now: datetime | None = None) -> int:
    """Remove expired feed projections in bounded batches on each ingest run."""
    now = now or datetime.now(UTC)
    removed = 0
    for snapshot in database.collection("publicAlerts").where("expiresAt", "<=", now).limit(500).stream():
        snapshot.reference.delete()
        removed += 1
    for snapshot in database.collection("emergencyEvents").where("expiresAt", "<=", now).limit(500).stream():
        if (snapshot.to_dict() or {}).get("sourceAlertId"):
            snapshot.reference.delete()
    return removed
