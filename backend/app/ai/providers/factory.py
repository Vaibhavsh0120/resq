from functools import lru_cache

from ...config import get_settings
from .base import AiProvider
from .openai_provider import OpenAiProvider


@lru_cache
def get_ai_provider() -> AiProvider:
    return OpenAiProvider(get_settings())
