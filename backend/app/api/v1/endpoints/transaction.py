"""
app/api/v1/endpoints/transaction.py — Movimientos y transferencias (JWT)

DELETE = desactivar (revierte saldo, conserva historial).
POST /transfers = mover dinero entre cuentas propias.
"""

from datetime import date
from typing import Literal

from fastapi import APIRouter, Depends, Query, status
from sqlalchemy.orm import Session

from app.api.deps import get_current_user, get_db
from app.models.user import User
from app.schemas.pagination import Page
from app.schemas.transaction import (
    TransactionCreate,
    TransactionResponse,
    TransactionUpdate,
    TransferCreate,
    TransferResponse,
)
from app.services.export import ExportService
from app.services.transaction import TransactionService

router = APIRouter(prefix="/transactions", tags=["transactions"])


@router.get("/export")
def export_transactions(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
    format: Literal["csv", "json"] = Query(default="csv"),
    account_id: int | None = Query(default=None, gt=0),
    category_id: int | None = Query(default=None, gt=0),
    sub_category_id: int | None = Query(default=None, gt=0),
    contraparte_id: int | None = Query(default=None, gt=0),
    medio_pago: Literal["cuenta", "efectivo"] | None = Query(default=None),
    tipo: Literal[
        "gasto", "ingreso", "transferencia_salida", "transferencia_entrada"
    ]
    | None = Query(default=None),
    date_from: date | None = Query(default=None),
    date_to: date | None = Query(default=None),
):
    """Descarga movimientos activos (máx. 10_000) en CSV o JSON."""
    return ExportService.export_transactions(
        db,
        current_user,
        fmt=format,
        account_id=account_id,
        category_id=category_id,
        sub_category_id=sub_category_id,
        contraparte_id=contraparte_id,
        medio_pago=medio_pago,
        tipo=tipo,
        date_from=date_from,
        date_to=date_to,
    )


@router.get("", response_model=Page[TransactionResponse])
def list_transactions(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
    limit: int = Query(default=20, ge=1, le=100),
    offset: int = Query(default=0, ge=0),
    account_id: int | None = Query(default=None, gt=0),
    category_id: int | None = Query(default=None, gt=0),
    sub_category_id: int | None = Query(default=None, gt=0),
    contraparte_id: int | None = Query(default=None, gt=0),
    medio_pago: Literal["cuenta", "efectivo"] | None = Query(default=None),
    tipo: Literal[
        "gasto", "ingreso", "transferencia_salida", "transferencia_entrada"
    ]
    | None = Query(default=None),
    date_from: date | None = Query(default=None),
    date_to: date | None = Query(default=None),
) -> Page[TransactionResponse]:
    """
    Listado propio, solo activos.

    Orden estable: `fecha DESC`, luego `id DESC` (más recientes primero).
    """
    return TransactionService.list_mine(
        db,
        current_user,
        account_id=account_id,
        category_id=category_id,
        sub_category_id=sub_category_id,
        contraparte_id=contraparte_id,
        medio_pago=medio_pago,
        tipo=tipo,
        date_from=date_from,
        date_to=date_to,
        limit=limit,
        offset=offset,
    )


@router.post(
    "/transfers",
    response_model=TransferResponse,
    status_code=status.HTTP_201_CREATED,
)
def create_transfer(
    data: TransferCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    return TransactionService.transfer(db, current_user, data)


@router.get("/{transaction_id}", response_model=TransactionResponse)
def get_transaction(
    transaction_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    return TransactionService.get_mine(db, current_user, transaction_id)


@router.post("", response_model=TransactionResponse, status_code=status.HTTP_201_CREATED)
def create_transaction(
    data: TransactionCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    return TransactionService.create(db, current_user, data)


@router.put("/{transaction_id}", response_model=TransactionResponse)
def update_transaction(
    transaction_id: int,
    data: TransactionUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    return TransactionService.update(db, current_user, transaction_id, data)


@router.delete("/{transaction_id}", status_code=status.HTTP_204_NO_CONTENT)
def deactivate_transaction(
    transaction_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> None:
    """Desactiva el movimiento (o ambas piernas si es transferencia)."""
    TransactionService.deactivate(db, current_user, transaction_id)
