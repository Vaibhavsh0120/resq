from __future__ import annotations

from pathlib import Path
from urllib.parse import unquote, urlparse

import cloudinary
import cloudinary.uploader
import httpx

from ..config import Settings


class ReportPhotoStorage:
    def __init__(self, settings: Settings) -> None:
        self._settings = settings
        if settings.cloudinary_url:
            parsed = urlparse(settings.cloudinary_url)
            if parsed.scheme != "cloudinary" or not all((parsed.hostname, parsed.username, parsed.password)):
                raise RuntimeError("Invalid Cloudinary configuration.")
            cloudinary.config(
                cloud_name=parsed.hostname,
                api_key=unquote(parsed.username),
                api_secret=unquote(parsed.password),
                secure=True,
            )

    def put(self, *, object_name: str, data: bytes, content_type: str) -> dict[str, str]:
        if self._settings.cloudinary_url:
            result = cloudinary.uploader.upload(
                data,
                public_id=object_name.removesuffix(".jpg"),
                resource_type="image",
                type="authenticated",
                overwrite=False,
            )
            return {"publicId": result["public_id"], "assetId": result["asset_id"]}

        if self._settings.app_env != "development":
            raise RuntimeError("Cloudinary private storage is required outside development.")
        destination = Path(self._settings.local_upload_dir).resolve() / object_name
        destination.parent.mkdir(parents=True, exist_ok=True)
        destination.write_bytes(data)
        return {"publicId": f"local://{object_name}", "assetId": ""}

    def delete(self, public_id: str) -> None:
        if public_id.startswith("local://"):
            (Path(self._settings.local_upload_dir).resolve() / public_id.removeprefix("local://")).unlink(missing_ok=True)
            return
        if not self._settings.cloudinary_url:
            raise RuntimeError("Cloudinary is not configured.")
        result = cloudinary.uploader.destroy(
            public_id, type="authenticated", resource_type="image", invalidate=True
        )
        if result.get("result") not in {"ok", "not found"}:
            raise RuntimeError("Cloudinary deletion was not confirmed.")

    def read(self, public_id: str) -> bytes:
        if public_id.startswith("local://"):
            return (Path(self._settings.local_upload_dir).resolve() / public_id.removeprefix("local://")).read_bytes()
        if not self._settings.cloudinary_url:
            raise RuntimeError("Cloudinary is not configured.")
        url = cloudinary.CloudinaryImage(public_id).build_url(
            type="authenticated", sign_url=True, secure=True
        )
        response = httpx.get(url, timeout=20)
        response.raise_for_status()
        if len(response.content) > 20 * 1024 * 1024:
            raise RuntimeError("Stored photo exceeds scanner limit.")
        return response.content
