from functools import lru_cache

from ...config import get_settings
from .base import AiProvider
from .openai_provider import OpenAiProvider
from .openai_compatible_provider import OpenAiCompatibleProvider
from .http_provider import ClaudeProvider, GeminiProvider, GroqProvider


def build_ai_provider(settings, client=None) -> AiProvider:
    if settings.ai_provider == "groq":
        return GroqProvider(settings, client=client)
    if settings.ai_provider == "gemini":
        return GeminiProvider(settings, client=client)
    if settings.ai_provider == "claude":
        return ClaudeProvider(settings, client=client)
    if settings.ai_provider == "openai_compatible":
        return OpenAiCompatibleProvider(settings)
    return OpenAiProvider(settings)


@lru_cache
def get_ai_provider() -> AiProvider:
    return build_ai_provider(get_settings())
