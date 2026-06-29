from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from slowapi import _rate_limit_exceeded_handler
from slowapi.errors import RateLimitExceeded

from app.api import auth, transactions, analytics, tax, clients, invoices
from app.core.config import settings
from app.core.database import create_tables
from app.core.limiter import limiter


@asynccontextmanager
async def lifespan(app: FastAPI):
    try:
        await create_tables()
    except Exception as exc:
        print(f"[WARN] DB not available at startup: {exc}")
    yield


_is_production = settings.ENV == "production"

app = FastAPI(
    title="Finery API",
    description="Финансовый менеджер для фрилансеров и самозанятых",
    version="1.0.0",
    lifespan=lifespan,
    docs_url=None if _is_production else "/docs",
    redoc_url=None,
)

app.state.limiter = limiter
app.add_exception_handler(RateLimitExceeded, _rate_limit_exceeded_handler)

app.add_middleware(
    CORSMiddleware,
    allow_origins=[
        "http://85.239.41.204:8000",
        "http://localhost:3000",
        "capacitor://localhost",
        "ionic://localhost",
    ],
    allow_credentials=False,
    allow_methods=["GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS"],
    allow_headers=["Authorization", "Content-Type"],
)

app.include_router(auth.router,         prefix="/api/v1")
app.include_router(transactions.router, prefix="/api/v1")
app.include_router(analytics.router,    prefix="/api/v1")
app.include_router(tax.router,          prefix="/api/v1")
app.include_router(clients.router,      prefix="/api/v1")
app.include_router(invoices.router,     prefix="/api/v1")


@app.get("/health")
async def health():
    return {"status": "ok", "service": "finery-api"}
