import uuid

import httpx

from app.core.config import get_settings

settings = get_settings()


class StorageService:
    """Thin wrapper around Supabase Storage's REST upload API. Swap the
    implementation (e.g. for Firebase Storage) without touching callers,
    since they only depend on `upload_receipt_image`.
    """

    def __init__(self):
        self.base_url = settings.SUPABASE_URL.rstrip("/")
        self.service_key = settings.SUPABASE_SERVICE_KEY
        self.bucket = settings.STORAGE_BUCKET

    async def upload_receipt_image(
        self, user_id: str, file_bytes: bytes, content_type: str, original_filename: str
    ) -> str:
        ext = original_filename.rsplit(".", 1)[-1] if "." in original_filename else "jpg"
        object_path = f"{user_id}/{uuid.uuid4()}.{ext}"

        if not self.base_url or not self.service_key:
            # No storage configured (e.g. local dev without Supabase set up).
            # Returning a placeholder keeps the upload endpoint testable;
            # replace with a hard failure once storage is required.
            return f"local://unconfigured-storage/{object_path}"

        url = f"{self.base_url}/storage/v1/object/{self.bucket}/{object_path}"
        headers = {
            "Authorization": f"Bearer {self.service_key}",
            "Content-Type": content_type,
            "x-upsert": "true",
        }
        async with httpx.AsyncClient(timeout=30.0) as client:
            response = await client.post(url, headers=headers, content=file_bytes)
            response.raise_for_status()

        return f"{self.base_url}/storage/v1/object/public/{self.bucket}/{object_path}"
