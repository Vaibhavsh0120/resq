import asyncio
from datetime import UTC, datetime, timedelta

import pytest


def _module():
    from app.integrations import india_events
    return india_events


NOW = datetime(2026, 9, 30, tzinfo=UTC)


def _feature(*, event_id=1104121, episode_id=19, country="India", point=(79.0499, 30.0203), end="2026-09-28T01:00:00", report="https://www.gdacs.org/report.aspx?eventid=1104121"):
    return {
        "type": "Feature",
        "geometry": {"type": "Point", "coordinates": list(point)},
        "properties": {
            "eventtype": "FL", "eventid": event_id, "episodeid": episode_id,
            "name": "Flood in India", "country": country,
            "iso3": "IND" if country == "India" else "NPL",
            "affectedcountries": [{"iso3": "IND", "countryname": "India"}] if country != "India" else [],
            "fromdate": "2026-09-24T01:00:00", "todate": end,
            "datemodified": "2026-09-29T11:25:14", "alertlevel": "Orange",
            "url": {"report": report},
        },
    }


class _Snapshot:
    def __init__(self, ref):
        self.reference = ref
        self.id = ref.id

    def to_dict(self):
        return self.reference.data


class _Ref:
    def __init__(self, items, key):
        self.items = items
        self.id = key

    @property
    def data(self):
        return self.items.get(self.id)

    def set(self, value, merge=False):
        self.items[self.id] = {**(self.data or {}), **value} if merge else value

    def get(self):
        return _Snapshot(self)

    def delete(self):
        self.items.pop(self.id, None)


class _Collection:
    def __init__(self, items):
        self.items = items
        self.cutoff = None
        self.cap = None

    def document(self, key):
        return _Ref(self.items, key)

    def where(self, field, op, value):
        assert field == "relevanceEndsAt" and op == "<="
        self.cutoff = value
        return self

    def limit(self, count):
        self.cap = count
        return self

    def stream(self):
        rows = [
            _Snapshot(_Ref(self.items, key))
            for key, item in list(self.items.items())
            if self.cutoff is None or item["relevanceEndsAt"] <= self.cutoff
        ]
        return rows[:self.cap]


class _Database:
    def __init__(self):
        self.events = {}
        self.state = {}

    def collection(self, name):
        assert name in {"indiaEvents", "ingestionState"}
        return _Collection(self.events if name == "indiaEvents" else self.state)


def test_normalizes_india_and_offshore_events_with_stable_identity():
    india_events = _module()
    indian = india_events.parse_gdacs_feature(_feature(), NOW)
    offshore = india_events.parse_gdacs_feature(_feature(country="Nepal", point=(85.0, 26.0)), NOW)
    assert indian is not None and offshore is not None
    assert indian["id"] == "gdacs-FL-1104121-19"
    assert indian["latitude"] == 30.0203
    assert indian["longitude"] == 79.0499
    assert indian["relevanceEndsAt"] == datetime(2026, 10, 5, 1, tzinfo=UTC)
    assert indian["sourceUrl"].startswith("https://www.gdacs.org/report.aspx")
    assert offshore["countryLabel"] == "India-impacting"
    assert india_events.parse_gdacs_feature(_feature(episode_id=20), NOW)["id"] != indian["id"]


@pytest.mark.parametrize("change", [
    {"geometry": {"type": "Point", "coordinates": [190, 20]}},
    {"geometry": {"type": "Polygon", "coordinates": []}},
    {"properties": {"country": "Nepal", "iso3": "NPL", "affectedcountries": []}},
    {"properties": {"todate": ""}},
    {"properties": {"todate": "2026-09-20T01:00:00"}},
    {"properties": {"url": {"report": "https://other.example/report"}}},
])
def test_rejects_unmappable_unrelated_expired_or_unsafe_events(change):
    india_events = _module()
    feature = _feature()
    for key, value in change.items():
        feature[key] = {**feature[key], **value}
    assert india_events.parse_gdacs_feature(feature, NOW) is None


@pytest.mark.parametrize("feature_count", [100, 105])
def test_ingest_is_bounded_and_purges_expired(monkeypatch, feature_count):
    india_events = _module()
    db = _Database()
    db.events["old"] = {"relevanceEndsAt": NOW - timedelta(seconds=1)}

    async def fetch(*args, **kwargs):
        return {"type": "FeatureCollection", "features": [_feature(event_id=number) for number in range(1, feature_count + 1)]}

    monkeypatch.setattr(india_events, "_fetch_gdacs", fetch)
    assert asyncio.run(india_events.ingest_gdacs(db, now=NOW)) == 100
    assert len(db.events) == 100
    assert "old" not in db.events
    assert db.state["gdacs"]["status"] == "ok"
    assert db.state["gdacs"]["truncated"] is True


def test_failed_refresh_keeps_recent_cache_but_purges_expired(monkeypatch):
    india_events = _module()
    db = _Database()
    db.events["recent"] = {"relevanceEndsAt": NOW + timedelta(days=1)}
    db.events["old"] = {"relevanceEndsAt": NOW - timedelta(seconds=1)}

    async def fail(*args, **kwargs):
        raise OSError("network down")

    monkeypatch.setattr(india_events, "_fetch_gdacs", fail)
    with pytest.raises(OSError):
        asyncio.run(india_events.ingest_gdacs(db, now=NOW))
    assert set(db.events) == {"recent"}
    assert db.state["gdacs"]["status"] == "error"
