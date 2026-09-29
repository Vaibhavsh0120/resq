import asyncio
from datetime import UTC, datetime, timedelta

import httpx

from app.integrations.official_alerts import _cached_get, _imd_severity, _imd_warning_text, matches_region, parse_cap


def test_imd_warning_scale_does_not_treat_green_as_critical() -> None:
    assert _imd_severity("1") == "critical"
    assert _imd_severity("2") == "warning"
    assert _imd_severity("3") == "info"
    assert _imd_severity("4") == "info"
    assert _imd_warning_text("1") is None
    assert _imd_warning_text("2,4") == "Heavy rain, Thunderstorm, lightning or squall"
    assert _imd_warning_text("999") is None


def test_cap_requires_documented_region_and_real_expiry() -> None:
    expiry = (datetime.now(UTC) + timedelta(hours=3)).isoformat()
    sent = datetime.now(UTC).isoformat()
    xml = f"""<alert xmlns="urn:oasis:names:tc:emergency:cap:1.2">
      <identifier>test-1</identifier><status>Actual</status><scope>Public</scope><sent>{sent}</sent>
      <info><language>en-IN</language><severity>Severe</severity><expires>{expiry}</expires>
      <headline>Flood warning</headline><description>Official warning</description>
      <area><areaDesc>Khagaria, Bihar</areaDesc></area></info></alert>""".encode()
    alert = parse_cap(xml, "https://sachet.ndma.gov.in/test", "test-1")
    assert alert is not None
    assert alert["severity"] == "warning"
    assert matches_region(alert, city="Khagaria", state="Bihar")
    assert not matches_region(alert, city="Patna", state="Bihar")
    assert not matches_region(alert, city="Khagaria", state="Delhi")
    assert parse_cap(xml.replace(b"Khagaria, Bihar", b"Unknown Region"), "https://sachet.ndma.gov.in/test", "test-1") is None


def test_sachet_304_uses_cached_xml_and_etag() -> None:
    class Snapshot:
        def to_dict(self):
            return {"etag": '"abc"', "cachedXml": "<alert/>"}

    class Ref:
        def get(self):
            return Snapshot()

        def set(self, data, merge=False):
            assert data["status"] == "ok"

    class Collection:
        def document(self, name):
            return Ref()

    class Database:
        def collection(self, name):
            return Collection()

    def respond(request):
        assert request.headers["If-None-Match"] == '"abc"'
        return httpx.Response(304)

    async def fetch():
        async with httpx.AsyncClient(transport=httpx.MockTransport(respond)) as client:
            return await _cached_get(client, Database(), "cap-test", "https://sachet.ndma.gov.in/test")

    content, changed = asyncio.run(fetch())
    assert content == b"<alert/>"
    assert changed is False
