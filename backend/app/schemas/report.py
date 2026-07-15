"""Schemas de reportes / dashboard (solo movimientos activos)."""

from datetime import date
from decimal import Decimal

from pydantic import BaseModel, Field

from app.schemas.budget import BudgetStatus


class CategoryBreakdown(BaseModel):
    category_id: int
    nombre: str
    total: Decimal
    tipo: str  # gasto | ingreso


class SubCategoryBreakdown(BaseModel):
    sub_category_id: int
    category_id: int
    nombre: str
    category_nombre: str
    total: Decimal
    tipo: str  # gasto | ingreso


class MedioPagoBreakdown(BaseModel):
    medio_pago: str  # cuenta | efectivo
    total_ingresos: Decimal
    total_gastos: Decimal
    count: int


class CounterpartyBreakdown(BaseModel):
    contraparte_id: int
    nombre: str
    total_gastos: Decimal
    total_ingresos: Decimal
    count: int


class MonthBucket(BaseModel):
    year: int
    month: int
    total_ingresos: Decimal
    total_gastos: Decimal
    balance_neto: Decimal


class AccountSnapshot(BaseModel):
    account_id: int
    banco: str
    moneda: str
    saldo: Decimal
    activo: bool
    total_ingresos: Decimal
    total_gastos: Decimal


class PeriodTotals(BaseModel):
    total_ingresos: Decimal = Field(ge=0)
    total_gastos: Decimal = Field(ge=0)
    balance_neto: Decimal


class PeriodComparison(BaseModel):
    """Comparativa del periodo actual vs el inmediatamente anterior (misma longitud)."""

    current_from: date
    current_to: date
    previous_from: date
    previous_to: date
    current: PeriodTotals
    previous: PeriodTotals
    ingresos_delta: Decimal
    gastos_delta: Decimal
    balance_neto_delta: Decimal
    ingresos_change_pct: Decimal | None = None
    gastos_change_pct: Decimal | None = None


class ReportSummary(BaseModel):
    total_ingresos: Decimal = Field(ge=0)
    total_gastos: Decimal = Field(ge=0)
    balance_neto: Decimal
    total_transferencias: Decimal = Field(ge=0)
    by_category_gastos: list[CategoryBreakdown]
    by_category_ingresos: list[CategoryBreakdown]
    by_subcategory_gastos: list[SubCategoryBreakdown]
    by_subcategory_ingresos: list[SubCategoryBreakdown]
    by_medio_pago: list[MedioPagoBreakdown]
    by_counterparty: list[CounterpartyBreakdown]
    by_month: list[MonthBucket]
    by_account: list[AccountSnapshot]
    budgets_status: list[BudgetStatus]
    period_comparison: PeriodComparison
    date_from: date | None = None
    date_to: date | None = None
    account_id: int | None = None
