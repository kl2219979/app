"""
app/repositories/account.py — Acceso a datos de Account
"""

from __future__ import annotations

from decimal import Decimal

from sqlalchemy import func, select
from sqlalchemy.orm import Session

from app.models.account import Account

CASH_TIPO = "efectivo"
CASH_BANCO = "Efectivo"


class AccountRepository:
    @staticmethod
    def get_by_id(db: Session, account_id: int) -> Account | None:
        return db.get(Account, account_id)

    @staticmethod
    def get_by_id_for_user(
        db: Session,
        *,
        account_id: int,
        user_id: int,
        only_active: bool = False,
    ) -> Account | None:
        filters = [Account.id == account_id, Account.user_id == user_id]
        if only_active:
            filters.append(Account.activo.is_(True))
        return db.scalar(select(Account).where(*filters))

    @staticmethod
    def get_cash_wallet(
        db: Session,
        *,
        user_id: int,
        moneda: str,
        only_active: bool = False,
    ) -> Account | None:
        filters = [
            Account.user_id == user_id,
            Account.moneda == moneda,
            Account.tipo == CASH_TIPO,
        ]
        if only_active:
            filters.append(Account.activo.is_(True))
        return db.scalar(
            select(Account).where(*filters).order_by(Account.id.asc()).limit(1)
        )

    @staticmethod
    def get_or_create_cash_wallet(
        db: Session,
        *,
        user_id: int,
        moneda: str,
    ) -> Account:
        """Wallet de efectivo único por usuario+moneda (auto-gestionado)."""
        existing = AccountRepository.get_cash_wallet(
            db, user_id=user_id, moneda=moneda, only_active=False
        )
        if existing is not None:
            if not existing.activo:
                existing.activo = True
                AccountRepository.update(db, existing)
            return existing
        wallet = Account(
            user_id=user_id,
            banco=CASH_BANCO,
            tipo=CASH_TIPO,
            moneda=moneda,
            saldo=Decimal("0.00"),
            activo=True,
        )
        return AccountRepository.create(db, wallet)

    @staticmethod
    def list_by_user(db: Session, user_id: int) -> list[Account]:
        items, _ = AccountRepository.list_filtered(
            db, user_id=user_id, limit=10_000, offset=0
        )
        return items

    @staticmethod
    def list_filtered(
        db: Session,
        *,
        user_id: int,
        only_active: bool = True,
        limit: int = 20,
        offset: int = 0,
    ) -> tuple[list[Account], int]:
        filters = [Account.user_id == user_id]
        if only_active:
            filters.append(Account.activo.is_(True))
        base = select(Account).where(*filters)
        total = db.scalar(select(func.count()).select_from(base.subquery())) or 0
        items = list(
            db.scalars(
                base.order_by(Account.id.desc()).limit(limit).offset(offset)
            ).all()
        )
        return items, int(total)

    @staticmethod
    def create(db: Session, account: Account) -> Account:
        db.add(account)
        db.flush()
        db.refresh(account)
        return account

    @staticmethod
    def update(db: Session, account: Account) -> Account:
        db.add(account)
        db.flush()
        db.refresh(account)
        return account
