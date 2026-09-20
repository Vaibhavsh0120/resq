from functools import lru_cache

from ...config import get_settings
from .base import AiProvider
from .openai_provider import OpenAiProvider
from .openai_compatible_provider import OpenAiCompatibleProvider


def build_ai_provider(settings) -> AiProvider:
    if settings.ai_provider == "openai_compatible":
        return OpenAiCompatibleProvider(settings)
    return OpenAiProvider(settings)


@lru_cache
def get_ai_provider() -> AiProvider:
    return build_ai_provider(get_settings())
