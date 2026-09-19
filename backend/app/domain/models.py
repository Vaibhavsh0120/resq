from datetime import datetime, timezone
from typing import Literal
from uuid import uuid4

from pydantic import BaseModel, Field


class UserContext(BaseModel):
    uid: str
    is_anonymous: bool = False


class ConversationCreate(BaseModel):
    language: Literal["en", "hi"] = "en"


class Conversation(BaseModel):
    id: str = Field(default_factory=lambda: str(uuid4()))
    language: Literal["en", "hi"] = "en"
    created_at: datetime = Field(default_factory=lambda: datetime.now(timezone.utc))


class MessageRequest(BaseModel):
    text: str = Field(min_length=1, max_length=8000)
    consent_categories: set[
        Literal["readiness", "coarse_location", "precise_location", "medical", "family"]
    ] = set()


class VoiceSessionRequest(BaseModel):
    conversation_id: str
    language: Literal["en", "hi"] = "en"


class VoiceSession(BaseModel):
    transport: Literal["webrtc", "websocket", "chained"]
    conversation_id: str
    model: str
    ephemeral_token: str | None = None
    expires_at: datetime | None = None


HazardType = Literal[
    "flood",
    "fire",
    "earthquake",
    "landslide",
    "road_block",
    "severe_weather",
    "infrastructure_damage",
    "other",
]


class IncidentReportCreate(BaseModel):
    hazard: HazardType
    description: str = Field(min_length=3, max_length=2000)
    latitude: float | None = Field(default=None, ge=-90, le=90)
    longitude: float | None = Field(default=None, ge=-180, le=180)


class IncidentReport(BaseModel):
    id: str
    status: Literal["pending"] = "pending"
    hazard: HazardType
    created_at: datetime
