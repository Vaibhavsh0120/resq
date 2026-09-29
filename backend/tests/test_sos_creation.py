from datetime import UTC, datetime, timedelta

from app.services.sos_events import resolve_sos_recipients, should_retry_sos
from fastapi.testclient import TestClient

from app.api import dependencies
from app.api.routes import sos
from app.domain.models import UserContext
from app.main import app


class Snapshot:
    def __init__(self, data):
        self._data = data

    def to_dict(self):
        return self._data


class Document:
    def __init__(self, data, members=None):
        self.data = data
        self.members = members or []

    def get(self):
        return Snapshot(self.data)

    def set(self, data):
        self.data = data

    def collection(self, name):
        if name == "settings":
            return Collection({})
        assert name == "members"
        return Members(self.members)


class Members:
    def __init__(self, members):
        self.members = members

    def where(self, field, operator, value):
        assert (field, operator, value) == ("accepted", "==", True)
        return self

    def stream(self):
        return [Member(uid, data) for uid, data in self.members]

    def document(self, key):
        return Document(next((data for uid, data in self.members if uid == key), None))


class Member:
    def __init__(self, uid, data):
        self.id = uid
        self.data = data

    def to_dict(self):
        return self.data


class Collection:
    def __init__(self, documents):
        self.documents = documents

    def document(self, key):
        if key not in self.documents:
            self.documents[key] = Document(None)
        return self.documents[key]


class Database:
    def __init__(self):
        self.events = {}

    def collection(self, name):
        if name == "users":
            return Collection({"owner": Owner()})
        if name == "householdCircles":
            return Collection({
                "home": Document({}, [
                    ("owner", {"accepted": True}),
                    ("member", {"accepted": True}),
                    ("pending", {"accepted": False}),
                    ("other", {"accepted": True, "userId": "someone-else"}),
                ])
            })
        if name == "sosEvents":
            return Collection(self.events)
        raise AssertionError(name)


class Owner:
    def collection(self, name):
        assert name == "settings"
        return Collection({"app": Document({"circleId": "home"})})


def test_sos_recipients_come_only_from_accepted_circle_members():
    circle_id, recipients = resolve_sos_recipients(Database(), "owner")
    assert circle_id == "home"
    assert recipients == ["member"]


def test_guest_sos_has_no_circle_recipients():
    circle_id, recipients = resolve_sos_recipients(Database(), "guest")
    assert circle_id is None
    assert recipients == []


def test_sos_api_derives_recipients_and_rejects_client_supplied_recipients(monkeypatch):
    database = Database()
    monkeypatch.setattr(sos, "firestore_client", lambda: database)
    app.dependency_overrides[dependencies.current_user] = lambda: UserContext(uid="owner")
    try:
        client = TestClient(app)
        forged = client.post("/v1/sos", json={"authorizedUids": ["attacker"]})
        assert forged.status_code == 422

        response = client.post("/v1/sos", json={"latitude": 28.6139, "longitude": 77.209})
        assert response.status_code == 201
        event = database.events[response.json()["id"]].data
        assert event["authorizedUids"] == ["member"]
        assert event["circleId"] == "home"
        assert event["deliveryStatus"] == "pending"
    finally:
        app.dependency_overrides.clear()


def test_sos_retry_only_claims_pending_or_expired_leases():
    now = datetime(2026, 9, 29, tzinfo=UTC)
    assert should_retry_sos({"deliveryStatus": "pending"}, now)
    assert should_retry_sos({
        "deliveryStatus": "dispatching", "leaseExpiresAt": now - timedelta(seconds=1)
    }, now)
    assert not should_retry_sos({
        "deliveryStatus": "dispatching", "leaseExpiresAt": now + timedelta(seconds=30)
    }, now)
    assert not should_retry_sos({"deliveryStatus": "inbox_delivered"}, now)
