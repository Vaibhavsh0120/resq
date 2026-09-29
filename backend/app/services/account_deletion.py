"""Idempotent, self-service erasure of a Firebase account's ResQ records."""

from __future__ import annotations

from datetime import UTC, datetime

from firebase_admin import auth

from ..config import Settings
from ..integrations.report_storage import ReportPhotoStorage


def _delete_documents(query) -> None:
    for document in query.stream():
        document.reference.delete()


def delete_account(database, uid: str, settings: Settings) -> None:
    storage = ReportPhotoStorage(settings)
    reports = list(database.collection("incidentReports").where("ownerId", "==", uid).stream())
    # Delete remote assets first. A storage failure keeps the account available to retry.
    for report in reports:
        data = report.to_dict() or {}
        public_id = data.get("photoPublicId")
        if public_id and data.get("photoState") not in {"deleted", "infected_deleted"}:
            storage.delete(public_id)
            report.reference.update({"photoState": "deleted", "photoPublicId": None, "photoDeletedAt": datetime.now(UTC)})

    for report in reports:
        database.collection("verifiedReports").document(report.id).delete()
        report.reference.delete()

    for conversation in database.collection("conversations").where("ownerId", "==", uid).stream():
        _delete_documents(conversation.reference.collection("messages"))
        conversation.reference.delete()

    # SOS inbox entries may contain the owner's name. Remove the copies sent to
    # accepted recipients before deleting the event itself.
    for event in database.collection("sosEvents").where("ownerId", "==", uid).stream():
        for recipient_uid in (event.to_dict() or {}).get("authorizedUids") or []:
            database.collection("users").document(recipient_uid).collection("notifications").document(event.id).delete()
        event.reference.delete()

    for name, owner_field in (
        ("locationShares", "ownerId"),
        ("circleInvites", "senderId"),
        ("circleInvites", "recipientId"),
    ):
        _delete_documents(database.collection(name).where(owner_field, "==", uid))

    # A person may have belonged to more than the Circle currently saved in
    # settings. Remove every member record and its private check-ins.
    for member in database.collection_group("members").where("userId", "==", uid).stream():
        circle = member.reference.parent.parent
        _delete_documents(circle.collection("checkIns").where("userId", "==", uid))
        if (circle.get().to_dict() or {}).get("ownerId") == uid:
            circle.update({"ownerId": None, "name": "Family Circle", "updatedAt": datetime.now(UTC)})
        member.reference.delete()

    user_ref = database.collection("users").document(uid)
    for name in ("settings", "readiness", "emergencyContacts", "notifications", "devices"):
        _delete_documents(user_ref.collection(name))
    user_ref.delete()

    # Daily parent documents are created with each quota use, so this covers
    # every retained day even after a missed cleanup run.
    for day in database.collection("aiUsage").list_documents():
        day.collection("counters").document(f"user-{uid}").delete()

    auth.delete_user(uid)
