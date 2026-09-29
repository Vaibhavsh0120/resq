from datetime import UTC, datetime, timedelta
from types import SimpleNamespace

import pytest
from fastapi.testclient import TestClient

from app.api import dependencies
from app.api.routes import admin
from app.main import app
from scripts import purge_photos


class Snapshot:
    def __init__(self, data, reference=None):
        self._data = data
        self.exists = data is not None
        self.reference = reference
        self.id = "report-1"

    def to_dict(self):
        return self._data


class Reference:
    def __init__(self, data=None):
        self.data = data

    def get(self):
        return Snapshot(self.data, self)

    def update(self, values):
        self.data.update(values)

    def set(self, values):
        self.data = values


class Collection:
    def __init__(self, reference):
        self.reference = reference

    def document(self, _id):
        return self.reference

    def where(self, *_args):
        return self

    def limit(self, _count):
        return self

    def stream(self):
        return [self.reference.get()]


class Database:
    def __init__(self, report):
        self.report = Reference(report)
        self.health = Reference()

    def collection(self, name):
        return Collection(self.health if name == "jobHealth" else self.report)


def test_expired_photo_cannot_be_read_even_by_admin(monkeypatch):
    database = Database({
        "photoState": "clean", "photoPublicId": "private/report-1",
        "photoExpiresAt": datetime.now(UTC) - timedelta(seconds=1),
    })
    monkeypatch.setattr(admin, "firestore_client", lambda: database)
    monkeypatch.setattr(admin.ReportPhotoStorage, "read", lambda *_: pytest.fail("expired photo read"))
    app.dependency_overrides[dependencies.require_admin] = lambda: "moderator"
    try:
        response = TestClient(app).get("/v1/admin/reports/report-1/photo")
        assert response.status_code == 410
    finally:
        app.dependency_overrides.clear()


def test_cloudinary_delete_failure_remains_retryable(monkeypatch):
    database = Database({
        "photoState": "clean", "photoPublicId": "private/report-1",
        "photoExpiresAt": datetime.now(UTC) - timedelta(hours=1),
    })
    monkeypatch.setattr(purge_photos, "firestore_client", lambda: database)
    monkeypatch.setattr(purge_photos, "get_settings", lambda: SimpleNamespace(cloudinary_url=""))

    def fail_delete(_self, _public_id):
        raise RuntimeError("Cloudinary unavailable")

    monkeypatch.setattr(purge_photos.ReportPhotoStorage, "delete", fail_delete)
    with pytest.raises(SystemExit):
        purge_photos.main()
    assert database.report.data["photoState"] == "delete_pending"
    assert database.health.data["overdue"] == 1

    monkeypatch.setattr(purge_photos.ReportPhotoStorage, "delete", lambda *_: None)
    purge_photos.main()
    assert database.report.data["photoState"] == "deleted"
    assert database.report.data["photoPublicId"] is None
