import hashlib
from datetime import datetime

from firebase_admin import firestore


class QuotaExceeded(Exception):
    pass


def consume_ai_quota(
    database,
    uid: str,
    client_ip: str,
    is_anonymous: bool,
    now: datetime,
    *,
    guest_limit: int,
    registered_limit: int,
    ip_limit: int,
) -> int:
    day_ref = database.collection("aiUsage").document(now.strftime("%Y%m%d"))
    counters = day_ref.collection("counters")
    user_ref = counters.document(f"user-{uid}")
    limits = [(user_ref, guest_limit if is_anonymous else registered_limit)]
    if is_anonymous:
        ip_hash = hashlib.sha256(client_ip.encode()).hexdigest()[:32]
        limits.append((counters.document(f"ip-{ip_hash}"), ip_limit))

    @firestore.transactional
    def consume(transaction):
        current = [(ref, limit, int((ref.get(transaction=transaction).to_dict() or {}).get("count", 0)))
                   for ref, limit in limits]
        if any(count >= limit for _, limit, count in current):
            raise QuotaExceeded
        transaction.set(day_ref, {"updatedAt": now}, merge=True)
        for ref, _, count in current:
            transaction.set(ref, {"count": count + 1, "updatedAt": now}, merge=True)
        return min(limit - count - 1 for _, limit, count in current)

    return consume(database.transaction())


def remaining_ai_quota(
    database, uid: str, client_ip: str, is_anonymous: bool, now: datetime,
    *, guest_limit: int, registered_limit: int, ip_limit: int,
) -> int:
    counters = database.collection("aiUsage").document(now.strftime("%Y%m%d")).collection("counters")
    used = int((counters.document(f"user-{uid}").get().to_dict() or {}).get("count", 0))
    remaining = max(0, (guest_limit if is_anonymous else registered_limit) - used)
    if is_anonymous:
        ip_hash = hashlib.sha256(client_ip.encode()).hexdigest()[:32]
        ip_used = int((counters.document(f"ip-{ip_hash}").get().to_dict() or {}).get("count", 0))
        remaining = min(remaining, max(0, ip_limit - ip_used))
    return remaining
