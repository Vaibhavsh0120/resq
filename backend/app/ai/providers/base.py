from abc import ABC, abstractmethod
from collections.abc import AsyncIterator


class AiProvider(ABC):
    @property
    @abstractmethod
    def name(self) -> str: ...

    @abstractmethod
    async def stream_text(self, *, prompt: str, safety_identifier: str) -> AsyncIterator[str]:
        if False:
            yield ""

    @abstractmethod
    async def create_voice_session(self, *, safety_identifier: str) -> dict[str, object]: ...
