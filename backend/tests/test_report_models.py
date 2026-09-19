import pytest
from pydantic import ValidationError

from app.domain.models import IncidentReportCreate


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
