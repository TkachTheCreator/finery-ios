from datetime import datetime

from fastapi import APIRouter, Depends, Query
from sqlalchemy import select, and_
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.auth import current_user
from app.core.database import get_db
from app.models.transaction import Transaction
from app.models.user import User
from app.services import analytics as svc

router = APIRouter(prefix="/analytics", tags=["analytics"])


def _tx_dicts(rows) -> list[dict]:
    return [
        {
            "amount": str(tx.amount),
            "direction": tx.direction,
            "client_type": tx.client_type,
            "income_category": tx.income_category,
            "date": tx.date.isoformat(),
        }
        for tx in rows
    ]


@router.get("/pnl")
async def pnl(
    from_date: datetime = Query(...),
    to_date: datetime = Query(...),
    user: User = Depends(current_user),
    db: AsyncSession = Depends(get_db),
):
    rows = await _fetch(user.id, from_date, to_date, db)
    return svc.pnl(_tx_dicts(rows), tax_mode=user.tax_mode)


@router.get("/top-sources")
async def top_sources(
    from_date: datetime = Query(...),
    to_date: datetime = Query(...),
    limit: int = Query(5, le=20),
    user: User = Depends(current_user),
    db: AsyncSession = Depends(get_db),
):
    rows = await _fetch(user.id, from_date, to_date, db)
    return svc.top_sources(_tx_dicts(rows), limit)


@router.get("/monthly")
async def monthly(
    year: int = Query(...),
    user: User = Depends(current_user),
    db: AsyncSession = Depends(get_db),
):
    from_date = datetime(year, 1, 1)
    to_date = datetime(year, 12, 31, 23, 59, 59)
    rows = await _fetch(user.id, from_date, to_date, db)
    return svc.monthly_dynamics(_tx_dicts(rows), tax_mode=user.tax_mode)


async def _fetch(user_id, from_date, to_date, db: AsyncSession):
    result = await db.execute(
        select(Transaction).where(
            and_(
                Transaction.user_id == user_id,
                Transaction.date >= from_date,
                Transaction.date <= to_date,
            )
        )
    )
    return result.scalars().all()
