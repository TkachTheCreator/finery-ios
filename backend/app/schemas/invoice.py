import json
import uuid
from datetime import datetime
from decimal import Decimal

from pydantic import BaseModel, model_validator


class InvoiceItem(BaseModel):
    name: str
    amount: Decimal


class InvoiceCreate(BaseModel):
    number: str
    date: datetime
    client_id: uuid.UUID | None = None
    client_name: str = ""
    items: list[InvoiceItem] = []
    include_vat: bool = False
    executor_name: str = ""
    total: Decimal = Decimal("0")


class InvoiceOut(BaseModel):
    id: uuid.UUID
    user_id: uuid.UUID
    number: str
    date: datetime
    client_id: uuid.UUID | None
    client_name: str
    items: list[InvoiceItem]
    include_vat: bool
    executor_name: str
    total: Decimal
    created_at: datetime

    model_config = {"from_attributes": True}

    @model_validator(mode="before")
    @classmethod
    def parse_items(cls, data):
        if hasattr(data, "items_json"):
            try:
                raw = json.loads(data.items_json or "[]")
                object.__setattr__(data, "items", raw)
            except Exception:
                pass
        return data
