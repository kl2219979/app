"""
app/repositories/category.py — Acceso a datos de Category
"""

from __future__ import annotations

from sqlalchemy import func, select
from sqlalchemy.orm import Session

from app.models.category import Category


class CategoryRepository:
    @staticmethod
    def get_by_id(db: Session, category_id: int) -> Category | None:
        return db.get(Category, category_id)

    @staticmethod
    def get_by_nombre(db: Session, nombre: str) -> Category | None:
        return db.scalar(select(Category).where(Category.nombre == nombre))

    @staticmethod
    def list_all(db: Session) -> list[Category]:
        items, _ = CategoryRepository.list_filtered(db, limit=10_000, offset=0)
        return items

    @staticmethod
    def list_filtered(
        db: Session,
        *,
        only_active: bool = True,
        limit: int = 20,
        offset: int = 0,
    ) -> tuple[list[Category], int]:
        base = select(Category)
        if only_active:
            base = base.where(Category.activo.is_(True))
        total = db.scalar(select(func.count()).select_from(base.subquery())) or 0
        items = list(
            db.scalars(
                base.order_by(Category.nombre.asc()).limit(limit).offset(offset)
            ).all()
        )
        return items, int(total)

    @staticmethod
    def create(db: Session, category: Category) -> Category:
        db.add(category)
        db.flush()
        db.refresh(category)
        return category

    @staticmethod
    def update(db: Session, category: Category) -> Category:
        db.add(category)
        db.flush()
        db.refresh(category)
        return category
