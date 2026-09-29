from collections.abc import AsyncIterator

from openai import AsyncOpenAI

from ...config import Settings
from .base import AiProvider


class OpenAiProvider(AiProvider):
    def __init__(self, settings: Settings) -> None:
        self._settings = settings
        self._client = AsyncOpenAI(
            api_key=settings.ai_api_key or "missing-development-key",
            base_url=settings.ai_base_url,
        )

    @property
    def name(self) -> str:
        return self._settings.ai_provider

    async def stream_text(self, *, prompt: str, safety_identifier: str) -> AsyncIterator[str]:
        if not self._settings.ai_api_key:
            raise RuntimeError("AI provider key is not configured")
        stream = await self._client.responses.create(
            model=self._settings.ai_text_model or "gpt-4.1-mini",
            instructions=(
                "You are ResQ, an India-first disaster safety assistant. Use verified sources, "
                "state uncertainty, and direct imminent emergencies to 112. Never claim to dispatch help."
            ),
            input=prompt,
            safety_identifier=safety_identifier,
            stream=True,
        )
        async for event in stream:
            if event.type == "response.output_text.delta":
                yield event.delta
