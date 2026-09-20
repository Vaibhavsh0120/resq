from app.ai.providers.factory import build_ai_provider
from app.ai.providers.openai_compatible_provider import OpenAiCompatibleProvider
from app.ai.providers.openai_provider import OpenAiProvider
from app.config import Settings


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

