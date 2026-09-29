"""Delete expired or pending-deletion report photos, retrying failures."""

from __future__ import annotations

from datetime import UTC, datetime

from firebase_admin import firestore

from app.config import get_settings
from app.integrations.firebase import firestore_client
from app.integrations.report_storage import ReportPhotoStorage


def main() -> None:
    database = firestore_client()
    storage = ReportPhotoStorage(get_settings())
    now = datetime.now(UTC)
    expired = list(database.collection("incidentReports").where("photoExpiresAt", "<=", now).limit(1001).stream())
    retry = list(database.collection("incidentReports").where("photoState", "==", "delete_pending").limit(1001).stream())
    backlog = len(expired) > 1000 or len(retry) > 1000
    candidates = {snapshot.id: snapshot for snapshot in [*expired[:1000], *retry[:1000]]}
    failures = 0
    overdue = 0
    for snapshot in candidates.values():
        data = snapshot.to_dict() or {}
        if data.get("photoState") in {"none", "deleted", "infected_deleted"}:
            continue
        public_id = data.get("photoPublicId")
        if not public_id:
            continue
        try:
            storage.delete(public_id)
            snapshot.reference.update(
                {"photoState": "deleted", "photoDeletedAt": datetime.now(UTC), "photoPublicId": None,
                 "photoExpiresAt": firestore.DELETE_FIELD}
            )
        except Exception:
            failures += 1
            if data.get("photoExpiresAt") and data["photoExpiresAt"] <= now:
                overdue += 1
            snapshot.reference.update(
                {"photoState": "delete_pending", "photoDeleteFailedAt": datetime.now(UTC)}
            )
    database.collection("jobHealth").document("photo_purge").set(
        {"lastRunAt": now, "processed": len(candidates), "failures": failures,
         "overdue": overdue, "backlog": backlog}
    )
    if failures or overdue or backlog:
        raise SystemExit(f"{failures} Cloudinary deletions need retry; {overdue} are overdue; backlog={backlog}")


if __name__ == "__main__":
    main()
