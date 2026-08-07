import json
from datetime import date, time

from openai import OpenAI
from pydantic import BaseModel, ValidationError

from app.core.config import get_settings

settings = get_settings()

EXTRACTION_SYSTEM_PROMPT = """You are a receipt-parsing engine. You will be \
given raw, possibly noisy OCR text from a shopping receipt. Extract structured \
data and return ONLY valid JSON matching this exact shape, nothing else:

{
  "store_name": string | null,
  "invoice_number": string | null,
  "purchase_date": "YYYY-MM-DD" | null,
  "purchase_time": "HH:MM" | null,
  "payment_method": "cash" | "card" | "upi" | "wallet" | "other" | null,
  "subtotal": number | null,
  "tax_amount": number | null,
  "discount_amount": number | null,
  "total_amount": number | null,
  "items": [
    {
      "raw_text": string,        // the original OCR line, unmodified
      "display_name": string,    // corrected, expanded product name (e.g. "Maggi 2pkt" -> "Maggi Noodles")
      "quantity": number,
      "unit": string | null,
      "mrp": number | null,
      "discount": number | null,
      "tax": number | null,
      "final_price": number,
      "confidence": number       // 0.0-1.0, your confidence in this line's extraction
    }
  ]
}

Rules:
- Correct obvious OCR typos and expand abbreviations in display_name (e.g. "Dairy Milk S" -> "Dairy Milk Silk").
- Merge duplicate line items that clearly refer to the same product and quantity split across lines.
- If a field genuinely cannot be determined, use null rather than guessing.
- final_price must always be a number; if not found, estimate from mrp/discount/tax or omit the item.
- Respond with JSON only. No markdown fences, no commentary.
"""


class ExtractedItem(BaseModel):
    raw_text: str
    display_name: str
    quantity: float = 1.0
    unit: str | None = None
    mrp: float | None = None
    discount: float | None = None
    tax: float | None = None
    final_price: float
    confidence: float = 0.5


class ExtractedReceipt(BaseModel):
    store_name: str | None = None
    invoice_number: str | None = None
    purchase_date: date | None = None
    purchase_time: time | None = None
    payment_method: str | None = None
    subtotal: float | None = None
    tax_amount: float | None = None
    discount_amount: float | None = None
    total_amount: float | None = None
    items: list[ExtractedItem] = []


class AiExtractionService:
    """Sends raw OCR text to GPT and parses the structured JSON response
    into an [ExtractedReceipt]. Isolated behind this class so the Celery
    task doesn't deal with prompt construction or malformed-response
    recovery directly.
    """

    def __init__(self):
        self._client: OpenAI | None = None

    def _get_client(self) -> OpenAI:
        if self._client is None:
            self._client = OpenAI(api_key=settings.OPENAI_API_KEY)
        return self._client

    def extract(self, raw_ocr_text: str) -> ExtractedReceipt:
        if not raw_ocr_text.strip():
            return ExtractedReceipt()

        client = self._get_client()
        response = client.chat.completions.create(
            model="gpt-4o-mini",
            temperature=0,
            response_format={"type": "json_object"},
            messages=[
                {"role": "system", "content": EXTRACTION_SYSTEM_PROMPT},
                {"role": "user", "content": raw_ocr_text},
            ],
        )
        content = response.choices[0].message.content or "{}"

        try:
            data = json.loads(content)
            return ExtractedReceipt.model_validate(data)
        except (json.JSONDecodeError, ValidationError) as exc:
            # Malformed model output shouldn't crash the pipeline — surface
            # an empty extraction so the receipt is flagged NEEDS_REVIEW
            # instead of FAILED, and the raw OCR text is still preserved.
            raise ExtractionParseError(str(exc)) from exc


class ExtractionParseError(Exception):
    pass
