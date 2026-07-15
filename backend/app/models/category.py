"""Modelo Category → tabla `categories` (soft-delete vía `activo`)."""

from __future__ import annotations

from datetime import datetime
from typing import TYPE_CHECKING

from sqlalchemy import Boolean, DateTime, String, func
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db.base import Base

if TYPE_CHECKING:
    from app.models.budget import Budget
    from app.models.sub_category import SubCategory
    from app.models.transaction import Transaction


class Category(Base):
    __tablename__ = "categories"

    id: Mapped[int] = mapped_column(primary_key=True, autoincrement=True)
    nombre: Mapped[str] = mapped_column(String(100), nullable=False, unique=True)
    descripcion: Mapped[str] = mapped_column(String(255), nullable=False, default="")
    activo: Mapped[bool] = mapped_column(Boolean, nullable=False, default=True)

    creado_en: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        server_default=func.now(),
        nullable=False,
    )
    actualizado_en: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        server_default=func.now(),
        onupdate=func.now(),
        nullable=False,
    )

    # Sin cascade delete: desactivar categoría desactiva subcategorías en el service.
    sub_categories: Mapped[list[SubCategory]] = relationship(back_populates="category")
    transactions: Mapped[list[Transaction]] = relationship(back_populates="category")
    budgets: Mapped[list[Budget]] = relationship(back_populates="category")

    def __repr__(self) -> str:
        return f"Category(id={self.id}, nombre={self.nombre!r}, activo={self.activo})"
