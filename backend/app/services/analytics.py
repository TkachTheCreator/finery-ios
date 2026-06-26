from decimal import Decimal
from collections import defaultdict

from app.services.tax import calculate_tax_npd, USN6_RATE, USN15_RATE


def pnl(transactions: list[dict], tax_mode: str = "npd") -> dict:
    income = Decimal("0")
    expenses = Decimal("0")

    for tx in transactions:
        amount = Decimal(str(tx["amount"]))
        if tx["direction"] == "income":
            income += amount
        else:
            expenses += amount

    if tax_mode == "npd":
        tax = sum(
            calculate_tax_npd(Decimal(str(tx["amount"])), tx.get("client_type"))
            for tx in transactions
            if tx["direction"] == "income"
        )
    elif tax_mode == "usn6":
        tax = (income * USN6_RATE).quantize(Decimal("0.01"))
    elif tax_mode == "usn15":
        profit = max(Decimal("0"), income - expenses)
        tax = (profit * USN15_RATE).quantize(Decimal("0.01"))
    else:
        tax = Decimal("0")

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


def monthly_dynamics(transactions: list[dict], tax_mode: str = "npd") -> list[dict]:
    by_month: dict[str, dict] = defaultdict(
        lambda: {"income": Decimal("0"), "expense": Decimal("0"), "tax": Decimal("0")}
    )
    for tx in transactions:
        key = tx["date"][:7]  # YYYY-MM
        amount = Decimal(str(tx["amount"]))
        if tx["direction"] == "income":
            by_month[key]["income"] += amount
            if tax_mode == "npd":
                by_month[key]["tax"] += calculate_tax_npd(amount, tx.get("client_type"))
        else:
            by_month[key]["expense"] += amount

    # For USN modes, apply rate to monthly totals after accumulation
    result = []
    for k in sorted(by_month):
        m = by_month[k]
        if tax_mode == "usn6":
            m["tax"] = (m["income"] * USN6_RATE).quantize(Decimal("0.01"))
        elif tax_mode == "usn15":
            profit = max(Decimal("0"), m["income"] - m["expense"])
            m["tax"] = (profit * USN15_RATE).quantize(Decimal("0.01"))
        result.append({
            "month": k,
            "income": m["income"],
            "expense": m["expense"],
            "tax": m["tax"],
            "net": m["income"] - m["expense"] - m["tax"],
        })
    return result
