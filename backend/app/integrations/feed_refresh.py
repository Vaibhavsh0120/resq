"""Request-driven feeds with a global lease and bounded database RPCs."""

import asyncio
import time
from datetime import UTC, datetime, timedelta

from firebase_admin import firestore
from google.api_core.exceptions import Conflict, FailedPrecondition

from ..config import get_settings
from .india_events import ingest_gdacs, purge_old_india_events
from .official_alerts import expire_old_alerts, ingest_imd, ingest_ndma


class BoundedFirestore:
    """Propagate one wall-clock deadline through fluent references and snapshots."""
    def __init__(self, target, deadline: float):
        self._target, self._deadline = target, deadline

    def __getattr__(self, name):
        value = getattr(self._target, name)
        if name == 'reference':
            return BoundedFirestore(value, self._deadline)
        if not callable(value):
            return value

        def call(*args, **kwargs):
            if name in {'get', 'set', 'create', 'update', 'delete', 'stream', 'commit'}:
                remaining = self._deadline - time.monotonic()
                if remaining <= 0:
                    raise TimeoutError('Feed database deadline exceeded')
                kwargs.update(timeout=min(3.0, remaining), retry=None)
            result = value(*args, **kwargs)
            if name in {'collection', 'document', 'where', 'order_by', 'limit'}:
                return BoundedFirestore(result, self._deadline)
            if name == 'get' and hasattr(result, 'to_dict'):
                return BoundedFirestore(result, self._deadline)
            if name == 'stream':
                return self._stream(result)
            return result
        return call

    def _stream(self, rows):
        for row in rows:
            if time.monotonic() >= self._deadline:
                raise TimeoutError('Feed database deadline exceeded')
            yield BoundedFirestore(row, self._deadline)


def claim_refresh(database, source: str, *, now=None):
    reference = database.collection('ingestionState').document(source)
    snapshot = reference.get()
    state = snapshot.to_dict() or {}
    now = now or datetime.now(UTC)
    if any(state.get(key) and state[key] > now for key in ('refreshLeaseUntil', 'nextRefreshAt')):
        return None
    checked = state.get('lastCheckedAt')
    if state.get('status') == 'ok' and isinstance(checked, datetime) and now - checked < timedelta(minutes=30):
        return None
    lease = {'refreshLeaseUntil': now + timedelta(minutes=2)}
    try:
        if snapshot.exists:
            reference.update(lease, option=firestore.LastUpdateOption(snapshot.update_time))
        else:
            reference.create(lease)
    except (Conflict, FailedPrecondition):
        return None  # Another invocation won the atomic compare-and-swap.
    return reference


def _refresh(database, source: str):
    started = time.monotonic()
    bounded = BoundedFirestore(database, started + 30)
    try:
        reference = claim_refresh(bounded, source)
    except Exception:
        return  # Cached response is still usable if claiming fails.
    if reference is None:
        return
    failed = False

    async def ingest_one(name, operation):
        nonlocal failed
        try:
            remaining = started + 30 - time.monotonic()
            if remaining <= 0:
                raise TimeoutError('Feed refresh deadline exceeded')
            await asyncio.wait_for(operation(), timeout=remaining)
        except Exception as exc:
            failed = True
            # Allow a short, separate budget for recording failure and cleanup.
            health = BoundedFirestore(database, started + 40).collection('ingestionState').document(name)
            health.set({'status': 'error', 'lastError': type(exc).__name__,
                        'lastErrorAt': datetime.now(UTC)}, merge=True)

    async def run():
        if source == 'gdacs':
            await ingest_one('gdacs', lambda: ingest_gdacs(bounded))
        else:
            settings = get_settings()
            # Separate tasks mean NDMA failure cannot suppress IMD.
            await asyncio.gather(
                ingest_one('ndma', lambda: ingest_ndma(settings, database=bounded)),
                ingest_one('imd', lambda: ingest_imd(settings, database=bounded)),
                return_exceptions=True,
            )

    try:
        asyncio.run(run())
    except Exception:
        failed = True
    finally:
        final_store = BoundedFirestore(database, started + 40)
        try:
            if source == 'gdacs':
                purge_old_india_events(final_store)
            else:
                expire_old_alerts(final_store)
        except Exception:
            failed = True
        try:
            ref = final_store.collection('ingestionState').document(source)
            failed = failed or (ref.get().to_dict() or {}).get('status') != 'ok'
            now = datetime.now(UTC)
            ref.set({'refreshLeaseUntil': now, 'nextRefreshAt': now + timedelta(minutes=5 if failed else 30)}, merge=True)
        except Exception:
            pass  # A terminated invocation's lease expires after two minutes.


async def refresh_if_due(database, source: str) -> None:
    """Keep blocking RPCs off the server loop; reserve time for cached reads."""
    await asyncio.to_thread(_refresh, database, source)
