from fastapi import APIRouter, HTTPException, status

from ...domain.models import SosFanoutResult
from ...integrations.firebase import firestore_client
from ...services.sos_fanout import fan_out_sos
from ..dependencies import CurrentUser

router = APIRouter(tags=["sos"])


@router.post("/sos/{event_id}/fanout", response_model=SosFanoutResult)
async def fanout(event_id: str, user: CurrentUser) -> SosFanoutResult:
    database = firestore_client()
    snapshot = database.collection("sosEvents").document(event_id).get()
    if not snapshot.exists:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail={"code": "sos_not_found"})
    event = snapshot.to_dict() or {}
    if event.get("ownerId") != user.uid:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail={"code": "not_sos_owner"})
    if event.get("deliveryStatus") == "inbox_delivered":
        return SosFanoutResult(
            notification_count=len(event.get("authorizedUids") or []),
            push_success_count=0,
            push_failure_count=0,
        )

    notification_count, push_success, push_failure = fan_out_sos(
        database, event_id, event
    )
    return SosFanoutResult(
        notification_count=notification_count,
        push_success_count=push_success,
        push_failure_count=push_failure,
    )
