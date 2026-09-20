import hashlib
import secrets
from datetime import UTC, datetime, timedelta
from uuid import uuid4

from fastapi import APIRouter, HTTPException, status
from firebase_admin import firestore

from ...config import get_settings
from ...domain.models import (
    CircleInvite,
    CircleInviteAccepted,
    CircleInviteCreate,
)
from ...integrations.firebase import firestore_client
from ..dependencies import CurrentUser

router = APIRouter(tags=["circles"])


@router.post(
    "/circles/{circle_id}/invites",
    response_model=CircleInvite,
    status_code=status.HTTP_201_CREATED,
)
async def create_invite(
    circle_id: str, body: CircleInviteCreate, user: CurrentUser
) -> CircleInvite:
    if user.is_anonymous:
        raise HTTPException(status_code=403, detail={"code": "registered_account_required"})

    database = firestore_client()
    membership = (
        database.collection("householdCircles")
        .document(circle_id)
        .collection("members")
        .document(user.uid)
        .get()
    )
    membership_data = membership.to_dict() if membership.exists else {}
    if not membership_data.get("accepted") or membership_data.get("role") not in {
        "owner",
        "admin",
    }:
        raise HTTPException(status_code=403, detail={"code": "circle_admin_required"})

    invite_id = str(uuid4())
    token = secrets.token_urlsafe(32)
    token_hash = hashlib.sha256(token.encode()).hexdigest()
    expires_at = datetime.now(UTC) + timedelta(days=2)
    database.collection("circleInvites").document(invite_id).set(
        {
            "circleId": circle_id,
            "senderId": user.uid,
            "tokenHash": token_hash,
            "intendedContact": {
                "name": body.intended_name,
                "phoneNumber": body.phone_number,
                "email": body.email,
            },
            "expiresAt": expires_at,
            "redeemed": False,
            "createdAt": datetime.now(UTC),
        }
    )
    base = get_settings().app_universal_link_base.rstrip("/")
    return CircleInvite(
        id=invite_id,
        invite_url=f"{base}/{token}",
        expires_at=expires_at,
    )


@router.post(
    "/circle-invites/{token}/accept",
    response_model=CircleInviteAccepted,
)
async def accept_invite(token: str, user: CurrentUser) -> CircleInviteAccepted:
    if user.is_anonymous:
        raise HTTPException(status_code=403, detail={"code": "registered_account_required"})

    database = firestore_client()
    token_hash = hashlib.sha256(token.encode()).hexdigest()
    matches = list(
        database.collection("circleInvites")
        .where("tokenHash", "==", token_hash)
        .limit(1)
        .stream()
    )
    if not matches:
        raise HTTPException(status_code=404, detail={"code": "invite_not_found"})

    invite_ref = matches[0].reference
    transaction = database.transaction()

    @firestore.transactional
    def redeem(current_transaction):
        snapshot = invite_ref.get(transaction=current_transaction)
        invite = snapshot.to_dict() or {}
        expires_at = invite.get("expiresAt")
        if invite.get("redeemed") or expires_at is None or expires_at <= datetime.now(UTC):
            raise HTTPException(status_code=410, detail={"code": "invite_expired"})
        circle_id = invite["circleId"]
        profile_snapshot = database.collection("users").document(user.uid).get()
        profile = profile_snapshot.to_dict() or {}
        personal = profile.get("personalInfo") or {}
        member_ref = (
            database.collection("householdCircles")
            .document(circle_id)
            .collection("members")
            .document(user.uid)
        )
        settings_ref = (
            database.collection("users")
            .document(user.uid)
            .collection("settings")
            .document("app")
        )
        now = datetime.now(UTC)
        current_transaction.set(
            member_ref,
            {
                "userId": user.uid,
                "displayName": personal.get("fullName") or "Circle member",
                "phoneNumber": personal.get("phoneNumber") or "",
                "role": "member",
                "accepted": True,
                "joinedAt": now,
                "sharingPermissions": {"location": False},
            },
        )
        current_transaction.set(settings_ref, {"circleId": circle_id}, merge=True)
        current_transaction.update(
            invite_ref,
            {"redeemed": True, "redeemedBy": user.uid, "redeemedAt": now},
        )
        return circle_id

    circle_id = redeem(transaction)
    return CircleInviteAccepted(circle_id=circle_id)
