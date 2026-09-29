from datetime import UTC, datetime, timedelta

from fastapi.testclient import TestClient

from app.api import dependencies
from app.api.routes import alerts
from app.domain.models import UserContext
from app.main import app


NOW = datetime.now(UTC)


class _Snapshot:
    def __init__(self, key, data):
        self.id = key
        self.data = data

    def to_dict(self):
        return self.data


class _Collection:
    def __init__(self, data):
        self.data = data
        self.filters = []
        self.sort_field = None
        self.sort_direction = None
        self.cap = None

    def document(self, key):
        return _Document(self.data.get(key))

    def where(self, field, op, value):
        self.filters.append((field, op, value))
        return self

    def order_by(self, field, direction=None):
        self.sort_field = field
        self.sort_direction = direction
        return self

    def limit(self, count):
        self.cap = count
        return self

    def stream(self):
        rows = list(self.data.items())
        for field, op, value in self.filters:
            if op == ">":
                rows = [(key, data) for key, data in rows if data.get(field) > value]
            elif op == "==":
                rows = [(key, data) for key, data in rows if data.get(field) == value]
            elif op == "array_contains":
                rows = [(key, data) for key, data in rows if value in data.get(field, [])]
            else:
                raise AssertionError(op)
        if self.sort_field:
            rows.sort(key=lambda row: row[1][self.sort_field], reverse=self.sort_direction == "DESCENDING")
        return [_Snapshot(key, data) for key, data in rows[:self.cap]]


class _Document:
    def __init__(self, data):
        self.data = data

    def get(self):
        return self

    def to_dict(self):
        return self.data


class _Database:
    def __init__(self, home=None, events=None):
        self.data = {
            "users": {"guest": {"homeLocation": home or {}}},
            "ingestionState": {"gdacs": {"status": "ok", "lastCheckedAt": NOW}, "ndma": {}, "imd": {}},
            "indiaEvents": events or {},
            "publicAlerts": {},
        }

    def collection(self, name):
        return _Collection(self.data[name])


def _client(monkeypatch, database):
    monkeypatch.setattr(alerts, "firestore_client", lambda: database)
    app.dependency_overrides[dependencies.current_user] = lambda: UserContext(uid="guest", is_anonymous=True)
    return TestClient(app)


def test_india_route_is_available_to_anonymous_user_and_caps_ordered_live_events(monkeypatch):
    events = {
        f"event-{index}": {
            "title": f"Event {index}", "latitude": 20.0, "longitude": 80.0,
            "updatedAt": NOW - timedelta(minutes=index),
            "relevanceEndsAt": NOW + timedelta(days=1),
        }
        for index in range(55)
    }
    events["expired"] = {"title": "Expired", "updatedAt": NOW, "relevanceEndsAt": NOW - timedelta(seconds=1)}
    client = _client(monkeypatch, _Database(events=events))
    try:
        response = client.get("/v1/alerts/india")
        assert response.status_code == 200
        body = response.json()
        assert len(body["items"]) == 50
        assert body["items"][0]["id"] == "event-0"
        assert body["items"][-1]["id"] == "event-49"
        assert body["sourceHealth"]["status"] == "ok"
        assert "expired" not in {item["id"] for item in body["items"]}
    finally:
        app.dependency_overrides.clear()


def test_nearby_returns_saved_home_coverage_point_without_profile_details(monkeypatch):
    client = _client(monkeypatch, _Database(home={
        "city": "New Delhi", "state": "Delhi", "latitude": 28.6139,
        "longitude": 77.209, "addressLine": "private address",
    }))
    try:
        response = client.get("/v1/alerts/nearby")
        assert response.status_code == 200
        body = response.json()
        assert body["homeCenter"] == {"latitude": 28.6139, "longitude": 77.209}
        assert "private address" not in response.text
    finally:
        app.dependency_overrides.clear()


def test_nearby_omits_marker_when_home_coordinates_missing_or_invalid(monkeypatch):
    for home in ({"city": "Delhi", "state": "Delhi"},
                 {"city": "Delhi", "state": "Delhi", "latitude": 120, "longitude": 77}):
        client = _client(monkeypatch, _Database(home=home))
        try:
            response = client.get("/v1/alerts/nearby")
            assert response.status_code == 200
            assert response.json()["homeCenter"] is None
        finally:
            app.dependency_overrides.clear()
