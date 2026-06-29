from datetime import datetime, timedelta
from decimal import Decimal

from fastapi import APIRouter, Depends, Query
from sqlalchemy import select, and_, extract, func
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.auth import current_user
from app.core.database import get_db
from app.models.transaction import Transaction
from app.models.user import User
from app.services.tax import calculate_tax_for_period, calculate_tax_npd

router = APIRouter(prefix="/tax", tags=["tax"])

NPD_LIMIT = Decimal("2400000")


@router.get("/status")
async def tax_status(
    year: int = Query(...),
    user: User = Depends(current_user),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(
        select(Transaction).where(
            and_(
                Transaction.user_id == user.id,
                extract("year", Transaction.date) == year,
            )
        )
    )
    rows = result.scalars().all()
    tx_dicts = [
        {"amount": str(tx.amount), "direction": tx.direction, "client_type": tx.client_type}
        for tx in rows
    ]
    return calculate_tax_for_period(tx_dicts, tax_mode=user.tax_mode)


@router.get("/calculate")
async def calculate(
    amount: float = Query(...),
    client_type: str = Query("individual"),
):
    amt = Decimal(str(amount))
    tax = calculate_tax_npd(amt, client_type)
    return {
        "amount": amt,
        "client_type": client_type,
        "tax": tax,
        "rate": "4%" if client_type != "business" else "6%",
        "net": amt - tax,
    }


@router.get("/forecast")
async def tax_forecast(
    user: User = Depends(current_user),
    db: AsyncSession = Depends(get_db),
):
    now = datetime.utcnow()
    year_start = datetime(now.year, 1, 1)
    thirty_days_ago = now - timedelta(days=30)

    ytd_result = await db.execute(
        select(func.sum(Transaction.amount)).where(
            and_(
                Transaction.user_id == user.id,
                Transaction.direction == "income",
                Transaction.date >= year_start,
            )
        )
    )
    ytd_income = ytd_result.scalar() or Decimal("0")

    recent_result = await db.execute(
        select(func.sum(Transaction.amount)).where(
            and_(
                Transaction.user_id == user.id,
                Transaction.direction == "income",
                Transaction.date >= thirty_days_ago,
            )
        )
    )
    recent_income = recent_result.scalar() or Decimal("0")

    daily_avg = (recent_income / 30).quantize(Decimal("0.01"))
    remaining = max(Decimal("0"), NPD_LIMIT - ytd_income)

    days_to_limit = None
    limit_date = None
    if daily_avg > 0:
        days_to_limit = int(remaining / daily_avg)
        limit_date = (now + timedelta(days=days_to_limit)).date().isoformat()

    recommendation = None
    if days_to_limit is not None and days_to_limit < 60:
        recommendation = "Рассмотрите переход на УСН 6%"

    annual_tax_forecast = (daily_avg * 365 * Decimal("0.05")).quantize(Decimal("1"))

    return {
        "daily_avg": daily_avg,
        "days_to_limit": days_to_limit,
        "limit_date": limit_date,
        "recommendation": recommendation,
        "annual_tax_forecast": annual_tax_forecast,
        "ytd_income": ytd_income,
        "remaining": remaining,
    }
