import hashlib
from datetime import UTC, datetime

from fastapi import APIRouter, HTTPException

from ...domain.models import DeviceRegistration, DeviceRegistrationResult
from ...integrations.firebase import firestore_client
from ..dependencies import CurrentUser

router = APIRouter(tags=["devices"])


@router.post("/devices:register", response_model=DeviceRegistrationResult)
async def register_device(
    body: DeviceRegistration, user: CurrentUser
) -> DeviceRegistrationResult:
    if user.is_anonymous:
        raise HTTPException(status_code=403, detail={"code": "registered_account_required"})
    token_id = hashlib.sha256(body.token.encode()).hexdigest()
    (
        firestore_client()
        .collection("users")
        .document(user.uid)
        .collection("devices")
        .document(token_id)
        .set(
            {
                "token": body.token,
                "platform": body.platform,
                "enabled": True,
                "updatedAt": datetime.now(UTC),
            },
            merge=True,
        )
    )
    return DeviceRegistrationResult()
