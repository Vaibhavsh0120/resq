import asyncio
from datetime import UTC, datetime

from app.config import get_settings
from app.integrations.firebase import firestore_client
from app.integrations.india_events import ingest_gdacs
from app.integrations.official_alerts import expire_old_alerts, ingest_imd, ingest_ndma


async def main() -> None:
    settings = get_settings()
    ndma_count = await ingest_ndma(settings)
    try:
        imd_count = await ingest_imd(settings)
    except Exception as exc:
        firestore_client().collection("ingestionState").document("imd").set(
            {"status": "error", "lastError": type(exc).__name__, "lastErrorAt": datetime.now(UTC)},
            merge=True,
        )
        raise
    try:
        gdacs_count = await ingest_gdacs(firestore_client())
    except Exception as exc:
        # National event coverage is best effort; preserve the local warning run.
        gdacs_count = 0
        print(f"GDACS refresh failed ({type(exc).__name__}); relevant cached events remain available.")
    expired = expire_old_alerts(firestore_client())
    print(f"Ingested {ndma_count} NDMA, {imd_count} IMD alerts and {gdacs_count} GDACS events; expired {expired} alerts.")


if __name__ == "__main__":
    asyncio.run(main())
