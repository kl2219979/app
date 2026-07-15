"""
Modelo Counterparty → tabla `counterparties`.

Agenda de terceros (personas/cuentas fuera del sistema).
Un gasto/ingreso puede referenciar una contraparte sin que exista Account ajena.
"""

from __future__ import annotations

from datetime import datetime
from typing import TYPE_CHECKING

from sqlalchemy import Boolean, DateTime, ForeignKey, String, Text, func
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db.base import Base

if TYPE_CHECKING:
    from app.models.transaction import Transaction
    from app.models.user import User


class Counterparty(Base):
    __tablename__ = "counterparties"

    id: Mapped[int] = mapped_column(primary_key=True, autoincrement=True)
    user_id: Mapped[int] = mapped_column(ForeignKey("users.id"), nullable=False, index=True)

    nombre: Mapped[str] = mapped_column(String(150), nullable=False)
    banco: Mapped[str | None] = mapped_column(String(100), nullable=True)
    numero_cuenta: Mapped[str | None] = mapped_column(String(100), nullable=True)
    notas: Mapped[str | None] = mapped_column(Text, nullable=True)
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

    user: Mapped[User] = relationship(back_populates="counterparties")
    transactions: Mapped[list[Transaction]] = relationship(back_populates="counterparty")

    def __repr__(self) -> str:
        return (
            f"Counterparty(id={self.id}, nombre={self.nombre!r}, "
            f"activo={self.activo})"
        )
