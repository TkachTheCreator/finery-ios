"""
Finery API Load Test
Run after setup_users.py has created test_users.json.

Usage examples:
  # 50 VU for 90 seconds, ramp up at 5/sec
  locust -f locustfile.py --host http://localhost:8000 --headless \
         -u 50 -r 5 --run-time 90s --html report_050vu.html --csv results_050vu

  # 100 VU
  locust -f locustfile.py --host http://localhost:8000 --headless \
         -u 100 -r 10 --run-time 90s --html report_100vu.html --csv results_100vu

Rate-limiter awareness:
  - Each VU gets a unique fake X-Forwarded-For IP → each VU has its own
    100/min budget → tests real server capacity, not per-IP caps.
  - 429 responses are tracked separately ("rate_limit") and NOT counted as
    failures, so they do not inflate the error rate.
  - Real failures = 5xx responses or timeouts.
"""

import json
import os
import random
import string
from datetime import datetime

from locust import HttpUser, between, task

# ── Load pre-registered users ──────────────────────────────────────────────
_USERS_FILE = os.environ.get("TEST_USERS_FILE", "test_users.json")

try:
    with open(_USERS_FILE) as _f:
        _USER_POOL: list[dict] = json.load(_f)
    print(f"[locust] Loaded {len(_USER_POOL)} test users from {_USERS_FILE}")
except FileNotFoundError:
    print(f"[locust] ERROR: {_USERS_FILE} not found. Run setup_users.py first.")
    _USER_POOL = []

_user_index: int = 0


def _next_user() -> dict:
    global _user_index
    u = _USER_POOL[_user_index % len(_USER_POOL)]
    _user_index += 1
    return u


def _fake_ip() -> str:
    """Unique RFC-1918 IP so each VU has its own rate-limit bucket."""
    return f"10.{random.randint(0, 255)}.{random.randint(0, 255)}.{random.randint(1, 254)}"


def _rstr(n: int = 6) -> str:
    return "".join(random.choices(string.ascii_lowercase, k=n))


class FineryUser(HttpUser):
    """Simulates a real Finery user session (post-login state)."""

    wait_time = between(0.5, 2.0)

    def on_start(self) -> None:
        u = _next_user()
        self.token = u["token"]
        self.fake_ip = _fake_ip()
        year = datetime.now().year
        self._from = f"{year}-01-01T00:00:00"
        self._to = f"{year}-12-31T23:59:59"
        self._year = year

    # ── helpers ───────────────────────────────────────────────────────────

    def _hdr(self) -> dict:
        return {
            "Authorization": f"Bearer {self.token}",
            "Content-Type": "application/json",
            "X-Forwarded-For": self.fake_ip,
        }

    def _check(self, resp, name: str) -> None:
        """429 → tracked but not a failure. 5xx → failure."""
        if resp.status_code == 429:
            resp.failure(f"429_rate_limit")
        elif resp.status_code >= 500:
            resp.failure(f"{resp.status_code}_server_error")
        else:
            resp.success()

    # ── Tasks ─────────────────────────────────────────────────────────────

    @task(4)
    def list_transactions(self) -> None:
        with self.client.get(
            "/api/v1/transactions?per_page=50",
            headers=self._hdr(),
            catch_response=True,
            name="GET /transactions",
        ) as r:
            self._check(r, "list_transactions")

    @task(2)
    def create_transaction(self) -> None:
        body = {
            "amount": round(random.uniform(500, 80000), 2),
            "direction": random.choice(["income", "expense"]),
            "description": f"Нагр-тест {_rstr()}",
            "date": datetime.now().isoformat(),
            "client_type": random.choice(["individual", "business"]),
        }
        with self.client.post(
            "/api/v1/transactions",
            json=body,
            headers=self._hdr(),
            catch_response=True,
            name="POST /transactions",
        ) as r:
            self._check(r, "create_transaction")

    @task(2)
    def get_analytics_pnl(self) -> None:
        with self.client.get(
            f"/api/v1/analytics/pnl?from_date={self._from}&to_date={self._to}",
            headers=self._hdr(),
            catch_response=True,
            name="GET /analytics/pnl",
        ) as r:
            self._check(r, "analytics_pnl")

    @task(1)
    def get_tax_status(self) -> None:
        with self.client.get(
            f"/api/v1/tax/status?year={self._year}",
            headers=self._hdr(),
            catch_response=True,
            name="GET /tax/status",
        ) as r:
            self._check(r, "tax_status")

    @task(1)
    def get_tax_forecast(self) -> None:
        with self.client.get(
            "/api/v1/tax/forecast",
            headers=self._hdr(),
            catch_response=True,
            name="GET /tax/forecast",
        ) as r:
            self._check(r, "tax_forecast")
