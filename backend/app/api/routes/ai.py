import json
from collections.abc import AsyncIterator
from datetime import UTC, datetime
from uuid import uuid4

from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.responses import StreamingResponse

from ...ai.providers.base import AiProvider
from ...ai.providers.factory import get_ai_provider
from ...domain.models import (
    Conversation,
    ConversationCreate,
    MessageRequest,
    VoiceSession,
    VoiceSessionRequest,
)
from ...integrations.firebase import firestore_client
from ..dependencies import CurrentUser

router = APIRouter(prefix="/ai", tags=["assistant"])


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
            }
        )
    return conversation


@router.post("/conversations/{conversation_id}/messages:stream")
async def stream_message(
    conversation_id: str,
    body: MessageRequest,
    user: CurrentUser,
    provider: AiProvider = Depends(get_ai_provider),
) -> StreamingResponse:
    conversation_ref = None
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
        message_id = str(uuid4())
        conversation_ref.collection("messages").document(message_id).set(
            {
                "role": "user",
                "text": body.text,
                "createdAt": datetime.now(UTC),
                "inputType": "text",
            }
        )

    async def events() -> AsyncIterator[str]:
        completed_text = ""
        async for delta in provider.stream_text(prompt=body.text, safety_identifier=user.uid):
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
                    "inputType": "text",
                    "provider": provider.name,
                }
            )
            conversation_ref.update({"updatedAt": now})
        yield 'event: message.completed\ndata: {"status":"completed"}\n\n'

    return StreamingResponse(events(), media_type="text/event-stream")


@router.post("/voice/sessions", response_model=VoiceSession)
async def create_voice_session(
    body: VoiceSessionRequest,
    user: CurrentUser,
    provider: AiProvider = Depends(get_ai_provider),
) -> VoiceSession:
    session = await provider.create_voice_session(safety_identifier=user.uid)
    return VoiceSession(
        conversation_id=body.conversation_id,
        model=getattr(provider, "_settings").ai_voice_model,
        **session,
    )
