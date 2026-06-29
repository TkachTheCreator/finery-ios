from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.api import auth, transactions, analytics, tax, clients, invoices
from app.core.database import create_tables


@asynccontextmanager
async def lifespan(app: FastAPI):
    try:
        await create_tables()
    except Exception as exc:
        print(f"[WARN] DB not available at startup: {exc}")
    yield


app = FastAPI(
    title="Finery API",
    description="Финансовый менеджер для фрилансеров и самозанятых",
    version="1.0.0",
    lifespan=lifespan,
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
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
