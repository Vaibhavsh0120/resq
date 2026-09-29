from datetime import UTC, datetime
from uuid import uuid4

from fastapi import APIRouter, HTTPException
from fastapi.responses import Response
from firebase_admin import firestore

from ...config import get_settings
from ...domain.models import PlaceVerification, ReportApproval
from ...integrations.firebase import firestore_client
from ...integrations.official_alerts import ingest_imd, ingest_ndma
from ...integrations.report_storage import ReportPhotoStorage
from ...services.geo_cells import geo_cell
from ..dependencies import AdminAccess

router = APIRouter(prefix="/admin", tags=["admin"])


def _audit(database, actor: str, action: str, target: str) -> None:
    database.collection("adminAudit").document().set(
        {"actor": actor, "action": action, "target": target, "at": datetime.now(UTC)}
    )


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
    return [
        {"id": document.id, **{key: value for key, value in (document.to_dict() or {}).items()
                              if key not in {"photoPublicId", "photoAssetId", "photoStorageUri"}}}
        for document in documents
    ]


@router.get("/reports/{report_id}/photo")
async def view_report_photo(report_id: str, actor: AdminAccess) -> Response:
    snapshot = firestore_client().collection("incidentReports").document(report_id).get()
    data = snapshot.to_dict() if snapshot.exists else None
    if not data or data.get("photoState") != "clean":
        raise HTTPException(status_code=404, detail={"code": "photo_unavailable"})
    expiry = data.get("photoExpiresAt")
    if not expiry or expiry <= datetime.now(UTC):
        raise HTTPException(status_code=410, detail={"code": "photo_expired"})
    try:
        photo = ReportPhotoStorage(get_settings()).read(data["photoPublicId"])
    except Exception as exc:
        raise HTTPException(status_code=503, detail={"code": "photo_unavailable"}) from exc
    if expiry <= datetime.now(UTC):
        raise HTTPException(status_code=410, detail={"code": "photo_expired"})
    _audit(firestore_client(), actor, "view_report_photo", report_id)
    return Response(content=photo, media_type="image/jpeg", headers={"Cache-Control": "no-store"})


@router.post("/reports/{report_id}:approve")
async def approve_report(
    report_id: str,
    body: ReportApproval,
    actor: AdminAccess,
) -> dict[str, bool]:
    database = firestore_client()
    source_ref = database.collection("incidentReports").document(report_id)
    snapshot = source_ref.get()
    if not snapshot.exists:
        raise HTTPException(status_code=404, detail={"code": "report_not_found"})
    data = snapshot.to_dict()
    if data.get("status") != "pending":
        raise HTTPException(status_code=409, detail={"code": "report_already_moderated"})
    if data.get("photoState") in {"pending_scan", "scan_failed", "infected"}:
        raise HTTPException(status_code=409, detail={"code": "photo_not_cleared"})
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
            "geoCell": geo_cell(public_location["latitude"], public_location["longitude"]) if public_location else None,
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
    batch.set(database.collection("adminAudit").document(),
              {"actor": actor, "action": "approve_report", "target": report_id, "at": now})
    batch.commit()
    return {"approved": True}


@router.post("/reports/{report_id}:reject")
async def reject_report(report_id: str, actor: AdminAccess) -> dict[str, bool]:
    database = firestore_client()
    reference = database.collection("incidentReports").document(report_id)
    snapshot = reference.get()
    if not snapshot.exists:
        raise HTTPException(status_code=404, detail={"code": "report_not_found"})
    data = snapshot.to_dict() or {}
    if data.get("photoPublicId") and data.get("photoState") != "deleted":
        try:
            ReportPhotoStorage(get_settings()).delete(data["photoPublicId"])
        except Exception as exc:
            raise HTTPException(status_code=503, detail={"code": "photo_deletion_pending"}) from exc
    now = datetime.now(UTC)
    batch = database.batch()
    batch.update(reference, {"status": "rejected", "moderatedAt": now, "photoState": "deleted",
                             "photoPublicId": None, "photoExpiresAt": firestore.DELETE_FIELD})
    batch.delete(database.collection("verifiedReports").document(report_id))
    batch.set(database.collection("adminAudit").document(),
              {"actor": actor, "action": "reject_report", "target": report_id, "at": now})
    batch.commit()
    return {"rejected": True}


@router.post("/ingestion:run")
async def run_ingestion(_: AdminAccess) -> dict[str, int]:
    settings = get_settings()
    return {
        "ndma": await ingest_ndma(settings),
        "imd": await ingest_imd(settings),
    }


@router.post("/places")
async def verify_place(body: PlaceVerification, actor: AdminAccess) -> dict[str, str]:
    database = firestore_client()
    place_id = str(uuid4())
    batch = database.batch()
    now = datetime.now(UTC)
    batch.set(database.collection("safePlaces").document(place_id),
        {
            "name": body.name,
            "type": body.type,
            "latitude": body.latitude,
            "longitude": body.longitude,
            "geoCell": geo_cell(body.latitude, body.longitude),
            "sourceUrl": body.source_url,
            "sourceNote": body.source_note,
            "facilities": body.facilities,
            "phone": body.phone,
            "verified": True,
            "verifiedBy": actor,
            "verifiedAt": now,
        }
    )
    batch.set(database.collection("adminAudit").document(),
              {"actor": actor, "action": "verify_place", "target": place_id, "at": now})
    batch.commit()
    return {"id": place_id}


@router.get("/places")
async def list_places(_: AdminAccess) -> list[dict]:
    documents = firestore_client().collection("safePlaces").order_by("verifiedAt", direction="DESCENDING").limit(100).stream()
    return [{"id": item.id, **(item.to_dict() or {})} for item in documents]


@router.get("/source-health")
async def source_health(_: AdminAccess) -> list[dict]:
    database = firestore_client()
    documents = [
        database.collection("ingestionState").document(name).get()
        for name in ("ndma", "imd")
    ] + [
        database.collection("jobHealth").document(name).get()
        for name in ("sos_retry", "checkin", "photo_scan", "photo_purge")
    ]
    return [
        {"id": item.id, **{key: value for key, value in (item.to_dict() or {}).items()
                         if key not in {"cachedXml", "etag"}}}
        for item in documents if item.exists
    ]


@router.get("/audit")
async def audit_history(_: AdminAccess) -> list[dict]:
    documents = firestore_client().collection("adminAudit").order_by("at", direction="DESCENDING").limit(100).stream()
    return [{"id": item.id, **(item.to_dict() or {})} for item in documents]
