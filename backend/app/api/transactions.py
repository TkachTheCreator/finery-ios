import uuid
from datetime import datetime

from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy import select, and_
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.auth import current_user
from app.core.database import get_db
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
    # Auto-classify if category not provided
    if body.direction == "income" and not body.income_category:
        body = body.model_copy(update={"income_category": classify(body.description, "income")})
    if body.direction == "expense" and not body.expense_category:
        body = body.model_copy(update={"expense_category": classify(body.description, "expense")})

    tx = Transaction(user_id=user.id, **body.model_dump())
    db.add(tx)
    await db.flush()
    await db.refresh(tx)
    return tx


@router.get("", response_model=list[TransactionOut])
async def list_transactions(
    from_date: datetime | None = Query(None),
    to_date: datetime | None = Query(None),
    direction: str | None = Query(None),
    limit: int = Query(100, le=500),
    offset: int = Query(0),
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

    result = await db.execute(
        select(Transaction)
        .where(and_(*filters))
        .order_by(Transaction.date.desc())
        .limit(limit)
        .offset(offset)
    )
    return result.scalars().all()


@router.get("/{tx_id}", response_model=TransactionOut)
async def get(tx_id: uuid.UUID, user: User = Depends(current_user), db: AsyncSession = Depends(get_db)):
    tx = await _get_or_404(tx_id, user.id, db)
    return tx


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
