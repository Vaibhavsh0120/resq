from datetime import UTC, datetime
from uuid import uuid4

from fastapi import APIRouter, File, HTTPException, UploadFile, status

from ...config import get_settings
from ...domain.models import IncidentReport, IncidentReportCreate, ReportPhotoUpload
from ...integrations.firebase import firestore_client
from ...integrations.report_storage import ReportPhotoStorage
from ...services.report_photos import (
    InvalidReportPhoto,
    sanitize_report_photo,
    scan_report_photo,
)
from ..dependencies import CurrentUser

router = APIRouter(prefix="/reports", tags=["reports"])


@router.post("", response_model=IncidentReport, status_code=status.HTTP_201_CREATED)
async def create_report(body: IncidentReportCreate, user: CurrentUser) -> IncidentReport:
    if user.is_anonymous:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail={"code": "registered_account_required"},
        )

    report_id = str(uuid4())
    created_at = datetime.now(UTC)
    firestore_client().collection("incidentReports").document(report_id).set(
        {
            "ownerId": user.uid,
            "hazard": body.hazard,
            "description": body.description,
            "location": (
                {"latitude": body.latitude, "longitude": body.longitude}
                if body.latitude is not None and body.longitude is not None
                else None
            ),
            "status": "pending",
            "createdAt": created_at,
            "updatedAt": created_at,
            "photoState": "none",
        }
    )
    return IncidentReport(
        id=report_id,
        status="pending",
        hazard=body.hazard,
        created_at=created_at,
    )


@router.post("/{report_id}/photo-upload", response_model=ReportPhotoUpload)
async def upload_report_photo(
    report_id: str,
    user: CurrentUser,
    photo: UploadFile = File(...),
) -> ReportPhotoUpload:
    if user.is_anonymous:
        raise HTTPException(status_code=403, detail={"code": "registered_account_required"})
    report_ref = firestore_client().collection("incidentReports").document(report_id)
    snapshot = report_ref.get()
    if not snapshot.exists or snapshot.to_dict().get("ownerId") != user.uid:
        raise HTTPException(status_code=404, detail={"code": "report_not_found"})
    try:
        source = await photo.read()
        settings = get_settings()
        scan_report_photo(source, settings)
        cleaned = sanitize_report_photo(source)
        object_name = f"incident-reports/{user.uid}/{report_id}/original-sanitized.jpg"
        storage_uri = ReportPhotoStorage(settings).put(
            object_name=object_name,
            data=cleaned.bytes,
            content_type=cleaned.content_type,
        )
    except InvalidReportPhoto as exc:
        raise HTTPException(status_code=422, detail={"code": "invalid_photo", "message": str(exc)}) from exc
    except RuntimeError as exc:
        raise HTTPException(status_code=503, detail={"code": "photo_storage_unavailable"}) from exc
    report_ref.update(
        {
            "photoState": "private_pending_moderation",
            "photoStorageUri": storage_uri,
            "photoContentType": cleaned.content_type,
            "updatedAt": datetime.now(UTC),
        }
    )
    return ReportPhotoUpload(content_type=cleaned.content_type)
