from math import asin, cos, radians, sin, sqrt

from fastapi import APIRouter, Query

from ...integrations.firebase import firestore_client
from ...services.geo_cells import nearby_cells
from ..dependencies import CurrentUser

router = APIRouter(prefix="/places", tags=["places"])


def distance_km(lat_a: float, lng_a: float, lat_b: float, lng_b: float) -> float:
    delta_lat = radians(lat_b - lat_a)
    delta_lng = radians(lng_b - lng_a)
    value = (
        sin(delta_lat / 2) ** 2
        + cos(radians(lat_a)) * cos(radians(lat_b)) * sin(delta_lng / 2) ** 2
    )
    return 6371.0 * 2 * asin(sqrt(value))


@router.get("/nearby")
async def nearby_places(
    _: CurrentUser,
    lat: float = Query(ge=-90, le=90),
    lng: float = Query(ge=-180, le=180),
    radiusKm: float = Query(default=5, gt=0, le=5),
    cursor: str | None = Query(default=None, max_length=128),
) -> dict:
    database = firestore_client()
    cells = nearby_cells(lat, lng, radiusKm)
    query = (
        database.collection("safePlaces")
        .where("verified", "==", True)
        .where("geoCell", "in", cells)
        .order_by("__name__")
        .limit(101)
    )
    if cursor:
        snapshot = database.collection("safePlaces").document(cursor).get()
        if snapshot.exists:
            query = query.start_after(snapshot)
    documents = list(query.stream())
    page = documents[:100]
    results = []
    for document in page:
        data = document.to_dict() or {}
        place_lat = data.get("latitude")
        place_lng = data.get("longitude")
        if place_lat is None or place_lng is None:
            continue
        distance = distance_km(lat, lng, float(place_lat), float(place_lng))
        if distance <= radiusKm:
            results.append(
                {
                    "id": document.id,
                    **data,
                    "distanceKm": round(distance, 3),
                }
            )
    results.sort(key=lambda item: item["distanceKm"])
    return {"items": results, "nextCursor": page[-1].id if len(documents) > 100 else None}
