"""
app/services/sub_category.py — Soft-delete de subcategorías
"""

from __future__ import annotations

from fastapi import HTTPException, status
from sqlalchemy.orm import Session

from app.models.sub_category import SubCategory
from app.repositories.category import CategoryRepository
from app.repositories.sub_category import SubCategoryRepository
from app.schemas.pagination import Page
from app.schemas.sub_category import SubCategoryCreate, SubCategoryResponse, SubCategoryUpdate


class SubCategoryService:
    @staticmethod
    def list_all(
        db: Session,
        *,
        category_id: int | None = None,
        limit: int = 20,
        offset: int = 0,
        include_inactive: bool = False,
    ) -> Page[SubCategoryResponse]:
        if category_id is not None and CategoryRepository.get_by_id(db, category_id) is None:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Categoría no encontrada",
            )
        items, total = SubCategoryRepository.list_filtered(
            db,
            category_id=category_id,
            only_active=not include_inactive,
            limit=limit,
            offset=offset,
        )
        return Page[SubCategoryResponse](
            items=[SubCategoryResponse.model_validate(i) for i in items],
            total=total,
            limit=limit,
            offset=offset,
        )

    @staticmethod
    def get(db: Session, sub_category_id: int) -> SubCategory:
        item = SubCategoryRepository.get_by_id(db, sub_category_id)
        if item is None:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Subcategoría no encontrada",
            )
        return item

    @staticmethod
    def create(db: Session, data: SubCategoryCreate) -> SubCategory:
        category = CategoryRepository.get_by_id(db, data.category_id)
        if category is None or not category.activo:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Categoría no encontrada o inactiva",
            )
        item = SubCategory(
            category_id=data.category_id,
            nombre=data.nombre,
            descripcion=data.descripcion,
            activo=True,
        )
        SubCategoryRepository.create(db, item)
        db.commit()
        db.refresh(item)
        return item

    @staticmethod
    def update(db: Session, sub_category_id: int, data: SubCategoryUpdate) -> SubCategory:
        item = SubCategoryService.get(db, sub_category_id)
        if not item.activo:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="No se puede editar una subcategoría inactiva",
            )
        payload = data.model_dump(exclude_unset=True)
        if "category_id" in payload:
            category = CategoryRepository.get_by_id(db, payload["category_id"])
            if category is None or not category.activo:
                raise HTTPException(
                    status_code=status.HTTP_404_NOT_FOUND,
                    detail="Categoría no encontrada o inactiva",
                )
        for key, value in payload.items():
            setattr(item, key, value)
        SubCategoryRepository.update(db, item)
        db.commit()
        db.refresh(item)
        return item

    @staticmethod
    def deactivate(db: Session, sub_category_id: int) -> None:
        item = SubCategoryService.get(db, sub_category_id)
        if not item.activo:
            return
        item.activo = False
        SubCategoryRepository.update(db, item)
        db.commit()
