"""Fail scheduled run when safety jobs or official feeds are stale."""

from datetime import UTC, datetime, timedelta

from app.integrations.firebase import firestore_client


def main() -> None:
    database = firestore_client()
    now = datetime.now(UTC)
    sources = {
        "ndma": ("ingestionState", "lastCheckedAt", timedelta(minutes=90)),
        "gdacs": ("ingestionState", "lastCheckedAt", timedelta(minutes=90)),
        "sos_retry": ("jobHealth", "lastRunAt", timedelta(minutes=20)),
        "checkin": ("jobHealth", "lastRunAt", timedelta(minutes=20)),
        "photo_scan": ("jobHealth", "lastRunAt", timedelta(hours=2)),
        "photo_purge": ("jobHealth", "lastRunAt", timedelta(hours=8)),
    }
    unhealthy = []
    for name, (collection, timestamp_key, max_age) in sources.items():
        data = database.collection(collection).document(name).get().to_dict() or {}
        checked = data.get(timestamp_key)
        if not checked or now - checked > max_age or data.get("status") in {"error", "partial"} or data.get("failures", 0) or data.get("backlog"):
            unhealthy.append(name)
    if unhealthy:
        raise SystemExit("Operator action needed: stale or failed jobs: " + ", ".join(unhealthy))
    print("Operational jobs and NDMA feed are within best-effort freshness thresholds.")


if __name__ == "__main__":
    main()
