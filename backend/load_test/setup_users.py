"""
Finery Load Test — User Setup
Registers test users and collects JWT tokens before the locust run.

Usage:
    python setup_users.py --count 120 --base-url http://localhost:8000

Each user gets a unique fake X-Forwarded-For IP so the rate limiter
(5/min per IP on /auth/register) never triggers.

Output: test_users.json — read by locustfile.py during the test.
Cleanup: DELETE FROM users WHERE email LIKE 'loadtest_%@loadtest.finery.pro'
"""

import argparse
import json
import random
import string
import time
import sys

import requests


def _rstr(n: int = 10) -> str:
    return "".join(random.choices(string.ascii_lowercase + string.digits, k=n))


def _fake_ip() -> str:
    return f"10.{random.randint(0,255)}.{random.randint(0,255)}.{random.randint(1,254)}"


def _register(base_url: str, email: str, password: str, name: str, ip: str) -> str | None:
    try:
        r = requests.post(
            f"{base_url}/api/v1/auth/register",
            json={"email": email, "password": password, "name": name,
                  "tax_mode": "npd", "user_type": "freelancer"},
            headers={"Content-Type": "application/json", "X-Forwarded-For": ip},
            timeout=15,
        )
        if r.status_code == 201:
            return r.json()["access_token"]
        if r.status_code == 409:
            return None  # already exists — will login
        print(f"  register error {r.status_code}: {r.text[:120]}", file=sys.stderr)
        return None
    except Exception as e:
        print(f"  register exception: {e}", file=sys.stderr)
        return None


def _login(base_url: str, email: str, password: str, ip: str) -> str | None:
    try:
        r = requests.post(
            f"{base_url}/api/v1/auth/login",
            json={"email": email, "password": password},
            headers={"Content-Type": "application/json", "X-Forwarded-For": ip},
            timeout=15,
        )
        if r.status_code == 200:
            return r.json()["access_token"]
        print(f"  login error {r.status_code}: {r.text[:120]}", file=sys.stderr)
        return None
    except Exception as e:
        print(f"  login exception: {e}", file=sys.stderr)
        return None


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--count", type=int, default=120,
                    help="Number of test users to create (default 120)")
    ap.add_argument("--base-url", default="http://localhost:8000",
                    help="API base URL (default http://localhost:8000)")
    ap.add_argument("--output", default="test_users.json")
    ap.add_argument("--delay", type=float, default=0.05,
                    help="Seconds between registrations (default 0.05 = 20/sec)")
    args = ap.parse_args()

    # Verify server is reachable
    try:
        r = requests.get(f"{args.base_url}/health", timeout=5)
        print(f"Server: {r.json()}")
    except Exception as e:
        print(f"ERROR: Cannot reach {args.base_url}/health — {e}")
        sys.exit(1)

    users = []
    print(f"\nCreating {args.count} test users...")

    for i in range(args.count):
        tag = _rstr(12)
        email = f"loadtest_{tag}@loadtest.finery.pro"
        password = f"LoadPass_{tag[:8]}!9"
        name = f"LT {i + 1}"
        ip = _fake_ip()

        token = _register(args.base_url, email, password, name, ip)
        if token is None:
            token = _login(args.base_url, email, password, _fake_ip())

        if token:
            users.append({"email": email, "password": password, "token": token})
            print(f"  [{i+1:3d}/{args.count}] ✓ {email}")
        else:
            print(f"  [{i+1:3d}/{args.count}] ✗ FAILED {email}")

        if args.delay > 0:
            time.sleep(args.delay)

    with open(args.output, "w") as f:
        json.dump(users, f, indent=2)

    ok = len(users)
    print(f"\n✓ {ok}/{args.count} users saved to {args.output}")
    if ok < args.count:
        print(f"  {args.count - ok} failed — consider re-running with --delay 0.2")

    print("""
Cleanup SQL (run after testing):
  DELETE FROM users WHERE email LIKE 'loadtest_%@loadtest.finery.pro';
""")


if __name__ == "__main__":
    main()
