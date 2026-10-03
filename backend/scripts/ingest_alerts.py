import asyncio
from datetime import UTC, datetime

from app.config import get_settings
from app.integrations.firebase import firestore_client
from app.integrations.india_events import ingest_gdacs
from app.integrations.official_alerts import expire_old_alerts, ingest_imd, ingest_ndma


async def main() -> None:
    settings = get_settings()
    database = firestore_client()
    counts, failures = {}, []

    async def source(name, operation):
        try:
            counts[name] = await operation()
        except Exception as exc:
            failures.append(name)
            counts[name] = 0
            database.collection('ingestionState').document(name).set(
                {'status': 'error', 'lastError': type(exc).__name__, 'lastErrorAt': datetime.now(UTC)}, merge=True,
            )
            print(f'{name.upper()} refresh failed ({type(exc).__name__}); relevant cached records remain available.')

    try:
        await asyncio.gather(
            source('ndma', lambda: ingest_ndma(settings)),
            source('imd', lambda: ingest_imd(settings)),
            source('gdacs', lambda: ingest_gdacs(database)),
        )
    finally:
        expired = expire_old_alerts(database)
    print(f'Ingested {counts}; expired {expired} local alerts.')
    if failures:
        raise SystemExit('Feed maintenance needs attention: ' + ', '.join(failures))


if __name__ == '__main__':
    asyncio.run(main())
