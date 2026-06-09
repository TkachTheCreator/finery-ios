from decimal import Decimal
from collections import defaultdict

from app.services.tax import calculate_tax


def pnl(transactions: list[dict]) -> dict:
    income = Decimal("0")
    expenses = Decimal("0")
    tax = Decimal("0")

    for tx in transactions:
        amount = Decimal(str(tx["amount"]))
        if tx["direction"] == "income":
            income += amount
            tax += calculate_tax(amount, tx.get("client_type"))
        else:
            expenses += amount

    return {
        "total_income": income,
        "total_expenses": expenses,
        "tax_amount": tax,
        "net_profit": income - expenses - tax,
    }


def top_sources(transactions: list[dict], limit: int = 5) -> list[dict]:
    totals: dict[str, Decimal] = defaultdict(Decimal)
    for tx in transactions:
        if tx["direction"] == "income" and tx.get("income_category"):
            totals[tx["income_category"]] += Decimal(str(tx["amount"]))
    return [
        {"category": cat, "amount": amt}
        for cat, amt in sorted(totals.items(), key=lambda x: x[1], reverse=True)[:limit]
    ]


def monthly_dynamics(transactions: list[dict]) -> list[dict]:
    by_month: dict[str, dict] = defaultdict(lambda: {"income": Decimal("0"), "expense": Decimal("0"), "tax": Decimal("0")})
    for tx in transactions:
        key = tx["date"][:7]  # YYYY-MM
        amount = Decimal(str(tx["amount"]))
        if tx["direction"] == "income":
            by_month[key]["income"] += amount
            by_month[key]["tax"] += calculate_tax(amount, tx.get("client_type"))
        else:
            by_month[key]["expense"] += amount

    return [
        {
            "month": k,
            "income": v["income"],
            "expense": v["expense"],
            "tax": v["tax"],
            "net": v["income"] - v["expense"] - v["tax"],
        }
        for k, v in sorted(by_month.items())
    ]
