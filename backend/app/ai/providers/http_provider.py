"""Streaming text adapters for the non-OpenAI providers."""

from collections.abc import AsyncIterator
import json

import httpx

from ...config import Settings
from .base import AiProvider


SAFETY_INSTRUCTIONS = (
    "You are ResQ, an India-first disaster safety assistant. Use verified sources, "
    "state uncertainty, direct imminent emergencies to 112, and never claim to dispatch help."
)


class HttpTextProvider(AiProvider):
    def __init__(self, settings: Settings, client: httpx.AsyncClient | None = None) -> None:
        self._settings = settings
        self._client = client

    @property
    def name(self) -> str:
        return self._settings.ai_provider

    async def stream_text(self, *, prompt: str, safety_identifier: str) -> AsyncIterator[str]:
        if not self._settings.ai_api_key:
            raise RuntimeError("AI provider key is not configured")
        url, headers, body = self._request(prompt)
        client = self._client or httpx.AsyncClient(timeout=45)
        try:
            async with client.stream("POST", url, headers=headers, json=body) as response:
                response.raise_for_status()
                async for line in response.aiter_lines():
                    if not line.startswith("data: ") or line == "data: [DONE]":
                        continue
                    data = json.loads(line[6:])
                    if "error" in data or data.get("type") == "error":
                        raise RuntimeError("AI provider stream failed")
                    delta = self._delta(data)
                    if delta:
                        yield delta
        finally:
            if self._client is None:
                await client.aclose()

    def _request(self, prompt: str) -> tuple[str, dict[str, str], dict]:
        raise NotImplementedError

    def _delta(self, data: dict) -> str:
        raise NotImplementedError


class GroqProvider(HttpTextProvider):
    def _request(self, prompt: str) -> tuple[str, dict[str, str], dict]:
        return (
            "https://api.groq.com/openai/v1/chat/completions",
            {"Authorization": f"Bearer {self._settings.ai_api_key}"},
            {
                "model": self._settings.ai_text_model or "llama-3.3-70b-versatile",
                "messages": [
                    {"role": "system", "content": SAFETY_INSTRUCTIONS},
                    {"role": "user", "content": prompt},
                ],
                "stream": True,
            },
        )

    def _delta(self, data: dict) -> str:
        choices = data.get("choices") or []
        return (choices[0].get("delta") or {}).get("content") or "" if choices else ""


class GeminiProvider(HttpTextProvider):
    def _request(self, prompt: str) -> tuple[str, dict[str, str], dict]:
        model = self._settings.ai_text_model or "gemini-2.5-flash-lite"
        return (
            f"https://generativelanguage.googleapis.com/v1beta/models/{model}:streamGenerateContent?alt=sse",
            {"x-goog-api-key": self._settings.ai_api_key},
            {
                "systemInstruction": {"parts": [{"text": SAFETY_INSTRUCTIONS}]},
                "contents": [{"role": "user", "parts": [{"text": prompt}]}],
            },
        )

    def _delta(self, data: dict) -> str:
        candidates = data.get("candidates") or []
        if not candidates:
            return ""
        parts = (candidates[0].get("content") or {}).get("parts") or []
        return "".join(part.get("text", "") for part in parts)


class ClaudeProvider(HttpTextProvider):
    def _request(self, prompt: str) -> tuple[str, dict[str, str], dict]:
        return (
            "https://api.anthropic.com/v1/messages",
            {
                "x-api-key": self._settings.ai_api_key,
                "anthropic-version": "2023-06-01",
            },
            {
                "model": self._settings.ai_text_model or "claude-haiku-4-5",
                "max_tokens": 1024,
                "system": SAFETY_INSTRUCTIONS,
                "messages": [{"role": "user", "content": prompt}],
                "stream": True,
            },
        )

    def _delta(self, data: dict) -> str:
        if data.get("type") != "content_block_delta":
            return ""
        return (data.get("delta") or {}).get("text") or ""
