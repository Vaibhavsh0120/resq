from app.integrations.firebase import firestore_client
from app.services.checkin_reminders import send_due_checkin_reminders


if __name__ == "__main__":
    count = send_due_checkin_reminders(firestore_client())
    print(f"Created {count} emergency check-in reminders.")
