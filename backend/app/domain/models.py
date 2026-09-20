from datetime import datetime, timezone
from typing import Literal
from uuid import uuid4

from pydantic import BaseModel, Field, model_validator


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


class CircleInviteCreate(BaseModel):
    intended_name: str | None = Field(default=None, max_length=120)
    phone_number: str | None = Field(default=None, max_length=32)
    email: str | None = Field(default=None, max_length=320)

    @model_validator(mode="after")
    def has_contact(self):
        if not (self.phone_number or self.email):
            raise ValueError("A phone number or email is required")
        return self


class CircleInvite(BaseModel):
    id: str
    invite_url: str
    expires_at: datetime


class CircleInviteAccepted(BaseModel):
    circle_id: str
    accepted: bool = True


class SosFanoutResult(BaseModel):
    notification_count: int
    push_success_count: int
    push_failure_count: int


class DeviceRegistration(BaseModel):
    token: str = Field(min_length=8, max_length=4096)
    platform: Literal["android", "ios", "macos", "web"]


class DeviceRegistrationResult(BaseModel):
    registered: bool = True
