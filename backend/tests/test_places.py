from app.api.routes.places import distance_km


def test_place_distance_is_zero_at_the_same_coordinate() -> None:
    assert distance_km(28.6139, 77.2090, 28.6139, 77.2090) == 0


def test_place_distance_uses_kilometres() -> None:
    distance = distance_km(28.6139, 77.2090, 28.6200, 77.2150)
    assert 0.8 < distance < 1.0
