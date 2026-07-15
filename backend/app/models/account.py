"""
Modelo Account → tabla `accounts`.

Principio contable:
  - `saldo` solo cambia por transacciones (ingreso/gasto/transferencia).
  - No se borra la cuenta: se desactiva (`activo=False`) y el historial permanece.
"""

from __future__ import annotations

from datetime import datetime
from decimal import Decimal
from typing import TYPE_CHECKING

from sqlalchemy import Boolean, DateTime, ForeignKey, Numeric, String, func
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db.base import Base

if TYPE_CHECKING:
    from app.models.transaction import Transaction
    from app.models.user import User


class Account(Base):
    __tablename__ = "accounts"

    id: Mapped[int] = mapped_column(primary_key=True, autoincrement=True)
    user_id: Mapped[int] = mapped_column(ForeignKey("users.id"), nullable=False, index=True)

    banco: Mapped[str] = mapped_column(String(100), nullable=False)
    tipo: Mapped[str] = mapped_column(String(100), nullable=False)
    moneda: Mapped[str] = mapped_column(String(10), nullable=False)
    saldo: Mapped[Decimal] = mapped_column(Numeric(14, 2), nullable=False, default=Decimal("0.00"))
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

    # Sin cascade delete-orphan: el historial de movimientos no se borra con la cuenta.
    user: Mapped[User] = relationship(back_populates="accounts")
    transactions: Mapped[list[Transaction]] = relationship(back_populates="account")

    def __repr__(self) -> str:
        return (
            f"Account(id={self.id}, banco={self.banco!r}, "
            f"saldo={self.saldo}, activo={self.activo})"
        )
