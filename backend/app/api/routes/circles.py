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
    HouseholdCircle,
    CheckInCreate,
)
from ...integrations.firebase import firestore_client
from ..dependencies import CurrentUser

router = APIRouter(tags=["circles"])


@router.post("/circles/{circle_id}/check-ins")
async def create_check_in(circle_id: str, body: CheckInCreate, user: CurrentUser) -> dict:
    if user.is_anonymous:
        raise HTTPException(status_code=403, detail={"code": "registered_account_required"})
    database = firestore_client()
    circle = database.collection("householdCircles").document(circle_id)
    member_ref = circle.collection("members").document(user.uid)
    member = member_ref.get().to_dict() or {}
    if not member.get("accepted") or member.get("userId") != user.uid:
        raise HTTPException(status_code=403, detail={"code": "circle_membership_required"})
    now = datetime.now(UTC)
    settings = (database.collection("users").document(user.uid).collection("settings")
                .document("app").get().to_dict() or {})
    offset = int((settings.get("emergencyCheckIn") or {}).get("timezoneOffsetMinutes") or 0)
    offset = max(-840, min(840, offset))
    local_day = (now + timedelta(minutes=offset)).date()
    if body.event_id:
        event = database.collection("emergencyEvents").document(body.event_id).get()
        event_data = event.to_dict() if event.exists else {}
        if not event.exists or event_data.get("expiresAt") is None or event_data["expiresAt"] <= now:
            raise HTTPException(status_code=409, detail={"code": "emergency_event_not_active"})
    record_id = hashlib.sha256(
        f"{circle_id}:{user.uid}:{body.event_id or 'general'}:{local_day}".encode()
    ).hexdigest()[:32]
    record = circle.collection("checkIns").document(record_id)
    @firestore.transactional
    def commit_check_in(transaction):
        latest_member = member_ref.get(transaction=transaction).to_dict() or {}
        existing = record.get(transaction=transaction)
        if not latest_member.get("accepted") or latest_member.get("userId") != user.uid:
            raise HTTPException(status_code=403, detail={"code": "circle_membership_required"})
        if existing.exists:
            return {"id": record_id, "createdAt": existing.to_dict().get("createdAt"), "alreadyRecorded": True}
        transaction.set(record, {
            "userId": user.uid, "safe": body.safe, "eventId": body.event_id,
            "note": body.note.strip() if body.note else None,
            "location": {"latitude": body.latitude, "longitude": body.longitude}
                        if body.latitude is not None else None,
            "createdAt": now,
        })
        transaction.update(member_ref, {"lastCheckInSafe": body.safe, "lastCheckInAt": now})
        return {"id": record_id, "createdAt": now, "alreadyRecorded": False}

    return commit_check_in(database.transaction())


def build_circle_records(
    *, uid: str, display_name: str, circle_id: str, created_at: datetime
) -> tuple[dict, dict, dict]:
    return (
        {
            "ownerId": uid,
            "name": (
                "My Family Circle"
                if display_name == "My"
                else f"{display_name}'s Family Circle"
            ),
            "createdAt": created_at,
            "updatedAt": created_at,
        },
        {
            "userId": uid,
            "displayName": display_name,
            "phoneNumber": "",
            "role": "owner",
            "accepted": True,
            "joinedAt": created_at,
            "sharingPermissions": {"location": False},
        },
        {"circleId": circle_id},
    )


@router.post(
    "/circles",
    response_model=HouseholdCircle,
    status_code=status.HTTP_201_CREATED,
)
async def create_circle(user: CurrentUser) -> HouseholdCircle:
    if user.is_anonymous:
        raise HTTPException(status_code=403, detail={"code": "registered_account_required"})

    database = firestore_client()
    settings_ref = (
        database.collection("users")
        .document(user.uid)
        .collection("settings")
        .document("app")
    )
    profile = database.collection("users").document(user.uid).get().to_dict() or {}
    personal = profile.get("personalInfo") or {}
    display_name = personal.get("fullName") or "My"
    phone_number = personal.get("phoneNumber") or ""
    circle_id = str(uuid4())
    now = datetime.now(UTC)
    circle, member, settings = build_circle_records(
        uid=user.uid,
        display_name=display_name,
        circle_id=circle_id,
        created_at=now,
    )
    member["phoneNumber"] = phone_number
    circle_ref = database.collection("householdCircles").document(circle_id)
    transaction = database.transaction()

    @firestore.transactional
    def bootstrap(current_transaction):
        existing = settings_ref.get(transaction=current_transaction).to_dict() or {}
        existing_circle_id = existing.get("circleId")
        if existing_circle_id:
            return existing_circle_id, False
        current_transaction.set(circle_ref, circle)
        current_transaction.set(
            circle_ref.collection("members").document(user.uid), member
        )
        current_transaction.set(settings_ref, settings, merge=True)
        return circle_id, True

    resolved_circle_id, created = bootstrap(transaction)
    return HouseholdCircle(circle_id=resolved_circle_id, created=created)


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
        intended = invite.get("intendedContact") or {}
        intended_email = (intended.get("email") or "").strip().casefold()
        if intended_email and intended_email != (user.email or "").strip().casefold():
            raise HTTPException(
                status_code=403,
                detail={"code": "invite_intended_for_another_account"},
            )
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
        existing_settings = (
            settings_ref.get(transaction=current_transaction).to_dict() or {}
        )
        existing_circle_id = existing_settings.get("circleId")
        if existing_circle_id and existing_circle_id != circle_id:
            raise HTTPException(
                status_code=409,
                detail={"code": "circle_membership_already_exists"},
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
