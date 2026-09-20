from __future__ import annotations

from dataclasses import dataclass
from io import BytesIO
import socket
import struct

from PIL import Image, ImageOps, UnidentifiedImageError

from ..config import Settings


MAX_SOURCE_BYTES = 10 * 1024 * 1024
MAX_IMAGE_PIXELS = 24_000_000
Image.MAX_IMAGE_PIXELS = MAX_IMAGE_PIXELS


class InvalidReportPhoto(ValueError):
    pass


@dataclass(frozen=True)
class SanitizedPhoto:
    bytes: bytes
    content_type: str = "image/jpeg"


def sanitize_report_photo(source: bytes) -> SanitizedPhoto:
    """Decode and re-encode a report photo, dropping EXIF and other metadata."""
    if not source or len(source) > MAX_SOURCE_BYTES:
        raise InvalidReportPhoto("Photo must be between 1 byte and 10 MB.")
    try:
        with Image.open(BytesIO(source)) as original:
            original.verify()
        with Image.open(BytesIO(source)) as original:
            cleaned = ImageOps.exif_transpose(original).convert("RGB")
            cleaned.thumbnail((4096, 4096))
            destination = BytesIO()
            cleaned.save(destination, format="JPEG", quality=88, optimize=True)
    except (UnidentifiedImageError, OSError, ValueError) as exc:
        raise InvalidReportPhoto("The file is not a valid supported image.") from exc
    return SanitizedPhoto(destination.getvalue())


def scan_report_photo(source: bytes, settings: Settings) -> None:
    """Stream the original file to ClamAV. Production fails closed."""
    if not settings.clamav_host:
        if settings.app_env == "production":
            raise RuntimeError("ClamAV is required for production photo uploads.")
        return
    try:
        with socket.create_connection(
            (settings.clamav_host, settings.clamav_port), timeout=10
        ) as connection:
            connection.sendall(b"zINSTREAM\0")
            for offset in range(0, len(source), 64 * 1024):
                chunk = source[offset : offset + 64 * 1024]
                connection.sendall(struct.pack("!I", len(chunk)))
                connection.sendall(chunk)
            connection.sendall(struct.pack("!I", 0))
            response = connection.recv(4096).decode(errors="replace")
    except OSError as exc:
        raise RuntimeError("Photo malware scanner is unavailable.") from exc
    if "FOUND" in response:
        raise InvalidReportPhoto("The photo did not pass the security scan.")
    if "OK" not in response:
        raise RuntimeError("Photo malware scan returned an unknown result.")
