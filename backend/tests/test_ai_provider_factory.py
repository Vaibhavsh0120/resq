from app.ai.providers.factory import build_ai_provider
from app.ai.providers.openai_compatible_provider import OpenAiCompatibleProvider
from app.ai.providers.openai_provider import OpenAiProvider
from app.config import Settings
import asyncio
import httpx
import pytest


def test_provider_factory_keeps_vendor_choice_behind_adapter() -> None:
    assert isinstance(
        build_ai_provider(Settings(ai_provider="openai")),
        OpenAiProvider,
    )
    assert isinstance(
        build_ai_provider(
            Settings(
                ai_provider="openai_compatible",
                ai_base_url="http://localhost:11434/v1",
            )
        ),
        OpenAiCompatibleProvider,
    )
    for provider in ("groq", "gemini", "claude"):
        selected = build_ai_provider(Settings(ai_provider=provider))
        assert selected.name == provider


@pytest.mark.parametrize("provider,body,expected_path", [
    ("groq", 'data: {"choices":[{"delta":{"content":"Help"}}]}\n\n', "/openai/v1/chat/completions"),
    ("gemini", 'data: {"candidates":[{"content":{"parts":[{"text":"Help"}]}}]}\n\n', ":streamGenerateContent"),
    ("claude", 'event: content_block_delta\ndata: {"type":"content_block_delta","delta":{"text":"Help"}}\n\n', "/v1/messages"),
])
def test_provider_stream_contract(provider, body, expected_path):
    def respond(request: httpx.Request) -> httpx.Response:
        assert expected_path in str(request.url)
        return httpx.Response(200, text=body)

    async def collect():
        async with httpx.AsyncClient(transport=httpx.MockTransport(respond)) as client:
            adapter = build_ai_provider(
                Settings(ai_provider=provider, ai_api_key="test-key"), client=client
            )
            return [piece async for piece in adapter.stream_text(prompt="Where is help?", safety_identifier="user")]

    assert asyncio.run(collect()) == ["Help"]

