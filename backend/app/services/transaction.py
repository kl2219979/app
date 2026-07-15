"""
app/services/transaction.py — Contabilidad de movimientos

Principios:
- El saldo de la cuenta SOLO cambia por movimientos activos.
- No se borran movimientos: se desactivan y se revierte el impacto.
- Transferencias = dos piernas vinculadas (salida + entrada).
- Solo se opera sobre cuentas/categorías activas.
- medio_pago=efectivo resuelve wallet interno (tipo=efectivo) por moneda.
- contraparte_id opcional documenta terceros fuera del sistema.
"""

from __future__ import annotations

import uuid
from datetime import date
from decimal import Decimal

from fastapi import HTTPException, status
from sqlalchemy.orm import Session

from app.models.account import Account
from app.models.transaction import Transaction
from app.models.user import User
from app.repositories.account import AccountRepository
from app.repositories.category import CategoryRepository
from app.repositories.counterparty import CounterpartyRepository
from app.repositories.sub_category import SubCategoryRepository
from app.repositories.transaction import TransactionRepository
from app.schemas.pagination import Page
from app.schemas.transaction import (
    TransactionCreate,
    TransactionResponse,
    TransactionUpdate,
    TransferCreate,
    TransferResponse,
)

_CREDIT_TIPOS = {"ingreso", "transferencia_entrada"}
_DEBIT_TIPOS = {"gasto", "transferencia_salida"}
_OPERATIVE_TIPOS = {"gasto", "ingreso"}


class TransactionService:
    @staticmethod
    def _delta(tipo: str, monto: Decimal) -> Decimal:
        if tipo in _CREDIT_TIPOS:
            return monto
        if tipo in _DEBIT_TIPOS:
            return -monto
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="tipo de movimiento no válido",
        )

    @staticmethod
    def _apply_saldo(account: Account, delta: Decimal) -> None:
        account.saldo = Decimal(account.saldo) + delta

    @staticmethod
    def _ensure_sufficient_funds(account: Account, tipo: str, monto: Decimal) -> None:
        """Gastos y transferencias-salida no pueden dejar saldo negativo."""
        if tipo not in _DEBIT_TIPOS:
            return
        if Decimal(account.saldo) < Decimal(monto):
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Fondos insuficientes en la cuenta",
            )

    @staticmethod
    def _ensure_category_pair(db: Session, category_id: int, sub_category_id: int) -> None:
        category = CategoryRepository.get_by_id(db, category_id)
        if category is None or not category.activo:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Categoría no encontrada o inactiva",
            )
        sub = SubCategoryRepository.get_by_id(db, sub_category_id)
        if sub is None or not sub.activo:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Subcategoría no encontrada o inactiva",
            )
        if sub.category_id != category_id:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="La subcategoría no pertenece a la categoría indicada",
            )

    @staticmethod
    def _get_own_active_account(db: Session, user: User, account_id: int) -> Account:
        account = AccountRepository.get_by_id_for_user(
            db, account_id=account_id, user_id=user.id, only_active=True
        )
        if account is None:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Cuenta no encontrada o inactiva",
            )
        return account

    @staticmethod
    def _ensure_own_active_counterparty(
        db: Session, user: User, contraparte_id: int | None
    ) -> None:
        if contraparte_id is None:
            return
        item = CounterpartyRepository.get_by_id_for_user(
            db,
            counterparty_id=contraparte_id,
            user_id=user.id,
            only_active=True,
        )
        if item is None:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Contraparte no encontrada o inactiva",
            )

    @staticmethod
    def _resolve_account_for_medio(
        db: Session,
        user: User,
        *,
        medio_pago: str,
        account_id: int | None,
        moneda: str | None,
    ) -> Account:
        if medio_pago == "efectivo":
            if account_id is not None:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail="No envíes account_id cuando medio_pago=efectivo; usa moneda",
                )
            if not moneda:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail="moneda es obligatoria cuando medio_pago=efectivo",
                )
            return AccountRepository.get_or_create_cash_wallet(
                db, user_id=user.id, moneda=moneda
            )
        if account_id is None:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="account_id es obligatorio cuando medio_pago=cuenta",
            )
        return TransactionService._get_own_active_account(db, user, account_id)

    @staticmethod
    def list_mine(
        db: Session,
        current_user: User,
        *,
        account_id: int | None = None,
        category_id: int | None = None,
        sub_category_id: int | None = None,
        contraparte_id: int | None = None,
        medio_pago: str | None = None,
        tipo: str | None = None,
        date_from: date | None = None,
        date_to: date | None = None,
        limit: int = 20,
        offset: int = 0,
    ) -> Page[TransactionResponse]:
        if account_id is not None:
            account = AccountRepository.get_by_id_for_user(
                db, account_id=account_id, user_id=current_user.id
            )
            if account is None:
                raise HTTPException(
                    status_code=status.HTTP_404_NOT_FOUND,
                    detail="Cuenta no encontrada",
                )
        if contraparte_id is not None:
            cp = CounterpartyRepository.get_by_id_for_user(
                db, counterparty_id=contraparte_id, user_id=current_user.id
            )
            if cp is None:
                raise HTTPException(
                    status_code=status.HTTP_404_NOT_FOUND,
                    detail="Contraparte no encontrada",
                )
        items, total = TransactionRepository.list_filtered(
            db,
            user_id=current_user.id,
            account_id=account_id,
            category_id=category_id,
            sub_category_id=sub_category_id,
            contraparte_id=contraparte_id,
            medio_pago=medio_pago,
            tipo=tipo,
            date_from=date_from,
            date_to=date_to,
            only_active=True,
            limit=limit,
            offset=offset,
        )
        return Page[TransactionResponse](
            items=[TransactionResponse.model_validate(i) for i in items],
            total=total,
            limit=limit,
            offset=offset,
        )

    @staticmethod
    def get_mine(db: Session, current_user: User, transaction_id: int) -> Transaction:
        item = TransactionRepository.get_by_id_for_user(
            db, transaction_id=transaction_id, user_id=current_user.id, only_active=True
        )
        if item is None:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Transacción no encontrada o inactiva",
            )
        return item

    @staticmethod
    def create(db: Session, current_user: User, data: TransactionCreate) -> Transaction:
        account = TransactionService._resolve_account_for_medio(
            db,
            current_user,
            medio_pago=data.medio_pago,
            account_id=data.account_id,
            moneda=data.moneda,
        )
        TransactionService._ensure_category_pair(db, data.category_id, data.sub_category_id)
        TransactionService._ensure_own_active_counterparty(
            db, current_user, data.contraparte_id
        )
        TransactionService._ensure_sufficient_funds(account, data.tipo, data.monto)
        item = Transaction(
            account_id=account.id,
            category_id=data.category_id,
            sub_category_id=data.sub_category_id,
            contraparte_id=data.contraparte_id,
            monto=data.monto,
            tipo=data.tipo,
            medio_pago=data.medio_pago,
            fecha=data.fecha,
            descripcion=data.descripcion,
            activo=True,
        )
        TransactionRepository.create(db, item)
        TransactionService._apply_saldo(account, TransactionService._delta(item.tipo, item.monto))
        AccountRepository.update(db, account)
        db.commit()
        db.refresh(item)
        return item

    @staticmethod
    def update(
        db: Session,
        current_user: User,
        transaction_id: int,
        data: TransactionUpdate,
    ) -> Transaction:
        item = TransactionService.get_mine(db, current_user, transaction_id)
        if item.grupo_transferencia:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="No se puede editar una pierna de transferencia; "
                "desactívala y crea una nueva",
            )
        if item.tipo not in _OPERATIVE_TIPOS:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Solo se editan movimientos operativos (gasto/ingreso)",
            )

        payload = data.model_dump(exclude_unset=True)
        medio_pago = payload.get("medio_pago", item.medio_pago)
        new_tipo = payload.get("tipo", item.tipo)
        new_monto = payload.get("monto", item.monto)
        category_id = payload.get("category_id", item.category_id)
        sub_category_id = payload.get("sub_category_id", item.sub_category_id)
        contraparte_id = payload.get("contraparte_id", item.contraparte_id)

        account_id_in_payload = "account_id" in payload
        moneda_in_payload = "moneda" in payload
        account_id = payload.get("account_id")
        moneda = payload.get("moneda")

        if medio_pago == "efectivo":
            if account_id_in_payload and account_id is not None:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail="No envíes account_id cuando medio_pago=efectivo; usa moneda",
                )
            if item.medio_pago != "efectivo" and not moneda_in_payload:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail="moneda es obligatoria al cambiar a medio_pago=efectivo",
                )
            if not moneda_in_payload and item.medio_pago == "efectivo":
                # Same cash account; keep using current account unless moneda provided.
                new_account = TransactionService._get_own_active_account(
                    db, current_user, item.account_id
                )
            else:
                new_account = AccountRepository.get_or_create_cash_wallet(
                    db, user_id=current_user.id, moneda=moneda  # type: ignore[arg-type]
                )
        else:
            resolved_account_id = (
                account_id if account_id_in_payload else item.account_id
            )
            if resolved_account_id is None:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail="account_id es obligatorio cuando medio_pago=cuenta",
                )
            new_account = TransactionService._get_own_active_account(
                db, current_user, resolved_account_id
            )

        old_account = TransactionService._get_own_active_account(
            db, current_user, item.account_id
        )
        TransactionService._ensure_category_pair(db, category_id, sub_category_id)
        TransactionService._ensure_own_active_counterparty(
            db, current_user, contraparte_id
        )
        _ = TransactionService._delta(new_tipo, new_monto)

        TransactionService._apply_saldo(
            old_account,
            -TransactionService._delta(item.tipo, item.monto),
        )
        try:
            TransactionService._ensure_sufficient_funds(
                new_account, new_tipo, new_monto
            )
        except HTTPException:
            # Revert the temporary undo so the failed update leaves balances unchanged.
            TransactionService._apply_saldo(
                old_account,
                TransactionService._delta(item.tipo, item.monto),
            )
            raise
        # moneda is request-only; never persist on Transaction.
        payload.pop("moneda", None)
        for key, value in payload.items():
            setattr(item, key, value)
        item.account_id = new_account.id
        item.medio_pago = medio_pago
        item.contraparte_id = contraparte_id
        TransactionRepository.update(db, item)
        TransactionService._apply_saldo(
            new_account,
            TransactionService._delta(item.tipo, item.monto),
        )
        AccountRepository.update(db, old_account)
        if new_account.id != old_account.id:
            AccountRepository.update(db, new_account)
        db.commit()
        db.refresh(item)
        return item

    @staticmethod
    def deactivate(db: Session, current_user: User, transaction_id: int) -> None:
        """Soft-delete: revierte saldo y marca activo=False. Historial permanece."""
        item = TransactionService.get_mine(db, current_user, transaction_id)

        if item.grupo_transferencia:
            legs = TransactionRepository.list_by_transfer_group(db, item.grupo_transferencia)
            for leg in legs:
                if not leg.activo:
                    continue
                account = AccountRepository.get_by_id_for_user(
                    db, account_id=leg.account_id, user_id=current_user.id
                )
                if account is None:
                    raise HTTPException(
                        status_code=status.HTTP_404_NOT_FOUND,
                        detail="Cuenta asociada a la transferencia no encontrada",
                    )
                TransactionService._apply_saldo(
                    account,
                    -TransactionService._delta(leg.tipo, leg.monto),
                )
                leg.activo = False
                TransactionRepository.update(db, leg)
                AccountRepository.update(db, account)
            db.commit()
            return

        account = AccountRepository.get_by_id_for_user(
            db, account_id=item.account_id, user_id=current_user.id
        )
        if account is None:
            raise HTTPException(status_code=404, detail="Cuenta no encontrada")
        TransactionService._apply_saldo(
            account,
            -TransactionService._delta(item.tipo, item.monto),
        )
        item.activo = False
        TransactionRepository.update(db, item)
        AccountRepository.update(db, account)
        db.commit()

    @staticmethod
    def transfer(db: Session, current_user: User, data: TransferCreate) -> TransferResponse:
        if data.from_account_id == data.to_account_id:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="La cuenta origen y destino deben ser distintas",
            )
        origen = TransactionService._get_own_active_account(
            db, current_user, data.from_account_id
        )
        destino = TransactionService._get_own_active_account(
            db, current_user, data.to_account_id
        )
        if origen.moneda != destino.moneda:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Las transferencias requieren la misma moneda en ambas cuentas",
            )
        TransactionService._ensure_category_pair(db, data.category_id, data.sub_category_id)
        TransactionService._ensure_sufficient_funds(
            origen, "transferencia_salida", data.monto
        )

        grupo = str(uuid.uuid4())
        desc_out = data.descripcion or "Transferencia entre cuentas"
        salida = Transaction(
            account_id=origen.id,
            category_id=data.category_id,
            sub_category_id=data.sub_category_id,
            monto=data.monto,
            tipo="transferencia_salida",
            medio_pago="cuenta",
            fecha=data.fecha,
            descripcion=f"{desc_out} (salida)",
            activo=True,
            grupo_transferencia=grupo,
        )
        entrada = Transaction(
            account_id=destino.id,
            category_id=data.category_id,
            sub_category_id=data.sub_category_id,
            monto=data.monto,
            tipo="transferencia_entrada",
            medio_pago="cuenta",
            fecha=data.fecha,
            descripcion=f"{desc_out} (entrada)",
            activo=True,
            grupo_transferencia=grupo,
        )
        TransactionRepository.create(db, salida)
        TransactionRepository.create(db, entrada)
        TransactionService._apply_saldo(
            origen, TransactionService._delta(salida.tipo, salida.monto)
        )
        TransactionService._apply_saldo(
            destino, TransactionService._delta(entrada.tipo, entrada.monto)
        )
        AccountRepository.update(db, origen)
        AccountRepository.update(db, destino)
        db.commit()
        db.refresh(salida)
        db.refresh(entrada)
        return TransferResponse(
            grupo_transferencia=grupo,
            salida=TransactionResponse.model_validate(salida),
            entrada=TransactionResponse.model_validate(entrada),
        )
