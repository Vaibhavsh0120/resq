from io import BytesIO

from PIL import Image

from app.services.report_photos import sanitize_report_photo


def test_report_photo_is_reencoded_without_metadata() -> None:
    source = BytesIO()
    image = Image.new("RGB", (32, 24), "red")
    image.save(source, format="JPEG", exif=b"Exif\x00\x00private-location")

    result = sanitize_report_photo(source.getvalue())

    cleaned = Image.open(BytesIO(result.bytes))
    assert cleaned.format == "JPEG"
    assert cleaned.size == (32, 24)
    assert cleaned.getexif() == {}
    assert result.content_type == "image/jpeg"

