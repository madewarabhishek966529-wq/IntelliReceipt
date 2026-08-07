from google.cloud import vision

from app.core.config import get_settings

settings = get_settings()


class OcrService:
    """Wraps Google Cloud Vision's document text detection. Kept as a
    separate service (rather than inlined in the Celery task) so it can be
    swapped for another OCR provider, or mocked in tests, without touching
    the extraction pipeline.
    """

    def __init__(self):
        self._client: vision.ImageAnnotatorClient | None = None

    def _get_client(self) -> vision.ImageAnnotatorClient:
        if self._client is None:
            if settings.GOOGLE_VISION_CREDENTIALS_PATH:
                self._client = vision.ImageAnnotatorClient.from_service_account_file(
                    settings.GOOGLE_VISION_CREDENTIALS_PATH
                )
            else:
                # Falls back to Application Default Credentials if configured
                # in the environment (e.g. GOOGLE_APPLICATION_CREDENTIALS).
                self._client = vision.ImageAnnotatorClient()
        return self._client

    def extract_text(self, image_bytes: bytes) -> str:
        """Runs document text detection (better suited to receipts than
        plain text detection, since it preserves reading order/blocks).
        Returns an empty string if nothing was detected.
        """
        client = self._get_client()
        image = vision.Image(content=image_bytes)
        response = client.document_text_detection(image=image)

        if response.error.message:
            raise RuntimeError(f"Vision API error: {response.error.message}")

        return response.full_text_annotation.text if response.full_text_annotation else ""
