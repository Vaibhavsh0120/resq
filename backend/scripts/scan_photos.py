"""Scheduled malware screening. Requires clamscan and Firebase/Cloudinary secrets."""

from __future__ import annotations

import subprocess
from datetime import UTC, datetime

from firebase_admin import firestore

from app.config import get_settings
from app.integrations.firebase import firestore_client
from app.integrations.report_storage import ReportPhotoStorage


def scan_bytes(data: bytes) -> str:
    result = subprocess.run(
        ["clamscan", "--no-summary", "-"], input=data, capture_output=True, timeout=120
    )
    if result.returncode == 0:
        return "clean"
    if result.returncode == 1:
        return "infected"
    raise RuntimeError("ClamAV did not complete a valid scan.")


def main() -> None:
    database = firestore_client()
    storage = ReportPhotoStorage(get_settings())
    pending = list(
        database.collection("incidentReports")
        .where("photoState", "in", ["pending_scan", "scan_failed"])
        .limit(50)
        .stream()
    )
    failures = 0
    for snapshot in pending:
        data = snapshot.to_dict() or {}
        public_id = data.get("photoPublicId")
        if not public_id:
            continue
        try:
            expiry = data.get("photoExpiresAt")
            if expiry is None:
                raise RuntimeError("Pending photo has no expiry")
            if expiry <= datetime.now(UTC):
                continue
            outcome = scan_bytes(storage.read(public_id))
            if outcome == "infected":
                storage.delete(public_id)
                snapshot.reference.update(
                    {"photoState": "infected_deleted", "photoScannedAt": datetime.now(UTC),
                     "photoPublicId": None, "photoExpiresAt": firestore.DELETE_FIELD}
                )
            else:
                snapshot.reference.update(
                    {"photoState": "clean", "photoScannedAt": datetime.now(UTC)}
                )
        except Exception:
            failures += 1
            snapshot.reference.update(
                {"photoState": "scan_failed", "photoScanFailedAt": datetime.now(UTC)}
            )
    database.collection("jobHealth").document("photo_scan").set(
        {"lastRunAt": datetime.now(UTC), "processed": len(pending), "failures": failures}
    )
    if failures:
        raise SystemExit(f"{failures} photo scans need retry")


if __name__ == "__main__":
    main()
