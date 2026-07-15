"""
Schemas de Account.

- Create: `saldo_inicial` solo al abrir la cuenta (punto de partida contable).
- Update: NO permite editar saldo (solo movimientos lo cambian).
- Delete HTTP → desactivar (`activo=False`), historial intacto.
"""

from datetime import datetime
from decimal import Decimal

from pydantic import BaseModel, ConfigDict, Field


class AccountCreate(BaseModel):
    banco: str = Field(min_length=1, max_length=100)
    tipo: str = Field(min_length=1, max_length=100)
    moneda: str = Field(min_length=1, max_length=10)
    # Solo al crear: saldo de apertura. Después solo cambian las transacciones.
    saldo_inicial: Decimal = Field(default=Decimal("0.00"), ge=0)


class AccountUpdate(BaseModel):
    model_config = ConfigDict(extra="forbid")

    banco: str | None = Field(default=None, min_length=1, max_length=100)
    tipo: str | None = Field(default=None, min_length=1, max_length=100)
    moneda: str | None = Field(default=None, min_length=1, max_length=10)


class AccountResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    user_id: int
    banco: str
    tipo: str
    moneda: str
    saldo: Decimal
    activo: bool
    creado_en: datetime
    actualizado_en: datetime
