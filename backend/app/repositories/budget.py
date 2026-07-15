"""app/repositories/budget.py — Acceso a datos de Budget."""

from __future__ import annotations

from sqlalchemy import func, select
from sqlalchemy.orm import Session

from app.models.budget import Budget


class BudgetRepository:
    @staticmethod
    def get_by_id_for_user(
        db: Session,
        *,
        budget_id: int,
        user_id: int,
        only_active: bool = False,
    ) -> Budget | None:
        filters = [Budget.id == budget_id, Budget.user_id == user_id]
        if only_active:
            filters.append(Budget.activo.is_(True))
        return db.scalar(select(Budget).where(*filters))

    @staticmethod
    def get_by_category_for_user(
        db: Session,
        *,
        user_id: int,
        category_id: int,
    ) -> Budget | None:
        return db.scalar(
            select(Budget).where(
                Budget.user_id == user_id,
                Budget.category_id == category_id,
            )
        )

    @staticmethod
    def list_filtered(
        db: Session,
        *,
        user_id: int,
        only_active: bool = True,
        limit: int = 20,
        offset: int = 0,
    ) -> tuple[list[Budget], int]:
        filters = [Budget.user_id == user_id]
        if only_active:
            filters.append(Budget.activo.is_(True))
        base = select(Budget).where(*filters)
        total = db.scalar(select(func.count()).select_from(base.subquery())) or 0
        items = list(
            db.scalars(
                base.order_by(Budget.id.desc()).limit(limit).offset(offset)
            ).all()
        )
        return items, int(total)

    @staticmethod
    def create(db: Session, item: Budget) -> Budget:
        db.add(item)
        db.flush()
        db.refresh(item)
        return item

    @staticmethod
    def update(db: Session, item: Budget) -> Budget:
        db.add(item)
        db.flush()
        db.refresh(item)
        return item
