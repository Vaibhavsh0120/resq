from datetime import UTC, datetime

from app.domain.models import ConversationMessage, MessageRequest


def test_conversation_message_serializes_firestore_timestamp() -> None:
    message = ConversationMessage.from_firestore(
        "message-1",
        {
            "role": "assistant",
            "text": "Move to higher ground.",
            "inputType": "voice",
            "createdAt": datetime(2026, 9, 20, 8, 30, tzinfo=UTC),
        },
    )

    assert message.id == "message-1"
    assert message.input_type == "voice"
    assert message.created_at.isoformat() == "2026-09-20T08:30:00+00:00"


def test_voice_transcript_uses_the_same_message_request() -> None:
    request = MessageRequest(text="Where is help?", input_type="voice")
    assert request.input_type == "voice"

