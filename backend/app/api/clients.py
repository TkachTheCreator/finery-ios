import uuid

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy import select, and_
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.auth import current_user
from app.core.database import get_db
from app.models.client import Client
from app.models.transaction import Transaction
from app.models.user import User
from app.schemas.client import ClientCreate, ClientOut, ClientUpdate
from app.schemas.transaction import TransactionOut

router = APIRouter(prefix="/clients", tags=["clients"])


@router.get("", response_model=list[ClientOut])
async def list_clients(
    user: User = Depends(current_user),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(
        select(Client)
        .where(Client.user_id == user.id)
        .order_by(Client.created_at.desc())
    )
    return result.scalars().all()


@router.post("", response_model=ClientOut, status_code=201)
async def create_client(
    body: ClientCreate,
    user: User = Depends(current_user),
    db: AsyncSession = Depends(get_db),
):
    client = Client(user_id=user.id, **body.model_dump())
    db.add(client)
    await db.flush()
    await db.refresh(client)
    return client


@router.put("/{client_id}", response_model=ClientOut)
async def update_client(
    client_id: uuid.UUID,
    body: ClientUpdate,
    user: User = Depends(current_user),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(
        select(Client).where(and_(Client.id == client_id, Client.user_id == user.id))
    )
    client = result.scalar_one_or_none()
    if not client:
        raise HTTPException(status_code=404, detail="Client not found")
    for k, v in body.model_dump(exclude_none=True).items():
        setattr(client, k, v)
    await db.flush()
    await db.refresh(client)
    return client


@router.delete("/{client_id}", status_code=204)
async def delete_client(
    client_id: uuid.UUID,
    user: User = Depends(current_user),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(
        select(Client).where(and_(Client.id == client_id, Client.user_id == user.id))
    )
    client = result.scalar_one_or_none()
    if not client:
        raise HTTPException(status_code=404, detail="Client not found")
    await db.delete(client)


@router.get("/{client_id}/transactions", response_model=list[TransactionOut])
async def client_transactions(
    client_id: uuid.UUID,
    user: User = Depends(current_user),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(
        select(Transaction).where(
            and_(
                Transaction.user_id == user.id,
                Transaction.client_id == client_id,
            )
        ).order_by(Transaction.date.desc())
    )
    return result.scalars().all()
