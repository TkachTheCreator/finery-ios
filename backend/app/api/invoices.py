import json
import uuid

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy import select, and_
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.auth import current_user
from app.core.database import get_db
from app.models.invoice import Invoice
from app.models.user import User
from app.schemas.invoice import InvoiceCreate, InvoiceOut

router = APIRouter(prefix="/invoices", tags=["invoices"])


@router.get("", response_model=list[InvoiceOut])
async def list_invoices(
    user: User = Depends(current_user),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(
        select(Invoice)
        .where(Invoice.user_id == user.id)
        .order_by(Invoice.created_at.desc())
    )
    return result.scalars().all()


@router.post("", response_model=InvoiceOut, status_code=201)
async def create_invoice(
    body: InvoiceCreate,
    user: User = Depends(current_user),
    db: AsyncSession = Depends(get_db),
):
    items_json = json.dumps([item.model_dump(mode="json") for item in body.items])
    invoice = Invoice(
        user_id=user.id,
        number=body.number,
        date=body.date,
        client_id=body.client_id,
        client_name=body.client_name,
        items_json=items_json,
        include_vat=body.include_vat,
        executor_name=body.executor_name,
        total=body.total,
    )
    db.add(invoice)
    await db.flush()
    await db.refresh(invoice)
    return invoice


@router.delete("/{invoice_id}", status_code=204)
async def delete_invoice(
    invoice_id: uuid.UUID,
    user: User = Depends(current_user),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(
        select(Invoice).where(and_(Invoice.id == invoice_id, Invoice.user_id == user.id))
    )
    invoice = result.scalar_one_or_none()
    if not invoice:
        raise HTTPException(status_code=404, detail="Invoice not found")
    await db.delete(invoice)
