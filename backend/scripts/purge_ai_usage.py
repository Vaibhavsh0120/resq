"""Remove old daily AI quota counters, including hashed guest IP counters."""

from datetime import UTC, datetime, timedelta

from app.integrations.firebase import firestore_client


def main() -> None:
    database = firestore_client()
    cutoff = (datetime.now(UTC) - timedelta(days=35)).strftime("%Y%m%d")
    removed = 0
    for day in database.collection("aiUsage").list_documents():
        if day.id >= cutoff:
            continue
        for counter in day.collection("counters").stream():
            counter.reference.delete()
        day.delete()
        removed += 1
    print(f"Purged {removed} old AI usage days.")


if __name__ == "__main__":
    main()
