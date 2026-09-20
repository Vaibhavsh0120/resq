from .openai_provider import OpenAiProvider


class OpenAiCompatibleProvider(OpenAiProvider):
    """Adapter for compatible Responses endpoints without native Realtime."""

    async def create_voice_session(
        self,
        *,
        safety_identifier: str,
        language: str,
        conversation_context: str = "",
    ) -> dict[str, object]:
        return {
            "transport": "chained",
            "ephemeral_token": None,
            "expires_at": None,
        }
