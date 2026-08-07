import json
from unittest.mock import MagicMock, patch

import pytest

from app.services.ai_extraction_service import (
    AiExtractionService,
    ExtractedReceipt,
    ExtractionParseError,
)


def _mock_openai_response(content: str):
    mock_response = MagicMock()
    mock_response.choices = [MagicMock(message=MagicMock(content=content))]
    return mock_response


def test_extract_returns_empty_receipt_for_blank_input():
    service = AiExtractionService()
    result = service.extract("   ")
    assert result == ExtractedReceipt()


def test_extract_parses_well_formed_json():
    payload = {
        "store_name": "Dmart",
        "invoice_number": "INV-123",
        "purchase_date": "2026-08-01",
        "purchase_time": "14:30",
        "payment_method": "upi",
        "subtotal": 100.0,
        "tax_amount": 5.0,
        "discount_amount": 0.0,
        "total_amount": 105.0,
        "items": [
            {
                "raw_text": "Maggi 2pkt",
                "display_name": "Maggi Noodles",
                "quantity": 2,
                "unit": None,
                "mrp": 14.0,
                "discount": 0.0,
                "tax": 0.5,
                "final_price": 28.0,
                "confidence": 0.92,
            }
        ],
    }

    service = AiExtractionService()
    with patch.object(service, "_get_client") as mock_get_client:
        mock_client = MagicMock()
        mock_client.chat.completions.create.return_value = _mock_openai_response(
            json.dumps(payload)
        )
        mock_get_client.return_value = mock_client

        result = service.extract("raw ocr text here")

    assert result.store_name == "Dmart"
    assert result.invoice_number == "INV-123"
    assert result.total_amount == 105.0
    assert len(result.items) == 1
    assert result.items[0].display_name == "Maggi Noodles"
    assert result.items[0].confidence == 0.92


def test_extract_raises_parse_error_on_malformed_json():
    service = AiExtractionService()
    with patch.object(service, "_get_client") as mock_get_client:
        mock_client = MagicMock()
        mock_client.chat.completions.create.return_value = _mock_openai_response(
            "not valid json at all {"
        )
        mock_get_client.return_value = mock_client

        with pytest.raises(ExtractionParseError):
            service.extract("raw ocr text here")


def test_extract_raises_parse_error_on_schema_mismatch():
    service = AiExtractionService()
    with patch.object(service, "_get_client") as mock_get_client:
        mock_client = MagicMock()
        # final_price is required on each item; omitting it should fail validation.
        bad_payload = {"items": [{"raw_text": "x", "display_name": "x", "quantity": 1}]}
        mock_client.chat.completions.create.return_value = _mock_openai_response(
            json.dumps(bad_payload)
        )
        mock_get_client.return_value = mock_client

        with pytest.raises(ExtractionParseError):
            service.extract("raw ocr text here")
