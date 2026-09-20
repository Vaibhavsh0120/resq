import asyncio

from app.config import get_settings
from app.integrations.official_alerts import ingest_imd, ingest_ndma


async def main() -> None:
    settings = get_settings()
    ndma_count = await ingest_ndma(settings)
    imd_count = await ingest_imd(settings)
    print(f"Ingested {ndma_count} NDMA and {imd_count} IMD alert records.")


if __name__ == "__main__":
    asyncio.run(main())
