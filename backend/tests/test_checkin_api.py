from fastapi.testclient import TestClient

from app.api import dependencies
from app.api.routes import circles
from app.domain.models import UserContext
from app.main import app


class Snapshot:
    def __init__(self, data):
        self.data = data
        self.exists = data is not None

    def to_dict(self):
        return self.data


class Reference:
    def __init__(self, store, path):
        self.store = store
        self.path = path

    def collection(self, name):
        return Collection(self.store, f"{self.path}/{name}")

    def get(self, **_kwargs):
        return Snapshot(self.store.get(self.path))


class Collection:
    def __init__(self, store, path):
        self.store = store
        self.path = path

    def document(self, document_id):
        return Reference(self.store, f"{self.path}/{document_id}")


class Transaction:
    def __init__(self, store):
        self.store = store

    def set(self, reference, data):
        self.store[reference.path] = data

    def update(self, reference, data):
        self.store[reference.path].update(data)


class Database:
    def __init__(self, member):
        self.store = {
            "householdCircles/home/members/member": member,
            "users/member/settings/app": {},
        }

    def collection(self, name):
        return Collection(self.store, name)

    def transaction(self):
        return Transaction(self.store)


def test_checkin_rejects_nonmember_and_repeats_without_overwrite(monkeypatch):
    database = Database({"accepted": False, "userId": "member"})
    monkeypatch.setattr(circles, "firestore_client", lambda: database)
    monkeypatch.setattr(circles.firestore, "transactional", lambda function: function)
    app.dependency_overrides[dependencies.current_user] = lambda: UserContext(uid="member")
    try:
        client = TestClient(app)
        assert client.post("/v1/circles/home/check-ins", json={"safe": True}).status_code == 403
        database.store["householdCircles/home/members/member"]["accepted"] = True
        first = client.post("/v1/circles/home/check-ins", json={"safe": True})
        second = client.post("/v1/circles/home/check-ins", json={"safe": False})
        assert first.status_code == second.status_code == 200
        assert first.json()["alreadyRecorded"] is False
        assert second.json()["alreadyRecorded"] is True
        assert first.json()["id"] == second.json()["id"]
        assert database.store["householdCircles/home/members/member"]["lastCheckInSafe"] is True
    finally:
        app.dependency_overrides.clear()
