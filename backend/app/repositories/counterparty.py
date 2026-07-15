"""
app/repositories/counterparty.py — Acceso a datos de Counterparty
"""

from __future__ import annotations

from sqlalchemy import func, select
from sqlalchemy.orm import Session

from app.models.counterparty import Counterparty


class CounterpartyRepository:
    @staticmethod
    def get_by_id(db: Session, counterparty_id: int) -> Counterparty | None:
        return db.get(Counterparty, counterparty_id)

    @staticmethod
    def get_by_id_for_user(
        db: Session,
        *,
        counterparty_id: int,
        user_id: int,
        only_active: bool = False,
    ) -> Counterparty | None:
        filters = [Counterparty.id == counterparty_id, Counterparty.user_id == user_id]
        if only_active:
            filters.append(Counterparty.activo.is_(True))
        return db.scalar(select(Counterparty).where(*filters))

    @staticmethod
    def list_filtered(
        db: Session,
        *,
        user_id: int,
        only_active: bool = True,
        limit: int = 20,
        offset: int = 0,
    ) -> tuple[list[Counterparty], int]:
        filters = [Counterparty.user_id == user_id]
        if only_active:
            filters.append(Counterparty.activo.is_(True))
        base = select(Counterparty).where(*filters)
        total = db.scalar(select(func.count()).select_from(base.subquery())) or 0
        items = list(
            db.scalars(
                base.order_by(Counterparty.id.desc()).limit(limit).offset(offset)
            ).all()
        )
        return items, int(total)

    @staticmethod
    def create(db: Session, item: Counterparty) -> Counterparty:
        db.add(item)
        db.flush()
        db.refresh(item)
        return item

    @staticmethod
    def update(db: Session, item: Counterparty) -> Counterparty:
        db.add(item)
        db.flush()
        db.refresh(item)
        return item
