from __future__ import annotations

import hashlib
from datetime import UTC, datetime, timedelta
from email.utils import parsedate_to_datetime
from typing import Any

import feedparser
import httpx

from ..config import Settings
from .firebase import firestore_client


def _severity(text: str) -> str:
    lowered = text.lower()
    if any(word in lowered for word in ("extreme", "red alert", "take action")):
        return "critical"
    if any(word in lowered for word in ("warning", "orange", "severe", "alert")):
        return "warning"
    return "info"


def _imd_severity(color: str) -> str:
    """Map IMD's green/yellow/orange/red scale without inflating severity."""
    normalized = color.strip().lower()
    if normalized in {"4", "red"}:
        return "critical"
    if normalized in {"3", "orange"}:
        return "warning"
    return "info"


def _stable_id(source: str, external_id: str) -> str:
    return hashlib.sha256(f"{source}:{external_id}".encode()).hexdigest()[:32]


def _published(entry: Any) -> datetime:
    value = entry.get("published") or entry.get("updated")
    if value:
        try:
            return parsedate_to_datetime(value).astimezone(UTC)
        except (TypeError, ValueError, OverflowError):
            pass
    return datetime.now(UTC)


async def ingest_ndma(settings: Settings) -> int:
    if not settings.ndma_feed_url:
        return 0
    database = firestore_client()
    state_ref = database.collection("ingestionState").document("ndma")
    state = state_ref.get().to_dict() or {}
    headers = {}
    if state.get("etag"):
        headers["If-None-Match"] = state["etag"]
    if state.get("lastModified"):
        headers["If-Modified-Since"] = state["lastModified"]
    async with httpx.AsyncClient(timeout=20, follow_redirects=True) as client:
        response = await client.get(settings.ndma_feed_url, headers=headers)
    if response.status_code == 304:
        return 0
    response.raise_for_status()
    feed = feedparser.loads(response.content)
    batch = database.batch()
    count = 0
    for entry in feed.entries:
        external_id = entry.get("id") or entry.get("link") or entry.get("title")
        if not external_id:
            continue
        issued_at = _published(entry)
        alert_id = _stable_id("ndma", external_id)
        document = database.collection("publicAlerts").document(alert_id)
        summary = entry.get("summary", "")
        severity = _severity(f"{entry.get('title', '')} {summary}")
        expires_at = issued_at + timedelta(hours=24)
        batch.set(
            document,
            {
                "source": "NDMA SACHET",
                "sourceUrl": entry.get("link", settings.ndma_feed_url),
                "externalId": external_id,
                "title": {"en": entry.get("title", "Official safety alert")},
                "summary": {"en": summary},
                "severity": severity,
                "issuedAt": issued_at,
                "expiresAt": expires_at,
                "verified": True,
                "ingestedAt": datetime.now(UTC),
            },
            merge=True,
        )
        if severity in {"critical", "warning"}:
            batch.set(
                database.collection("emergencyEvents").document(alert_id),
                {
                    "title": {"en": entry.get("title", "Official safety alert")},
                    "sourceAlertId": alert_id,
                    "source": "NDMA SACHET",
                    "severity": severity,
                    "issuedAt": issued_at,
                    "expiresAt": expires_at,
                    "status": "active",
                },
                merge=True,
            )
        count += 1
    batch.set(
        state_ref,
        {
            "etag": response.headers.get("etag"),
            "lastModified": response.headers.get("last-modified"),
            "updatedAt": datetime.now(UTC),
        },
        merge=True,
    )
    batch.commit()
    return count


async def ingest_imd(settings: Settings) -> int:
    if not settings.imd_district_warning_url or not settings.imd_district_ids:
        return 0
    ids = [item.strip() for item in settings.imd_district_ids.split(",") if item.strip()]
    database = firestore_client()
    count = 0
    async with httpx.AsyncClient(timeout=20, follow_redirects=True) as client:
        for district_id in ids:
            url = settings.imd_district_warning_url.format(id=district_id)
            response = await client.get(url)
            response.raise_for_status()
            payload = response.json()
            records = payload if isinstance(payload, list) else [payload]
            for record in records:
                if not isinstance(record, dict):
                    continue
                district = record.get("District") or record.get("district") or district_id
                issued = datetime.now(UTC)
                title = f"IMD weather warning for {district}"
                warning = str(record.get("Day_1") or record.get("day_1") or "")
                color = str(record.get("Day1_Color") or record.get("day1_color") or "")
                if not warning or warning.lower() in {"nil", "no warning"}:
                    continue
                severity = _imd_severity(color)
                alert_id = _stable_id(
                    "imd", f"{district_id}:{issued.date().isoformat()}:{warning}"
                )
                document = database.collection("publicAlerts").document(alert_id)
                expires_at = issued + timedelta(days=1)
                document.set(
                    {
                        "source": "India Meteorological Department",
                        "sourceUrl": url,
                        "externalId": district_id,
                        "district": district,
                        "title": {"en": title},
                        "summary": {"en": warning},
                        "severity": severity,
                        "issuedAt": issued,
                        "expiresAt": expires_at,
                        "verified": True,
                        "ingestedAt": issued,
                    },
                    merge=True,
                )
                if severity in {"critical", "warning"}:
                    database.collection("emergencyEvents").document(alert_id).set(
                        {
                            "title": {"en": title},
                            "sourceAlertId": alert_id,
                            "source": "India Meteorological Department",
                            "severity": severity,
                            "district": district,
                            "issuedAt": issued,
                            "expiresAt": expires_at,
                            "status": "active",
                        },
                        merge=True,
                    )
                count += 1
    return count
