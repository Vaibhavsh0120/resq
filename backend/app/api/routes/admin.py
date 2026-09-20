from datetime import UTC, datetime

from fastapi import APIRouter, HTTPException

from ...config import get_settings
from ...domain.models import ReportApproval
from ...integrations.firebase import firestore_client
from ...integrations.official_alerts import ingest_imd, ingest_ndma
from ..dependencies import AdminAccess

router = APIRouter(prefix="/admin", tags=["admin"])


@router.get("/reports")
async def pending_reports(_: AdminAccess) -> list[dict]:
    documents = (
        firestore_client()
        .collection("incidentReports")
        .where("status", "==", "pending")
        .order_by("createdAt", direction="DESCENDING")
        .limit(100)
        .stream()
    )
    return [{"id": document.id, **document.to_dict()} for document in documents]


@router.post("/reports/{report_id}:approve")
async def approve_report(
    report_id: str,
    body: ReportApproval,
    _: AdminAccess,
) -> dict[str, bool]:
    database = firestore_client()
    source_ref = database.collection("incidentReports").document(report_id)
    snapshot = source_ref.get()
    if not snapshot.exists:
        raise HTTPException(status_code=404, detail={"code": "report_not_found"})
    data = snapshot.to_dict()
    if data.get("status") != "pending":
        raise HTTPException(status_code=409, detail={"code": "report_already_moderated"})
    location = data.get("location") or {}
    public_location = None
    if location.get("latitude") is not None and location.get("longitude") is not None:
        public_location = {
            "latitude": round(float(location["latitude"]), 2),
            "longitude": round(float(location["longitude"]), 2),
        }
    now = datetime.now(UTC)
    batch = database.batch()
    batch.set(
        database.collection("verifiedReports").document(report_id),
        {
            "hazard": data.get("hazard"),
            # Moderators must provide a reviewed, PII-free public summary.
            "description": body.public_description.strip(),
            "coarseLocation": public_location,
            "verifiedAt": now,
            "source": "Community report verified by ResQ moderation",
        },
    )
    batch.update(source_ref, {"status": "verified", "moderatedAt": now})
    owner_id = data.get("ownerId")
    if owner_id:
        notification = database.collection("users").document(owner_id).collection("notifications").document()
        batch.set(
            notification,
            {
                "title": "Report verified",
                "body": "Your incident report passed moderation.",
                "severity": "info",
                "category": "report",
                "read": False,
                "createdAt": now,
                "deepLink": "/app/updates",
            },
        )
    batch.commit()
    return {"approved": True}


@router.post("/reports/{report_id}:reject")
async def reject_report(report_id: str, _: AdminAccess) -> dict[str, bool]:
    reference = firestore_client().collection("incidentReports").document(report_id)
    snapshot = reference.get()
    if not snapshot.exists:
        raise HTTPException(status_code=404, detail={"code": "report_not_found"})
    reference.update({"status": "rejected", "moderatedAt": datetime.now(UTC)})
    return {"rejected": True}


@router.post("/ingestion:run")
async def run_ingestion(_: AdminAccess) -> dict[str, int]:
    settings = get_settings()
    return {
        "ndma": await ingest_ndma(settings),
        "imd": await ingest_imd(settings),
    }
