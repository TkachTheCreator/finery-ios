from decimal import Decimal
from datetime import date

NPD_YEAR_LIMIT = Decimal("2400000")
NPD_RATE_INDIVIDUAL = Decimal("0.04")
NPD_RATE_BUSINESS = Decimal("0.06")


def npd_rate(client_type: str | None) -> Decimal:
    if client_type == "business":
        return NPD_RATE_BUSINESS
    return NPD_RATE_INDIVIDUAL


def calculate_tax(amount: Decimal, client_type: str | None) -> Decimal:
    return (amount * npd_rate(client_type)).quantize(Decimal("0.01"))


def calculate_tax_for_period(
    transactions: list[dict],
) -> dict:
    total_income = Decimal("0")
    total_tax = Decimal("0")

    for tx in transactions:
        if tx["direction"] != "income":
            continue
        amount = Decimal(str(tx["amount"]))
        tax = calculate_tax(amount, tx.get("client_type"))
        total_income += amount
        total_tax += tax

    limit_used_pct = (total_income / NPD_YEAR_LIMIT * 100).quantize(Decimal("0.01"))
    remaining = max(NPD_YEAR_LIMIT - total_income, Decimal("0"))
    next_deadline = _next_deadline()

    return {
        "total_income": total_income,
        "total_tax": total_tax,
        "limit_used_percent": limit_used_pct,
        "yearly_limit": NPD_YEAR_LIMIT,
        "remaining": remaining,
        "is_near_limit": limit_used_pct >= 80,
        "is_over_limit": total_income > NPD_YEAR_LIMIT,
        "next_deadline": next_deadline.isoformat(),
        "days_until_deadline": (next_deadline - date.today()).days,
    }


def _next_deadline() -> date:
    today = date.today()
    deadline = date(today.year, today.month, 28)
    if today > deadline:
        month = today.month % 12 + 1
        year = today.year + (1 if month == 1 else 0)
        deadline = date(year, month, 28)
    return deadline
