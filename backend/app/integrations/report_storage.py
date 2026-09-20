from __future__ import annotations

from pathlib import Path

import boto3

from ..config import Settings


class ReportPhotoStorage:
    def __init__(self, settings: Settings) -> None:
        self._settings = settings

    def put(self, *, object_name: str, data: bytes, content_type: str) -> str:
        if self._settings.object_storage_bucket:
            client = boto3.client(
                "s3",
                endpoint_url=self._settings.object_storage_endpoint,
                region_name=self._settings.object_storage_region,
                aws_access_key_id=self._settings.object_storage_access_key,
                aws_secret_access_key=self._settings.object_storage_secret_key,
            )
            client.put_object(
                Bucket=self._settings.object_storage_bucket,
                Key=object_name,
                Body=data,
                ContentType=content_type,
                ServerSideEncryption="AES256",
            )
            return f"oci://{self._settings.object_storage_bucket}/{object_name}"

        if self._settings.app_env != "development":
            raise RuntimeError("Private object storage is required outside development.")
        destination = Path(self._settings.local_upload_dir).resolve() / object_name
        destination.parent.mkdir(parents=True, exist_ok=True)
        destination.write_bytes(data)
        return f"local://{object_name}"
