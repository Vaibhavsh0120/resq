from datetime import UTC, datetime

from app.services.checkin_reminders import is_checkin_due


def test_delayed_free_scheduler_still_sends_same_day_checkin():
    now = datetime(2026, 9, 29, 3, 35, tzinfo=UTC)
    assert is_checkin_due(now, "09:00", 330)
    assert not is_checkin_due(now, "09:30", 330)
