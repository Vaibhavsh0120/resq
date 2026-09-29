from datetime import UTC, datetime
from uuid import uuid4

from fastapi import APIRouter, HTTPException, status

from ...domain.models import SosCreateRequest, SosCreated, SosFanoutResult
from ...integrations.firebase import firestore_client
from ...services.sos_events import resolve_sos_recipients
from ...services.sos_fanout import fan_out_sos
from ..dependencies import CurrentUser

router = APIRouter(tags=["sos"])


@router.post("/sos", response_model=SosCreated, status_code=status.HTTP_201_CREATED)
async def create_sos(body: SosCreateRequest, user: CurrentUser) -> SosCreated:
    database = firestore_client()
    circle_id, recipients = (
        (None, [])
        if user.is_anonymous
        else resolve_sos_recipients(database, user.uid)
    )
    event_id = str(uuid4())
    event = {
        "ownerId": user.uid,
        "authorizedUids": recipients,
        "status": "active",
        "createdAt": datetime.now(UTC),
        "deliveryStatus": "pending" if recipients else "no_recipients",
    }
    if circle_id:
        event["circleId"] = circle_id
    if body.latitude is not None:
        event["location"] = {"latitude": body.latitude, "longitude": body.longitude}
    database.collection("sosEvents").document(event_id).set(event)
    return SosCreated(id=event_id, delivery_status=event["deliveryStatus"])


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
            delivery_status="inbox_delivered",
        )

    notification_count, push_success, push_failure = fan_out_sos(
        database, event_id, event
    )
    return SosFanoutResult(
        notification_count=notification_count,
        push_success_count=push_success,
        push_failure_count=push_failure,
        delivery_status=(database.collection("sosEvents").document(event_id).get().to_dict() or {}).get("deliveryStatus", "pending"),
    )
