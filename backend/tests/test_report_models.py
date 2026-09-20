import pytest
from pydantic import ValidationError

from app.domain.models import CircleInviteCreate, DeviceRegistration, IncidentReportCreate
from app.services.sos_fanout import build_sos_notification


def test_incident_report_accepts_supported_hazard_and_rejects_unknown():
    report = IncidentReportCreate(
        hazard="flood",
        description="Water rising near the bridge",
        latitude=28.6139,
        longitude=77.2090,
    )
    assert report.hazard == "flood"

    with pytest.raises(ValidationError):
        IncidentReportCreate(hazard="meteor", description="Unexpected event")


def test_circle_invite_requires_an_intended_contact():
    invite = CircleInviteCreate(phone_number="+919999999999")
    assert invite.phone_number == "+919999999999"

    with pytest.raises(ValidationError):
        CircleInviteCreate()


def test_sos_notification_is_durable_and_deep_linked():
    payload = build_sos_notification("event-1", "Maya")

    assert payload["severity"] == "critical"
    assert payload["read"] is False
    assert payload["deepLink"] == "/sos/event-1"


def test_device_registration_accepts_supported_platform():
    device = DeviceRegistration(token="fcm-token", platform="android")
    assert device.platform == "android"

    with pytest.raises(ValidationError):
        DeviceRegistration(token="fcm-token", platform="unsupported")
