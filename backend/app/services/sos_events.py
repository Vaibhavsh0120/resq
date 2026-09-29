from datetime import datetime


def should_retry_sos(event: dict, now: datetime) -> bool:
    status = event.get("deliveryStatus")
    if status == "pending":
        return True
    if status == "dispatching":
        lease_expires_at = event.get("leaseExpiresAt")
        return lease_expires_at is None or lease_expires_at <= now
    return False


def resolve_sos_recipients(database, owner_id: str) -> tuple[str | None, list[str]]:
    settings = (
        database.collection("users")
        .document(owner_id)
        .collection("settings")
        .document("app")
        .get()
        .to_dict()
        or {}
    )
    circle_id = settings.get("circleId")
    if not isinstance(circle_id, str) or not circle_id:
        return None, []

    members = database.collection("householdCircles").document(circle_id).collection("members")
    owner = members.document(owner_id).get().to_dict() or {}
    if owner.get("accepted") is not True:
        return None, []

    recipients = sorted({
        member.id
        for member in members.where("accepted", "==", True).stream()
        if member.id != owner_id
        and (member.to_dict() or {}).get("accepted") is True
        and (member.to_dict() or {}).get("userId", member.id) == member.id
    })
    return circle_id, recipients[:400]
