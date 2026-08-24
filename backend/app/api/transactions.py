import math
import uuid
from datetime import datetime

from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy import and_, func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.auth import current_user
from app.core.database import get_db
from app.models.client import Client
from app.models.transaction import Transaction
from app.models.user import User
from app.schemas.transaction import TransactionCreate, TransactionOut, TransactionUpdate
from app.services.classifier import classify

router = APIRouter(prefix="/transactions", tags=["transactions"])


@router.post("", response_model=TransactionOut, status_code=201)
async def create(
    body: TransactionCreate,
    user: User = Depends(current_user),
    db: AsyncSession = Depends(get_db),
):
    if body.client_id is not None:
        client_result = await db.execute(
            select(Client).where(and_(Client.id == body.client_id, Client.user_id == user.id))
        )
        if not client_result.scalar_one_or_none():
            raise HTTPException(status_code=404, detail="Client not found")

    if body.direction == "income" and not body.income_category:
        body = body.model_copy(update={"income_category": classify(body.description, "income")})
    if body.direction == "expense" and not body.expense_category:
        body = body.model_copy(update={"expense_category": classify(body.description, "expense")})

    tx = Transaction(user_id=user.id, **body.model_dump())
    db.add(tx)
    await db.flush()
    await db.refresh(tx)
    return tx


@router.get("")
async def list_transactions(
    from_date: datetime | None = Query(None),
    to_date: datetime | None = Query(None),
    direction: str | None = Query(None),
    page: int = Query(1, ge=1),
    per_page: int = Query(50, ge=1, le=500),
    user: User = Depends(current_user),
    db: AsyncSession = Depends(get_db),
):
    filters = [Transaction.user_id == user.id]
    if from_date:
        filters.append(Transaction.date >= from_date)
    if to_date:
        filters.append(Transaction.date <= to_date)
    if direction:
        filters.append(Transaction.direction == direction)

    count_result = await db.execute(
        select(func.count()).select_from(Transaction).where(and_(*filters))
    )
    total = count_result.scalar_one()

    offset = (page - 1) * per_page
    result = await db.execute(
        select(Transaction)
        .where(and_(*filters))
        .order_by(Transaction.date.desc())
        .limit(per_page)
        .offset(offset)
    )
    items = result.scalars().all()

    return {
        "items": [TransactionOut.model_validate(tx) for tx in items],
        "total": total,
        "page": page,
        "pages": max(1, math.ceil(total / per_page)),
    }


@router.get("/{tx_id}", response_model=TransactionOut)
async def get(tx_id: uuid.UUID, user: User = Depends(current_user), db: AsyncSession = Depends(get_db)):
    return await _get_or_404(tx_id, user.id, db)


@router.patch("/{tx_id}", response_model=TransactionOut)
async def update(
    tx_id: uuid.UUID,
    body: TransactionUpdate,
    user: User = Depends(current_user),
    db: AsyncSession = Depends(get_db),
):
    tx = await _get_or_404(tx_id, user.id, db)
    for field, value in body.model_dump(exclude_none=True).items():
        setattr(tx, field, value)
    await db.flush()
    await db.refresh(tx)
    return tx


@router.delete("/{tx_id}", status_code=204)
async def delete(tx_id: uuid.UUID, user: User = Depends(current_user), db: AsyncSession = Depends(get_db)):
    tx = await _get_or_404(tx_id, user.id, db)
    await db.delete(tx)


async def _get_or_404(tx_id: uuid.UUID, user_id: uuid.UUID, db: AsyncSession) -> Transaction:
    result = await db.execute(
        select(Transaction).where(Transaction.id == tx_id, Transaction.user_id == user_id)
    )
    tx = result.scalar_one_or_none()
    if not tx:
        raise HTTPException(status_code=404, detail="Transaction not found")
    return tx
