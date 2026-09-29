from .openai_provider import OpenAiProvider


class OpenAiCompatibleProvider(OpenAiProvider):
    """Adapter for a Responses-compatible text endpoint."""
