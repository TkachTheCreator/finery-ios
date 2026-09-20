from slowapi import Limiter
from starlette.requests import Request


def _real_ip(request: Request) -> str:
    # nginx sets X-Real-IP to $remote_addr (the actual connecting IP).
    # If Cloudflare proxy mode is active, X-Real-IP will be a CF IP instead —
    # in that case configure nginx realip module to trust CF ranges and rewrite $remote_addr.
    return (
        request.headers.get("X-Real-IP")
        or request.headers.get("X-Forwarded-For", "").split(",")[0].strip()
        or (request.client.host if request.client else "127.0.0.1")
    )


# default_limits applies to all endpoints that have no explicit @limiter.limit decorator.
# Auth endpoints keep their stricter 5/minute because both limits are evaluated and
# the stricter one wins.
limiter = Limiter(key_func=_real_ip, default_limits=["100/minute"])
