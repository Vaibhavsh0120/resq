from datetime import UTC, datetime, timedelta

import asyncio
import time

from app.integrations import feed_refresh


class Ref:
    def __init__(self):
        self.data = {}
        self.exists = True
        self.update_time = datetime.now(UTC)

    def get(self, **kwargs):
        return self

    def to_dict(self):
        return self.data.copy()

    def set(self, data, merge=False, **kwargs):
        self.data.update(data)
    def update(self, data, **kwargs):
        self.data.update(data)


class Database:
    def __init__(self, ref):
        self.ref = ref
    def collection(self, name):
        return self
    def document(self, name):
        return self.ref


def test_refresh_lease_allows_one_attempt_per_window_and_recovers_after_crash():
    ref = Ref()
    database = Database(ref)
    now = datetime.now(UTC)
    assert feed_refresh.claim_refresh(database, 'gdacs', now=now)
    assert not feed_refresh.claim_refresh(database, 'gdacs', now=now + timedelta(seconds=1))
    assert feed_refresh.claim_refresh(database, 'gdacs', now=now + timedelta(minutes=3))
    ref.set({'nextRefreshAt': now + timedelta(minutes=30)})
    assert not feed_refresh.claim_refresh(database, 'gdacs', now=now + timedelta(minutes=4))


def test_refresh_failure_keeps_cache_and_allows_bounded_retry(monkeypatch):
    ref = Ref()
    monkeypatch.setattr(feed_refresh, 'claim_refresh', lambda *args: ref)
    monkeypatch.setattr(feed_refresh, 'purge_old_india_events', lambda *args: None)

    async def failed(*args):
        raise RuntimeError('source unavailable')

    monkeypatch.setattr(feed_refresh, 'ingest_gdacs', failed)
    asyncio.run(feed_refresh.refresh_if_due(Database(ref), 'gdacs'))
    assert ref.data['status'] == 'error'
    assert ref.data['lastError'] == 'RuntimeError'
    assert 240 < (ref.data['nextRefreshAt'] - datetime.now(UTC)).total_seconds() <= 300


def test_fresh_manual_feed_is_reused_without_duplicate_ingestion():
    now = datetime.now(UTC)
    ref = Ref()
    ref.data = {'status': 'ok', 'lastCheckedAt': now - timedelta(minutes=5)}
    assert feed_refresh.claim_refresh(Database(ref), 'gdacs', now=now) is None
    assert 'refreshLeaseUntil' not in ref.data


def test_firestore_refresh_calls_have_rpc_deadline_and_no_unbounded_retry():
    class Rpc:
        def get(self, *, timeout, retry):
            assert 0 < timeout <= 0.051
            assert retry is None
            return 'cached'
    bounded = feed_refresh.BoundedFirestore(Rpc(), time.monotonic() + 0.05)
    assert bounded.get() == 'cached'
    expired = feed_refresh.BoundedFirestore(Rpc(), time.monotonic() - 1)
    try:
        expired.get()
    except TimeoutError:
        pass
    else:
        raise AssertionError('Expired refresh attempted a database RPC')


def test_ndma_failure_does_not_skip_imd_or_cleanup(monkeypatch):
    calls = []
    ref = Ref()
    class Database:
        def collection(self, name):
            return self
        def document(self, name):
            return ref
    monkeypatch.setattr(feed_refresh, 'claim_refresh', lambda *args: ref)
    async def ndma(*args, **kwargs):
        calls.append('ndma')
        raise RuntimeError('source unavailable')
    async def imd(*args, **kwargs):
        calls.append('imd')
    monkeypatch.setattr(feed_refresh, 'ingest_ndma', ndma)
    monkeypatch.setattr(feed_refresh, 'ingest_imd', imd)
    monkeypatch.setattr(feed_refresh, 'expire_old_alerts', lambda *args: calls.append('purge'))
    asyncio.run(feed_refresh.refresh_if_due(Database(), 'ndma'))
    assert calls == ['ndma', 'imd', 'purge']
