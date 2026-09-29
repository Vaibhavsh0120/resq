from app.services.geo_cells import geo_cell, nearby_cells


def test_nearby_cells_include_boundary_crossings() -> None:
    cells = nearby_cells(28.699, 77.299, 5)
    assert geo_cell(28.699, 77.299) in cells
    assert geo_cell(28.73, 77.33) in cells
    assert geo_cell(28.67, 77.27) in cells
    assert len(cells) <= 30
