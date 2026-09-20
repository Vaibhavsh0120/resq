from datetime import UTC, datetime

from app.domain.models import ConversationMessage


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

