from collections import defaultdict
from datetime import datetime
from decimal import Decimal

from fastapi import APIRouter, Depends, Query
from sqlalchemy import select, and_
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.auth import current_user
from app.core.database import get_db
from app.models.transaction import Transaction
from app.models.user import User
from app.services import analytics as svc

router = APIRouter(prefix="/analytics", tags=["analytics"])

_MONTH_LABELS = [
    "", "Январь", "Февраль", "Март", "Апрель", "Май", "Июнь",
    "Июль", "Август", "Сентябрь", "Октябрь", "Ноябрь", "Декабрь",
]


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
    year: int = Query(..., ge=2020, le=2100),
    user: User = Depends(current_user),
    db: AsyncSession = Depends(get_db),
):
    from_date = datetime(year, 1, 1)
    to_date = datetime(year, 12, 31, 23, 59, 59)
    rows = await _fetch(user.id, from_date, to_date, db)
    return svc.monthly_dynamics(_tx_dicts(rows), tax_mode=user.tax_mode)


@router.get("/seasonal")
async def seasonal(
    user: User = Depends(current_user),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(
        select(Transaction).where(Transaction.user_id == user.id)
    )
    rows = result.scalars().all()

    # Group by year+month
    by_ym: dict[int, dict[int, dict]] = defaultdict(lambda: defaultdict(lambda: {"income": Decimal("0"), "expense": Decimal("0")}))
    for tx in rows:
        y, m = tx.date.year, tx.date.month
        if tx.direction == "income":
            by_ym[y][m]["income"] += tx.amount
        else:
            by_ym[y][m]["expense"] += tx.amount

    monthly_averages = []
    for month in range(1, 13):
        incomes  = [by_ym[y][month]["income"]  for y in by_ym if month in by_ym[y]]
        expenses = [by_ym[y][month]["expense"] for y in by_ym if month in by_ym[y]]
        avg_i = (sum(incomes)  / len(incomes))  if incomes  else Decimal("0")
        avg_e = (sum(expenses) / len(expenses)) if expenses else Decimal("0")
        monthly_averages.append({"month": month, "label": _MONTH_LABELS[month], "avg_income": avg_i, "avg_expense": avg_e})

    overall_avg = sum(m["avg_income"] for m in monthly_averages) / 12 if monthly_averages else Decimal("0")

    best  = max(monthly_averages, key=lambda x: x["avg_income"])
    worst = min(monthly_averages, key=lambda x: x["avg_income"])

    def pct(val): return int((val - overall_avg) / overall_avg * 100) if overall_avg > 0 else 0

    now = datetime.utcnow()
    cur = monthly_averages[now.month - 1]
    diff = pct(cur["avg_income"])
    direction = "выше" if diff >= 0 else "ниже"
    insight = f"{_MONTH_LABELS[now.month]} исторически {direction} среднего на {abs(diff)}%"

    return {
        "monthly_averages": monthly_averages,
        "best_month":  {"month": best["month"],  "label": best["label"],  "diff_pct": pct(best["avg_income"])},
        "worst_month": {"month": worst["month"], "label": worst["label"], "diff_pct": pct(worst["avg_income"])},
        "current_month_insight": insight,
    }


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
