from __future__ import annotations

from math import cos, floor, radians


def geo_cell(latitude: float, longitude: float) -> str:
    """A 0.1 degree search cell; use exact distance after retrieving candidates."""
    return f"{floor(latitude * 10)}:{floor(longitude * 10)}"


def nearby_cells(latitude: float, longitude: float, radius_km: float) -> list[str]:
    lat_delta = radius_km / 111.0
    lng_delta = radius_km / (111.0 * max(cos(radians(latitude)), 0.5))
    south, north = floor((latitude - lat_delta) * 10), floor((latitude + lat_delta) * 10)
    west, east = floor((longitude - lng_delta) * 10), floor((longitude + lng_delta) * 10)
    return [f"{lat}:{lng}" for lat in range(south, north + 1) for lng in range(west, east + 1)]
