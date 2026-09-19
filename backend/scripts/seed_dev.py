"""Seed local ResQ data. Refuses to run against unapproved projects."""

from __future__ import annotations

import argparse
import math
import os
from datetime import UTC, datetime, timedelta

import firebase_admin
from firebase_admin import firestore


def _guard_project(project_id: str) -> None:
    emulator = os.getenv("FIRESTORE_EMULATOR_HOST")
    allowlist = {
        value.strip()
        for value in os.getenv("RESQ_DEV_PROJECT_ALLOWLIST", "").split(",")
        if value.strip()
    }
    if not emulator and project_id not in allowlist:
        raise SystemExit(
            "Seed refused: set FIRESTORE_EMULATOR_HOST or explicitly add the "
            "development project to RESQ_DEV_PROJECT_ALLOWLIST."
        )


def _offset(latitude: float, longitude: float, north_km: float, east_km: float) -> tuple[float, float]:
    latitude_delta = north_km / 110.574
    longitude_delta = east_km / (111.320 * math.cos(math.radians(latitude)))
    return latitude + latitude_delta, longitude + longitude_delta


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--project", default=os.getenv("FIREBASE_PROJECT_ID", "resq-dev"))
    parser.add_argument("--lat", type=float, default=28.6139)
    parser.add_argument("--lng", type=float, default=77.2090)
    args = parser.parse_args()
    _guard_project(args.project)

    if not firebase_admin._apps:
        firebase_admin.initialize_app(options={"projectId": args.project})
    database = firestore.client()
    now = datetime.now(UTC)

    nearby_places = [
        ("community-relief-centre", "Community Relief Centre", "relief_centre", 0.8, 0.4),
        ("district-hospital", "District Hospital", "hospital", 1.6, -0.7),
        ("public-shelter", "Public Emergency Shelter", "shelter", -2.1, 1.0),
    ]
    for place_id, name, place_type, north, east in nearby_places:
        lat, lng = _offset(args.lat, args.lng, north, east)
        database.collection("safePlaces").document(place_id).set(
            {
                "name": name,
                "type": place_type,
                "latitude": lat,
                "longitude": lng,
                "geohash": f"dev:{lat:.4f}:{lng:.4f}",
                "phone": "112",
                "facilities": ["first_aid", "drinking_water"],
                "verified": True,
                "verifiedAt": now,
                "updatedAt": now,
            }
        )

    database.collection("publicAlerts").document("district-heavy-rain").set(
        {
            "title": {"en": "Heavy rain warning", "hi": "भारी बारिश की चेतावनी"},
            "summary": {
                "en": "Avoid waterlogged roads and follow district instructions.",
                "hi": "जलभराव वाली सड़कों से बचें और जिला निर्देशों का पालन करें।",
            },
            "severity": "severe",
            "source": "Development fixture",
            "district": "development",
            "issuedAt": now,
            "expiresAt": now + timedelta(hours=12),
            "verified": True,
        }
    )

    database.collection("guidance").document("flood-v1").set(
        {
            "hazard": "flood",
            "version": 1,
            "offlineEligible": True,
            "source": "Curated development guidance",
            "dos": {
                "en": ["Move to higher ground", "Switch off electricity if safe"],
                "hi": ["ऊंचे स्थान पर जाएं", "सुरक्षित हो तो बिजली बंद करें"],
            },
            "donts": {
                "en": ["Do not walk or drive through flood water"],
                "hi": ["बाढ़ के पानी में पैदल या वाहन से न जाएं"],
            },
            "updatedAt": now,
        }
    )
    print(f"Seeded ResQ development data in project {args.project}.")


if __name__ == "__main__":
    main()
