import uuid
from datetime import datetime
from decimal import Decimal
from typing import Literal

from pydantic import BaseModel, Field, field_validator


class TransactionCreate(BaseModel):
    amount: Decimal
    direction: Literal["income", "expense"]
    description: str = Field("", max_length=500)
    date: datetime
    source: str = "manual"
    income_category: str | None = None
    expense_category: str | None = None
    client_type: Literal["individual", "business"] | None = None
    notes: str | None = Field(None, max_length=500)
    client_id: uuid.UUID | None = None

    @field_validator("amount")
    @classmethod
    def validate_amount(cls, v: Decimal) -> Decimal:
        if v <= 0:
            raise ValueError("amount must be positive")
        return v


class TransactionUpdate(BaseModel):
    amount: Decimal | None = None
    direction: Literal["income", "expense"] | None = None
    description: str | None = Field(None, max_length=500)
    date: datetime | None = None
    source: str | None = None
    income_category: str | None = None
    expense_category: str | None = None
    client_type: Literal["individual", "business"] | None = None
    client_id: uuid.UUID | None = None
    notes: str | None = Field(None, max_length=500)


class TransactionOut(BaseModel):
    id: uuid.UUID
    user_id: uuid.UUID
    amount: Decimal
    direction: str
    description: str
    date: datetime
    source: str
    income_category: str | None
    expense_category: str | None
    client_type: str | None
    notes: str | None
    client_id: uuid.UUID | None
    created_at: datetime

    model_config = {"from_attributes": True}
