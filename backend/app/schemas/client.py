import uuid
from datetime import datetime
from decimal import Decimal
from typing import Literal

from pydantic import BaseModel

ClientStatusLiteral = Literal["active", "completed"]


class ClientCreate(BaseModel):
    name: str
    email: str | None = None
    phone: str | None = None
    status: ClientStatusLiteral = "active"
    notes: str | None = None


class ClientUpdate(BaseModel):
    name: str | None = None
    email: str | None = None
    phone: str | None = None
    total_paid: Decimal | None = None
    last_payment: datetime | None = None
    status: ClientStatusLiteral | None = None
    notes: str | None = None


class ClientOut(BaseModel):
    id: uuid.UUID
    user_id: uuid.UUID
    name: str
    email: str | None
    phone: str | None
    total_paid: Decimal
    last_payment: datetime | None
    status: str
    notes: str | None
    created_at: datetime

    model_config = {"from_attributes": True}
