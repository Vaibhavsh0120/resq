"""Retry inbox delivery for pending SOS events from the free scheduled runner."""

from datetime import UTC, datetime

from app.integrations.firebase import firestore_client
from app.services.sos_events import should_retry_sos
from app.services.sos_fanout import fan_out_sos


def main() -> None:
    database = firestore_client()
    events = (
        database.collection("sosEvents")
        .where("deliveryStatus", "in", ["pending", "dispatching"])
        .limit(100)
        .stream()
    )
    attempted = 0
    failures = 0
    for snapshot in events:
        event = snapshot.to_dict() or {}
        if should_retry_sos(event, datetime.now(UTC)):
            try:
                fan_out_sos(database, snapshot.id, event)
            except Exception:
                failures += 1
            attempted += 1
    database.collection("jobHealth").document("sos_retry").set(
        {"lastRunAt": datetime.now(UTC), "attempted": attempted, "failures": failures}
    )
    print(f"Attempted {attempted} pending SOS deliveries.")
    if failures:
        raise SystemExit(f"{failures} SOS inbox deliveries need retry")


if __name__ == "__main__":
    main()
