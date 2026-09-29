from __future__ import annotations

from datetime import UTC, datetime, timedelta

from firebase_admin import firestore, messaging


def is_checkin_due(now: datetime, expected: str, timezone_offset_minutes: int) -> bool:
    try:
        scheduled = datetime.strptime(expected, "%H:%M").time()
    except ValueError:
        return False
    local_now = now + timedelta(minutes=timezone_offset_minutes)
    return local_now.time().replace(second=0, microsecond=0) >= scheduled


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
        if not is_checkin_due(now, expected, offset):
            continue
        notification_id = f"checkin-{event_id}-{local_now.date().isoformat()}"
        notification_ref = (
            database.collection("users")
            .document(uid)
            .collection("notifications")
            .document(notification_id)
        )
        title = "Emergency check-in"
        event_title = event_data.get("title") or "the active emergency"
        if isinstance(event_title, dict):
            event_title = event_title.get("en") or next(iter(event_title.values()), "the active emergency")
        body = f"Let your Family Circle know you are safe during {event_title}."
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
        tokens = list(dict.fromkeys(token for token in tokens if token))[:500]
        transaction = database.transaction()

        @firestore.transactional
        def create_inbox(current_transaction):
            if notification_ref.get(transaction=current_transaction).exists:
                return False
            current_transaction.set(notification_ref, {
                "title": title,
                "body": body,
                "severity": "warning",
                "category": "check_in",
                "read": False,
                "createdAt": now,
                "deepLink": "/app/family",
                "eventId": event_id,
                "pushStatus": "pending" if tokens else "no_devices",
            })
            return True

        if not create_inbox(transaction):
            continue
        if tokens:
            # Mark the attempt before FCM. A crash can leave this unconfirmed;
            # the durable inbox remains available without duplicate pushes.
            notification_ref.update({"pushStatus": "attempted", "pushAttemptedAt": now})
            try:
                result = messaging.send_each_for_multicast(
                    messaging.MulticastMessage(
                        tokens=tokens,
                        notification=messaging.Notification(title=title, body=body),
                        data={"category": "check_in", "deepLink": "/app/family"},
                    )
                )
                notification_ref.update({
                    "pushStatus": "sent" if result.failure_count == 0 else "partial_failure",
                    "pushSuccessCount": result.success_count,
                    "pushFailureCount": result.failure_count,
                })
            except Exception:
                notification_ref.update({"pushStatus": "unconfirmed", "pushFailureCount": len(tokens)})
        sent += 1
    return sent
