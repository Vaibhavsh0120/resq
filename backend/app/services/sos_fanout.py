from __future__ import annotations

from datetime import UTC, datetime

from firebase_admin import firestore, messaging


def build_sos_notification(event_id: str, owner_name: str) -> dict:
    return {
        "title": f"Emergency SOS from {owner_name}",
        "body": f"{owner_name} activated an SOS event. Open ResQ for details.",
        "severity": "critical",
        "category": "sos",
        "read": False,
        "deepLink": f"/sos/{event_id}",
        "createdAt": datetime.now(UTC),
    }


def fan_out_sos(database, event_id: str, event: dict) -> tuple[int, int, int]:
    recipients = list(dict.fromkeys(event.get("authorizedUids") or []))[:400]
    owner_id = event["ownerId"]
    owner = database.collection("users").document(owner_id).get().to_dict() or {}
    owner_name = (owner.get("personalInfo") or {}).get("fullName") or "A Circle member"
    payload = build_sos_notification(event_id, owner_name)

    batch = database.batch()
    tokens: list[str] = []
    for uid in recipients:
        notification_ref = (
            database.collection("users")
            .document(uid)
            .collection("notifications")
            .document(event_id)
        )
        batch.set(notification_ref, payload)
        for device in (
            database.collection("users")
            .document(uid)
            .collection("devices")
            .where("enabled", "==", True)
            .stream()
        ):
            token = (device.to_dict() or {}).get("token") or device.id
            if token:
                tokens.append(token)

    event_ref = database.collection("sosEvents").document(event_id)
    batch.update(
        event_ref,
        {
            "deliveryStatus": "inbox_delivered" if recipients else "no_recipients",
            "notifiedAt": firestore.SERVER_TIMESTAMP,
        },
    )
    batch.commit()

    if not tokens:
        return len(recipients), 0, 0
    try:
        response = messaging.send_each_for_multicast(
            messaging.MulticastMessage(
                tokens=list(dict.fromkeys(tokens))[:500],
                notification=messaging.Notification(
                    title=payload["title"], body=payload["body"]
                ),
                data={
                    "category": "sos",
                    "deepLink": payload["deepLink"],
                    "eventId": event_id,
                },
                android=messaging.AndroidConfig(priority="high"),
            )
        )
        return len(recipients), response.success_count, response.failure_count
    except Exception:
        return len(recipients), 0, len(tokens)
