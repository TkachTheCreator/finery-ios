from datetime import datetime

from fastapi import APIRouter, Depends, Query
from sqlalchemy import select, and_, extract
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.auth import current_user
from app.core.database import get_db
from app.models.transaction import Transaction
from app.models.user import User
from app.services.tax import calculate_tax_for_period

router = APIRouter(prefix="/tax", tags=["tax"])


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
    return calculate_tax_for_period(tx_dicts)


@router.get("/calculate")
async def calculate(
    amount: float = Query(...),
    client_type: str = Query("individual"),
):
    from decimal import Decimal
    from app.services.tax import calculate_tax
    amt = Decimal(str(amount))
    tax = calculate_tax(amt, client_type)
    return {
        "amount": amt,
        "client_type": client_type,
        "tax": tax,
        "rate": "4%" if client_type != "business" else "6%",
        "net": amt - tax,
    }
