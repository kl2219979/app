"""Schemas Pydantic del recurso Budget (presupuesto mensual por categoría)."""

from datetime import datetime
from decimal import Decimal
from typing import Literal

from pydantic import BaseModel, ConfigDict, Field

BudgetPeriodo = Literal["mensual"]


class BudgetCreate(BaseModel):
    category_id: int = Field(gt=0)
    limite: Decimal = Field(gt=0)
    moneda: str = Field(default="COP", min_length=1, max_length=10)
    periodo: BudgetPeriodo = "mensual"


class BudgetUpdate(BaseModel):
    model_config = ConfigDict(extra="forbid")

    limite: Decimal | None = Field(default=None, gt=0)
    moneda: str | None = Field(default=None, min_length=1, max_length=10)


class BudgetResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    user_id: int
    category_id: int
    limite: Decimal
    moneda: str
    periodo: str
    activo: bool
    creado_en: datetime
    actualizado_en: datetime


class BudgetStatus(BaseModel):
    """Presupuesto + consumo del mes calendario en curso."""

    budget_id: int
    category_id: int
    category_nombre: str
    limite: Decimal
    moneda: str
    periodo: str
    gastado: Decimal
    restante: Decimal
    pct_usado: Decimal
    excedido: bool
    period_from: str  # ISO date
    period_to: str
