"""
app/services/account.py — Cuentas financieras

- saldo_inicial solo al crear.
- Después el saldo solo cambia por transacciones.
- DELETE = desactivar (historial y movimientos se conservan).
"""

from __future__ import annotations

from fastapi import HTTPException, status
from sqlalchemy.orm import Session

from app.models.account import Account
from app.models.user import User
from app.repositories.account import CASH_TIPO, AccountRepository
from app.schemas.account import AccountCreate, AccountResponse, AccountUpdate
from app.schemas.pagination import Page


class AccountService:
    @staticmethod
    def list_mine(
        db: Session,
        current_user: User,
        *,
        limit: int = 20,
        offset: int = 0,
        include_inactive: bool = False,
    ) -> Page[AccountResponse]:
        items, total = AccountRepository.list_filtered(
            db,
            user_id=current_user.id,
            only_active=not include_inactive,
            limit=limit,
            offset=offset,
        )
        return Page[AccountResponse](
            items=[AccountResponse.model_validate(i) for i in items],
            total=total,
            limit=limit,
            offset=offset,
        )

    @staticmethod
    def get_mine(db: Session, current_user: User, account_id: int) -> Account:
        account = AccountRepository.get_by_id_for_user(
            db, account_id=account_id, user_id=current_user.id
        )
        if account is None:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Cuenta no encontrada",
            )
        return account

    @staticmethod
    def create(db: Session, current_user: User, data: AccountCreate) -> Account:
        if data.tipo.strip().lower() == CASH_TIPO:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=(
                    "El wallet de efectivo se crea automáticamente con "
                    "medio_pago=efectivo; no lo crees manualmente"
                ),
            )
        account = Account(
            user_id=current_user.id,
            banco=data.banco,
            tipo=data.tipo,
            moneda=data.moneda,
            saldo=data.saldo_inicial,
            activo=True,
        )
        AccountRepository.create(db, account)
        db.commit()
        db.refresh(account)
        return account

    @staticmethod
    def update(
        db: Session,
        current_user: User,
        account_id: int,
        data: AccountUpdate,
    ) -> Account:
        account = AccountService.get_mine(db, current_user, account_id)
        if not account.activo:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="No se puede editar una cuenta inactiva; reactívala primero",
            )
        payload = data.model_dump(exclude_unset=True)
        new_tipo = payload.get("tipo", account.tipo)
        new_moneda = payload.get("moneda", account.moneda)
        if str(new_tipo).strip().lower() == CASH_TIPO:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=(
                    "No se puede convertir una cuenta a wallet de efectivo; "
                    "usa medio_pago=efectivo en movimientos"
                ),
            )
        if account.tipo == CASH_TIPO and ("tipo" in payload or "moneda" in payload):
            # Keep system cash wallets stable.
            if "tipo" in payload and payload["tipo"] != account.tipo:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail="No se puede cambiar el tipo del wallet de efectivo",
                )
            if "moneda" in payload and payload["moneda"] != account.moneda:
                other = AccountRepository.get_cash_wallet(
                    db,
                    user_id=current_user.id,
                    moneda=new_moneda,
                    only_active=False,
                )
                if other is not None and other.id != account.id:
                    raise HTTPException(
                        status_code=status.HTTP_400_BAD_REQUEST,
                        detail="Ya existe un wallet de efectivo para esa moneda",
                    )
        for key, value in payload.items():
            setattr(account, key, value)
        AccountRepository.update(db, account)
        db.commit()
        db.refresh(account)
        return account

    @staticmethod
    def deactivate(db: Session, current_user: User, account_id: int) -> None:
        """Desactiva la cuenta. No borra movimientos ni altera saldos históricos."""
        account = AccountService.get_mine(db, current_user, account_id)
        if not account.activo:
            return
        account.activo = False
        AccountRepository.update(db, account)
        db.commit()

    @staticmethod
    def reactivate(db: Session, current_user: User, account_id: int) -> Account:
        account = AccountService.get_mine(db, current_user, account_id)
        account.activo = True
        AccountRepository.update(db, account)
        db.commit()
        db.refresh(account)
        return account
