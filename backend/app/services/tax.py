from decimal import Decimal
from datetime import date

NPD_YEAR_LIMIT = Decimal("2400000")
NPD_RATE_INDIVIDUAL = Decimal("0.04")
NPD_RATE_BUSINESS = Decimal("0.06")
USN6_RATE = Decimal("0.06")
USN15_RATE = Decimal("0.15")


def npd_rate(client_type: str | None) -> Decimal:
    return NPD_RATE_BUSINESS if client_type == "business" else NPD_RATE_INDIVIDUAL


def calculate_tax_npd(amount: Decimal, client_type: str | None) -> Decimal:
    return (amount * npd_rate(client_type)).quantize(Decimal("0.01"))


# Legacy alias used by analytics service
def calculate_tax(amount: Decimal, client_type: str | None) -> Decimal:
    return calculate_tax_npd(amount, client_type)


def calculate_tax_for_period(transactions: list[dict], tax_mode: str = "npd") -> dict:
    total_income = Decimal("0")
    total_expense = Decimal("0")

    for tx in transactions:
        amount = Decimal(str(tx["amount"]))
        if tx["direction"] == "income":
            total_income += amount
        else:
            total_expense += amount

    if tax_mode == "npd":
        total_tax = sum(
            calculate_tax_npd(Decimal(str(tx["amount"])), tx.get("client_type"))
            for tx in transactions
            if tx["direction"] == "income"
        )
        yearly_limit = NPD_YEAR_LIMIT
        limit_used_pct = (total_income / NPD_YEAR_LIMIT * 100).quantize(Decimal("0.01"))
        remaining = max(NPD_YEAR_LIMIT - total_income, Decimal("0"))
        is_near_limit = limit_used_pct >= 80
        is_over_limit = total_income > NPD_YEAR_LIMIT

    elif tax_mode == "usn6":
        total_tax = (total_income * USN6_RATE).quantize(Decimal("0.01"))
        yearly_limit = Decimal("0")
        limit_used_pct = Decimal("0")
        remaining = Decimal("0")
        is_near_limit = False
        is_over_limit = False

    elif tax_mode == "usn15":
        profit = max(Decimal("0"), total_income - total_expense)
        total_tax = (profit * USN15_RATE).quantize(Decimal("0.01"))
        yearly_limit = Decimal("0")
        limit_used_pct = Decimal("0")
        remaining = Decimal("0")
        is_near_limit = False
        is_over_limit = False

    else:  # patent, none, other → no automatic tax
        total_tax = Decimal("0")
        yearly_limit = Decimal("0")
        limit_used_pct = Decimal("0")
        remaining = Decimal("0")
        is_near_limit = False
        is_over_limit = False

    next_deadline = _next_deadline()
    return {
        "total_income": total_income,
        "total_tax": total_tax,
        "limit_used_percent": limit_used_pct,
        "yearly_limit": yearly_limit,
        "remaining": remaining,
        "is_near_limit": is_near_limit,
        "is_over_limit": is_over_limit,
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
