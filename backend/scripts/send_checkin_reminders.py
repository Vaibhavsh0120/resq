from datetime import UTC, datetime

from app.integrations.firebase import firestore_client
from app.services.checkin_reminders import send_due_checkin_reminders


if __name__ == "__main__":
    database = firestore_client()
    count = send_due_checkin_reminders(database)
    database.collection("jobHealth").document("checkin").set(
        {"lastRunAt": datetime.now(UTC), "created": count}
    )
    print(f"Created {count} emergency check-in reminders.")
