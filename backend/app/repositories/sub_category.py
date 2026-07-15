"""
app/repositories/sub_category.py — Acceso a datos de SubCategory
"""

from __future__ import annotations

from sqlalchemy import func, select
from sqlalchemy.orm import Session

from app.models.sub_category import SubCategory


class SubCategoryRepository:
    @staticmethod
    def get_by_id(db: Session, sub_category_id: int) -> SubCategory | None:
        return db.get(SubCategory, sub_category_id)

    @staticmethod
    def list_by_category(db: Session, category_id: int) -> list[SubCategory]:
        items, _ = SubCategoryRepository.list_filtered(
            db, category_id=category_id, limit=10_000, offset=0
        )
        return items

    @staticmethod
    def list_filtered(
        db: Session,
        *,
        category_id: int | None = None,
        only_active: bool = True,
        limit: int = 20,
        offset: int = 0,
    ) -> tuple[list[SubCategory], int]:
        filters = []
        if category_id is not None:
            filters.append(SubCategory.category_id == category_id)
        if only_active:
            filters.append(SubCategory.activo.is_(True))
        base = select(SubCategory).where(*filters) if filters else select(SubCategory)
        total = db.scalar(select(func.count()).select_from(base.subquery())) or 0
        items = list(
            db.scalars(
                base.order_by(SubCategory.nombre.asc()).limit(limit).offset(offset)
            ).all()
        )
        return items, int(total)

    @staticmethod
    def create(db: Session, sub_category: SubCategory) -> SubCategory:
        db.add(sub_category)
        db.flush()
        db.refresh(sub_category)
        return sub_category

    @staticmethod
    def update(db: Session, sub_category: SubCategory) -> SubCategory:
        db.add(sub_category)
        db.flush()
        db.refresh(sub_category)
        return sub_category

    @staticmethod
    def deactivate_by_category(db: Session, category_id: int) -> int:
        items = list(
            db.scalars(
                select(SubCategory).where(
                    SubCategory.category_id == category_id,
                    SubCategory.activo.is_(True),
                )
            ).all()
        )
        for item in items:
            item.activo = False
            db.add(item)
        db.flush()
        return len(items)
