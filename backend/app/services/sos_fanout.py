from __future__ import annotations

from datetime import UTC, datetime, timedelta

from firebase_admin import firestore, messaging

from .sos_events import should_retry_sos


def build_sos_notification(event_id: str, owner_name: str) -> dict:
    return {
        "title": f"Emergency SOS from {owner_name}",
        "body": f"{owner_name} activated an SOS event. Open ResQ for details.",
        "severity": "critical",
        "category": "sos",
        "read": False,
        "deepLink": f"/sos/{event_id}",
        "eventId": event_id,
        "createdAt": datetime.now(UTC),
    }


def fan_out_sos(database, event_id: str, event: dict) -> tuple[int, int, int]:
    event_ref = database.collection("sosEvents").document(event_id)
    transaction = database.transaction()

    @firestore.transactional
    def claim(current_transaction):
        snapshot = event_ref.get(transaction=current_transaction)
        latest = snapshot.to_dict() or {}
        now = datetime.now(UTC)
        if not snapshot.exists or not should_retry_sos(latest, now):
            return None
        current_transaction.update(event_ref, {
            "deliveryStatus": "dispatching",
            "leaseExpiresAt": now + timedelta(minutes=2),
        })
        return latest

    event = claim(transaction)
    if event is None:
        return 0, 0, 0

    recipients = list(dict.fromkeys(event.get("authorizedUids") or []))[:400]
    circle_id = event.get("circleId")
    if circle_id:
        members = database.collection("householdCircles").document(circle_id).collection("members")
        recipients = [
            uid for uid in recipients
            if (member := (members.document(uid).get().to_dict() or {})).get("accepted") is True
            and member.get("userId", uid) == uid
        ]
    else:
        recipients = []
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
        settings = (
            database.collection("users")
            .document(uid)
            .collection("settings")
            .document("app")
            .get()
            .to_dict()
            or {}
        )
        categories = settings.get("notificationCategories") or {}
        if categories.get("circle", True):
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

    batch.update(
        event_ref,
        {
            "authorizedUids": recipients,
            "deliveryStatus": "inbox_delivered" if recipients else "no_recipients",
            "notifiedAt": firestore.SERVER_TIMESTAMP,
            "leaseExpiresAt": firestore.DELETE_FIELD,
            "pushStatus": "attempted" if tokens else "no_devices",
            "pushAttemptedAt": firestore.SERVER_TIMESTAMP if tokens else None,
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
        event_ref.update({
            "pushStatus": "sent" if response.failure_count == 0 else "partial_failure",
            "pushSuccessCount": response.success_count,
            "pushFailureCount": response.failure_count,
        })
        return len(recipients), response.success_count, response.failure_count
    except Exception:
        event_ref.update({"pushStatus": "unconfirmed", "pushFailureCount": len(tokens)})
        return len(recipients), 0, len(tokens)
