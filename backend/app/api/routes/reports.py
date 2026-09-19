from datetime import UTC, datetime
from uuid import uuid4

from fastapi import APIRouter, HTTPException, status

from ...domain.models import IncidentReport, IncidentReportCreate
from ...integrations.firebase import firestore_client
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
