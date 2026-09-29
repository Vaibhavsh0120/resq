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
