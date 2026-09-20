from datetime import datetime, timezone
from typing import Literal
from uuid import uuid4

from pydantic import BaseModel, Field, model_validator


class UserContext(BaseModel):
    uid: str
    is_anonymous: bool = False
    email: str | None = None
    phone_number: str | None = None


class ConversationCreate(BaseModel):
    language: Literal["en", "hi"] = "en"


class Conversation(BaseModel):
    id: str = Field(default_factory=lambda: str(uuid4()))
    language: Literal["en", "hi"] = "en"
    created_at: datetime = Field(default_factory=lambda: datetime.now(timezone.utc))


class ConversationSummary(Conversation):
    title: str = "New conversation"
    updated_at: datetime = Field(default_factory=lambda: datetime.now(timezone.utc))

    @classmethod
    def from_firestore(cls, conversation_id: str, data: dict) -> "ConversationSummary":
        created_at = data.get("createdAt") or datetime.now(timezone.utc)
        return cls(
            id=conversation_id,
            language=data.get("language", "en"),
            title=data.get("title") or "New conversation",
            created_at=created_at,
            updated_at=data.get("updatedAt") or created_at,
        )


class ConversationMessage(BaseModel):
    id: str
    role: Literal["user", "assistant"]
    text: str
    input_type: Literal["text", "voice"] = "text"
    created_at: datetime
    citations: list[dict[str, str]] = Field(default_factory=list)

    @classmethod
    def from_firestore(cls, message_id: str, data: dict) -> "ConversationMessage":
        return cls(
            id=message_id,
            role=data.get("role", "assistant"),
            text=data.get("text", ""),
            input_type=data.get("inputType", "text"),
            created_at=data.get("createdAt") or datetime.now(timezone.utc),
            citations=data.get("citations") or [],
        )


class ConversationDetail(ConversationSummary):
    messages: list[ConversationMessage] = Field(default_factory=list)


class VoiceTranscriptRequest(BaseModel):
    user_text: str | None = Field(default=None, max_length=8000)
    assistant_text: str | None = Field(default=None, max_length=8000)

    @model_validator(mode="after")
    def has_transcript(self):
        if not (self.user_text or self.assistant_text):
            raise ValueError("At least one transcript is required")
        return self


class ConversationHistoryItem(BaseModel):
    role: Literal["user", "assistant"]
    text: str = Field(min_length=1, max_length=4000)


class MessageRequest(BaseModel):
    text: str = Field(min_length=1, max_length=8000)
    history: list[ConversationHistoryItem] = Field(default_factory=list, max_length=20)
    consent_categories: set[
        Literal["readiness", "coarse_location", "precise_location", "medical", "family"]
    ] = set()


class VoiceSessionRequest(BaseModel):
    conversation_id: str
    language: Literal["en", "hi"] = "en"
    consent_categories: set[
        Literal["readiness", "coarse_location", "precise_location", "medical", "family"]
    ] = set()


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


class ReportPhotoUpload(BaseModel):
    uploaded: bool = True
    content_type: str


class ReportApproval(BaseModel):
    public_description: str = Field(min_length=3, max_length=1000)


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


class HouseholdCircle(BaseModel):
    circle_id: str
    created: bool = True


class SosFanoutResult(BaseModel):
    notification_count: int
    push_success_count: int
    push_failure_count: int


class DeviceRegistration(BaseModel):
    token: str = Field(min_length=8, max_length=4096)
    platform: Literal["android", "ios", "macos", "web"]


class DeviceRegistrationResult(BaseModel):
    registered: bool = True
