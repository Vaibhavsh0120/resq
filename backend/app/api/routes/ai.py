import asyncio
import json
from collections.abc import AsyncIterator
from datetime import UTC, datetime, timedelta
from uuid import uuid4

from fastapi import APIRouter, Depends, HTTPException, Request, status
from fastapi.responses import StreamingResponse

from ...ai.providers.base import AiProvider
from ...ai.providers.factory import get_ai_provider
from ...ai.retrieval.context import (
    authorized_consent_categories,
    grounded_prompt,
    retrieve_context,
)
from ...domain.models import (
    Conversation,
    ConversationCreate,
    ConversationDetail,
    ConversationMessage,
    ConversationSummary,
    MessageRequest,
)
from ...integrations.firebase import firestore_client
from ...config import get_settings
from ...services.ai_quota import QuotaExceeded, consume_ai_quota, remaining_ai_quota
from ...services.client_ip import client_ip
from ..dependencies import CurrentUser

router = APIRouter(prefix="/ai", tags=["assistant"])


@router.get("/capabilities")
async def capabilities(request: Request, user: CurrentUser) -> dict:
    settings = get_settings()
    now = datetime.now(UTC)
    remaining = remaining_ai_quota(
        firestore_client(), user.uid,
        client_ip(request, settings),
        user.is_anonymous, now,
        guest_limit=settings.ai_guest_daily_limit,
        registered_limit=settings.ai_registered_daily_limit,
        ip_limit=settings.ai_guest_ip_daily_limit,
    )
    tomorrow = (now + timedelta(days=1)).replace(hour=0, minute=0, second=0, microsecond=0)
    return {"available": bool(settings.ai_api_key), "dailyRemaining": remaining,
            "resetsAt": tomorrow}


def _owned_conversation(conversation_id: str, user: CurrentUser):
    if user.is_anonymous:
        raise HTTPException(status_code=404, detail={"code": "conversation_not_found"})
    reference = firestore_client().collection("conversations").document(conversation_id)
    snapshot = reference.get()
    if not snapshot.exists or snapshot.to_dict().get("ownerId") != user.uid:
        raise HTTPException(status_code=404, detail={"code": "conversation_not_found"})
    return reference, snapshot.to_dict()


def _conversation_history(reference) -> list[dict[str, str]]:
    documents = (
        reference.collection("messages")
        .order_by("createdAt", direction="DESCENDING")
        .limit(12)
        .stream()
    )
    history = [
        {
            "role": data.get("role", "assistant"),
            "text": str(data.get("text", ""))[:4000],
        }
        for document in documents
        if (data := document.to_dict()).get("text")
    ]
    history.reverse()
    return history


@router.get("/conversations", response_model=list[ConversationSummary])
async def list_conversations(user: CurrentUser) -> list[ConversationSummary]:
    if user.is_anonymous:
        return []
    documents = (
        firestore_client()
        .collection("conversations")
        .where("ownerId", "==", user.uid)
        .order_by("updatedAt", direction="DESCENDING")
        .limit(50)
        .stream()
    )
    return [ConversationSummary.from_firestore(document.id, document.to_dict()) for document in documents]


@router.get("/conversations/{conversation_id}", response_model=ConversationDetail)
async def get_conversation(conversation_id: str, user: CurrentUser) -> ConversationDetail:
    reference, data = _owned_conversation(conversation_id, user)
    messages = reference.collection("messages").order_by("createdAt").stream()
    summary = ConversationSummary.from_firestore(conversation_id, data)
    return ConversationDetail(
        **summary.model_dump(),
        messages=[
            ConversationMessage.from_firestore(message.id, message.to_dict())
            for message in messages
        ],
    )


@router.post("/conversations", response_model=Conversation)
async def create_conversation(body: ConversationCreate, user: CurrentUser) -> Conversation:
    conversation = Conversation(language=body.language)
    if not user.is_anonymous:
        firestore_client().collection("conversations").document(conversation.id).set(
            {
                "ownerId": user.uid,
                "language": conversation.language,
                "createdAt": conversation.created_at,
                "updatedAt": conversation.created_at,
                "title": "New conversation",
            }
        )
    return conversation


@router.post("/conversations/{conversation_id}/messages:stream")
async def stream_message(
    conversation_id: str,
    body: MessageRequest,
    request: Request,
    user: CurrentUser,
    provider: AiProvider = Depends(get_ai_provider),
) -> StreamingResponse:
    settings = get_settings()
    if not settings.ai_api_key:
        raise HTTPException(status_code=503, detail={"code": "assistant_unavailable"})
    conversation_ref = None
    history = [item.model_dump() for item in body.history]
    if not user.is_anonymous:
        conversation_ref = firestore_client().collection("conversations").document(
            conversation_id
        )
        snapshot = conversation_ref.get()
        if not snapshot.exists or snapshot.to_dict().get("ownerId") != user.uid:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail={"code": "conversation_not_found"},
            )
    try:
        consume_ai_quota(
            firestore_client(), user.uid,
            client_ip(request, get_settings()),
            user.is_anonymous, datetime.now(UTC),
            guest_limit=settings.ai_guest_daily_limit,
            registered_limit=settings.ai_registered_daily_limit,
            ip_limit=settings.ai_guest_ip_daily_limit,
        )
    except QuotaExceeded as exc:
        raise HTTPException(status_code=429, detail={"code": "assistant_daily_limit"}) from exc
    if conversation_ref is not None:
        history = await asyncio.to_thread(_conversation_history, conversation_ref)
        message_id = str(uuid4())
        conversation_ref.collection("messages").document(message_id).set(
            {
                "role": "user",
                "text": body.text,
                "createdAt": datetime.now(UTC),
                "inputType": body.input_type,
            }
        )
        if snapshot.to_dict().get("title") in (None, "", "New conversation"):
            conversation_ref.update({"title": body.text[:80]})

    async def events() -> AsyncIterator[str]:
        completed_text = ""
        citations: list[dict[str, str]] = []
        consent = set()
        if not user.is_anonymous:
            consent = await asyncio.to_thread(
                authorized_consent_categories,
                user.uid,
                set(body.consent_categories),
            )
        context = await asyncio.to_thread(
            retrieve_context,
            user.uid,
            consent,
        )
        for alert in context.get("verified_alerts", []):
            source_url = alert.get("sourceUrl")
            if source_url:
                citation = {
                    "title": alert.get("source", "Verified alert"),
                    "url": source_url,
                    "freshness": str(alert.get("issuedAt", "")),
                }
                citations.append(citation)
                yield f"event: citation\ndata: {json.dumps(citation)}\n\n"
        for guide in context.get("guidance", []):
            source_url = guide.get("sourceUrl")
            if source_url:
                citation = {
                    "title": guide.get("source", "Safety guidance"),
                    "url": source_url,
                    "freshness": str(guide.get("version", "")),
                }
                citations.append(citation)
                yield f"event: citation\ndata: {json.dumps(citation)}\n\n"
        async for delta in provider.stream_text(
            prompt=grounded_prompt(body.text, context, history),
            safety_identifier=user.uid,
        ):
            completed_text += delta
            payload = json.dumps({"conversationId": conversation_id, "delta": delta})
            yield f"event: message.delta\ndata: {payload}\n\n"
        if not user.is_anonymous:
            assert conversation_ref is not None
            now = datetime.now(UTC)
            conversation_ref.collection("messages").document(str(uuid4())).set(
                {
                    "role": "assistant",
                    "text": completed_text,
                    "createdAt": now,
                    "inputType": body.input_type,
                    "citations": citations,
                }
            )
            conversation_ref.update({"updatedAt": now})
        yield 'event: message.completed\ndata: {"status":"completed"}\n\n'

    return StreamingResponse(events(), media_type="text/event-stream")
