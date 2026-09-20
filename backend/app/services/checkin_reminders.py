from __future__ import annotations

from datetime import UTC, datetime, timedelta

from firebase_admin import firestore, messaging


def send_due_checkin_reminders(database, now: datetime | None = None) -> int:
    now = now or datetime.now(UTC)
    sent = 0
    settings_documents = (
        database.collection_group("settings")
        .where("emergencyCheckIn.enabled", "==", True)
        .stream()
    )
    for settings_document in settings_documents:
        if settings_document.id != "app":
            continue
        uid = settings_document.reference.parent.parent.id
        checkin = (settings_document.to_dict() or {}).get("emergencyCheckIn") or {}
        event_id = checkin.get("eventId")
        if not event_id:
            continue
        event = database.collection("emergencyEvents").document(event_id).get()
        event_data = event.to_dict() if event.exists else {}
        expires_at = event_data.get("expiresAt")
        if not event.exists or expires_at is None or expires_at <= now:
            settings_document.reference.update(
                {
                    "emergencyCheckIn.enabled": False,
                    "emergencyCheckIn.eventId": firestore.DELETE_FIELD,
                }
            )
            continue
        offset = int(checkin.get("timezoneOffsetMinutes") or 0)
        local_now = now + timedelta(minutes=offset)
        expected = str(checkin.get("time") or "09:00")
        if local_now.strftime("%H:%M") != expected:
            continue
        notification_id = f"checkin-{event_id}-{local_now.date().isoformat()}"
        notification_ref = (
            database.collection("users")
            .document(uid)
            .collection("notifications")
            .document(notification_id)
        )
        if notification_ref.get().exists:
            continue
        title = "Emergency check-in"
        event_title = event_data.get("title") or "the active emergency"
        if isinstance(event_title, dict):
            event_title = event_title.get("en") or next(iter(event_title.values()), "the active emergency")
        body = f"Let your Family Circle know you are safe during {event_title}."
        notification_ref.set(
            {
                "title": title,
                "body": body,
                "severity": "warning",
                "category": "check_in",
                "read": False,
                "createdAt": now,
                "deepLink": "/app/family",
                "eventId": event_id,
            }
        )
        categories = (settings_document.to_dict() or {}).get(
            "notificationCategories"
        ) or {}
        tokens = []
        if categories.get("circle", True):
            tokens = [
                (device.to_dict() or {}).get("token")
                for device in database.collection("users")
                .document(uid)
                .collection("devices")
                .where("enabled", "==", True)
                .stream()
            ]
        tokens = [token for token in tokens if token]
        if tokens:
            try:
                messaging.send_each_for_multicast(
                    messaging.MulticastMessage(
                        tokens=tokens[:500],
                        notification=messaging.Notification(title=title, body=body),
                        data={"category": "check_in", "deepLink": "/app/family"},
                    )
                )
            except Exception:
                pass
        sent += 1
    return sent
