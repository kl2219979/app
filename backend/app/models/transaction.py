"""
Modelo Transaction → tabla `transactions`.

tipos:
  gasto / ingreso                 → movimientos operativos
  transferencia_salida / _entrada → piernas de una transferencia (mismo grupo_transferencia)

medio_pago:
  cuenta   → account_id de una cuenta propia (banco/billetera)
  efectivo → account_id del wallet interno auto-gestionado (tipo=efectivo)

No se borran: se desactivan (`activo=False`) y se revierte el impacto en saldo.
"""

from __future__ import annotations

from datetime import date, datetime
from decimal import Decimal
from typing import TYPE_CHECKING

from sqlalchemy import Boolean, Date, DateTime, ForeignKey, Numeric, String, func
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db.base import Base

if TYPE_CHECKING:
    from app.models.account import Account
    from app.models.category import Category
    from app.models.counterparty import Counterparty
    from app.models.sub_category import SubCategory


class Transaction(Base):
    __tablename__ = "transactions"

    id: Mapped[int] = mapped_column(primary_key=True, autoincrement=True)

    account_id: Mapped[int] = mapped_column(
        ForeignKey("accounts.id"),
        nullable=False,
        index=True,
    )
    category_id: Mapped[int] = mapped_column(
        ForeignKey("categories.id"),
        nullable=False,
        index=True,
    )
    sub_category_id: Mapped[int] = mapped_column(
        ForeignKey("sub_categories.id"),
        nullable=False,
        index=True,
    )
    contraparte_id: Mapped[int | None] = mapped_column(
        ForeignKey("counterparties.id"),
        nullable=True,
        index=True,
    )

    monto: Mapped[Decimal] = mapped_column(Numeric(14, 2), nullable=False)
    tipo: Mapped[str] = mapped_column(String(30), nullable=False, default="gasto")
    medio_pago: Mapped[str] = mapped_column(String(20), nullable=False, default="cuenta")
    fecha: Mapped[date] = mapped_column(Date, nullable=False)
    descripcion: Mapped[str] = mapped_column(String(255), nullable=False, default="")
    activo: Mapped[bool] = mapped_column(Boolean, nullable=False, default=True)
    # UUID que une las dos piernas de una transferencia entre cuentas.
    grupo_transferencia: Mapped[str | None] = mapped_column(String(36), nullable=True, index=True)

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

    account: Mapped[Account] = relationship(back_populates="transactions")
    category: Mapped[Category] = relationship(back_populates="transactions")
    sub_category: Mapped[SubCategory] = relationship(back_populates="transactions")
    counterparty: Mapped[Counterparty | None] = relationship(back_populates="transactions")

    def __repr__(self) -> str:
        return (
            f"Transaction(id={self.id}, tipo={self.tipo!r}, "
            f"monto={self.monto}, activo={self.activo})"
        )
