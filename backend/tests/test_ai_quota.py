from datetime import UTC, datetime

import pytest

from app.services.ai_quota import QuotaExceeded, consume_ai_quota


class Snapshot:
    def __init__(self, value):
        self.value = value

    def to_dict(self):
        return {"count": self.value}


class Ref:
    def __init__(self, store, path):
        self.store = store
        self.path = path

    def collection(self, key):
        return Ref(self.store, f"{self.path}/{key}")

    def document(self, key):
        return Ref(self.store, f"{self.path}/{key}")

    def get(self, transaction=None):
        return Snapshot(self.store.get(self.path, 0))


class Transaction:
    def set(self, ref, data, merge=False):
        ref.store[ref.path] = data.get("count", 0)


class Database:
    def __init__(self):
        self.store = {}

    def collection(self, key):
        return Ref(self.store, key)

    def transaction(self):
        return Transaction()


def test_guest_ai_quota_is_durable_per_guest_and_ip(monkeypatch):
    import app.services.ai_quota as quota

    monkeypatch.setattr(quota.firestore, "transactional", lambda fn: fn)
    database = Database()
    now = datetime(2026, 9, 29, tzinfo=UTC)
    for _ in range(2):
        consume_ai_quota(database, "guest-1", "192.0.2.1", True, now, guest_limit=2, registered_limit=20, ip_limit=3)
    with pytest.raises(QuotaExceeded):
        consume_ai_quota(database, "guest-1", "192.0.2.1", True, now, guest_limit=2, registered_limit=20, ip_limit=3)
    consume_ai_quota(database, "guest-2", "192.0.2.1", True, now, guest_limit=2, registered_limit=20, ip_limit=3)
    with pytest.raises(QuotaExceeded):
        consume_ai_quota(database, "guest-3", "192.0.2.1", True, now, guest_limit=2, registered_limit=20, ip_limit=3)
