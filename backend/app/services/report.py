"""
app/services/report.py — Dashboard / estadísticas

Solo cuenta movimientos activos.
- gasto/ingreso = operativos
- transferencias se reportan aparte (no inflan gastos/ingresos del día a día)
"""

from __future__ import annotations

from calendar import monthrange
from datetime import date, timedelta
from decimal import Decimal

from fastapi import HTTPException, status
from sqlalchemy import extract, func, select
from sqlalchemy.orm import Session

from app.models.account import Account
from app.models.category import Category
from app.models.counterparty import Counterparty
from app.models.sub_category import SubCategory
from app.models.transaction import Transaction
from app.models.user import User
from app.repositories.account import AccountRepository
from app.schemas.report import (
    AccountSnapshot,
    CategoryBreakdown,
    CounterpartyBreakdown,
    MedioPagoBreakdown,
    MonthBucket,
    PeriodComparison,
    PeriodTotals,
    ReportSummary,
    SubCategoryBreakdown,
)
from app.services.budget import BudgetService


def _pct_change(current: Decimal, previous: Decimal) -> Decimal | None:
    if previous == 0:
        return None
    return ((current - previous) / previous * Decimal("100")).quantize(Decimal("0.01"))


def _resolve_comparison_windows(
    date_from: date | None,
    date_to: date | None,
    *,
    today: date | None = None,
) -> tuple[date, date, date, date]:
    """
    Current window + previous window of the same length.

    - Both filters set → use them; previous ends the day before date_from.
    - Otherwise → calendar month of `today` vs previous calendar month.
    """
    today = today or date.today()
    if date_from is not None and date_to is not None:
        if date_to < date_from:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="date_to debe ser >= date_from",
            )
        current_from, current_to = date_from, date_to
        span_days = (current_to - current_from).days + 1
        previous_to = current_from - timedelta(days=1)
        previous_from = previous_to - timedelta(days=span_days - 1)
        return current_from, current_to, previous_from, previous_to

    current_from = today.replace(day=1)
    current_to = today
    if today.month == 1:
        prev_year, prev_month = today.year - 1, 12
    else:
        prev_year, prev_month = today.year, today.month - 1
    previous_from = date(prev_year, prev_month, 1)
    previous_to = date(prev_year, prev_month, monthrange(prev_year, prev_month)[1])
    return current_from, current_to, previous_from, previous_to


class ReportService:
    @staticmethod
    def _operative_totals(
        db: Session,
        *,
        user_id: int,
        account_id: int | None,
        date_from: date | None,
        date_to: date | None,
    ) -> PeriodTotals:
        filters = [
            Account.user_id == user_id,
            Transaction.activo.is_(True),
            Transaction.tipo.in_(("gasto", "ingreso")),
        ]
        if account_id is not None:
            filters.append(Transaction.account_id == account_id)
        if date_from is not None:
            filters.append(Transaction.fecha >= date_from)
        if date_to is not None:
            filters.append(Transaction.fecha <= date_to)
        q = (
            select(Transaction.tipo, func.coalesce(func.sum(Transaction.monto), 0))
            .join(Account, Transaction.account_id == Account.id)
            .where(*filters)
            .group_by(Transaction.tipo)
        )
        totals = {row[0]: Decimal(str(row[1])) for row in db.execute(q).all()}
        ingresos = totals.get("ingreso", Decimal("0"))
        gastos = totals.get("gasto", Decimal("0"))
        return PeriodTotals(
            total_ingresos=ingresos,
            total_gastos=gastos,
            balance_neto=ingresos - gastos,
        )

    @staticmethod
    def summary(
        db: Session,
        current_user: User,
        *,
        account_id: int | None = None,
        date_from: date | None = None,
        date_to: date | None = None,
    ) -> ReportSummary:
        if account_id is not None:
            account = AccountRepository.get_by_id_for_user(
                db, account_id=account_id, user_id=current_user.id
            )
            if account is None:
                raise HTTPException(
                    status_code=status.HTTP_404_NOT_FOUND,
                    detail="Cuenta no encontrada",
                )
        if date_from is not None and date_to is not None and date_to < date_from:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="date_to debe ser >= date_from",
            )

        filters = [
            Account.user_id == current_user.id,
            Transaction.activo.is_(True),
        ]
        if account_id is not None:
            filters.append(Transaction.account_id == account_id)
        if date_from is not None:
            filters.append(Transaction.fecha >= date_from)
        if date_to is not None:
            filters.append(Transaction.fecha <= date_to)

        by_tipo = (
            select(Transaction.tipo, func.coalesce(func.sum(Transaction.monto), 0))
            .join(Account, Transaction.account_id == Account.id)
            .where(*filters)
            .group_by(Transaction.tipo)
        )
        totals = {row[0]: Decimal(str(row[1])) for row in db.execute(by_tipo).all()}
        total_ingresos = totals.get("ingreso", Decimal("0"))
        total_gastos = totals.get("gasto", Decimal("0"))
        total_transferencias = totals.get("transferencia_salida", Decimal("0"))

        def _breakdown(tipo: str) -> list[CategoryBreakdown]:
            q = (
                select(
                    Category.id,
                    Category.nombre,
                    func.coalesce(func.sum(Transaction.monto), 0),
                )
                .join(Transaction, Transaction.category_id == Category.id)
                .join(Account, Transaction.account_id == Account.id)
                .where(*filters, Transaction.tipo == tipo)
                .group_by(Category.id, Category.nombre)
                .order_by(func.sum(Transaction.monto).desc())
            )
            return [
                CategoryBreakdown(
                    category_id=row[0],
                    nombre=row[1],
                    total=Decimal(str(row[2])),
                    tipo=tipo,
                )
                for row in db.execute(q).all()
            ]

        def _sub_breakdown(tipo: str) -> list[SubCategoryBreakdown]:
            q = (
                select(
                    SubCategory.id,
                    SubCategory.category_id,
                    SubCategory.nombre,
                    Category.nombre,
                    func.coalesce(func.sum(Transaction.monto), 0),
                )
                .join(Transaction, Transaction.sub_category_id == SubCategory.id)
                .join(Category, SubCategory.category_id == Category.id)
                .join(Account, Transaction.account_id == Account.id)
                .where(*filters, Transaction.tipo == tipo)
                .group_by(
                    SubCategory.id,
                    SubCategory.category_id,
                    SubCategory.nombre,
                    Category.nombre,
                )
                .order_by(func.sum(Transaction.monto).desc())
            )
            return [
                SubCategoryBreakdown(
                    sub_category_id=row[0],
                    category_id=row[1],
                    nombre=row[2],
                    category_nombre=row[3],
                    total=Decimal(str(row[4])),
                    tipo=tipo,
                )
                for row in db.execute(q).all()
            ]

        medio_q = (
            select(
                Transaction.medio_pago,
                Transaction.tipo,
                func.coalesce(func.sum(Transaction.monto), 0),
                func.count(Transaction.id),
            )
            .join(Account, Transaction.account_id == Account.id)
            .where(*filters, Transaction.tipo.in_(("gasto", "ingreso")))
            .group_by(Transaction.medio_pago, Transaction.tipo)
        )
        medio_map: dict[str, dict[str, Decimal | int]] = {}
        for row in db.execute(medio_q).all():
            medio = row[0]
            bucket = medio_map.setdefault(
                medio,
                {
                    "ingreso": Decimal("0"),
                    "gasto": Decimal("0"),
                    "count": 0,
                },
            )
            bucket[row[1]] = Decimal(str(row[2]))
            bucket["count"] = int(bucket["count"]) + int(row[3])
        by_medio_pago = [
            MedioPagoBreakdown(
                medio_pago=medio,
                total_ingresos=Decimal(str(vals["ingreso"])),
                total_gastos=Decimal(str(vals["gasto"])),
                count=int(vals["count"]),
            )
            for medio, vals in sorted(medio_map.items())
        ]

        cp_q = (
            select(
                Counterparty.id,
                Counterparty.nombre,
                Transaction.tipo,
                func.coalesce(func.sum(Transaction.monto), 0),
                func.count(Transaction.id),
            )
            .join(Transaction, Transaction.contraparte_id == Counterparty.id)
            .join(Account, Transaction.account_id == Account.id)
            .where(
                *filters,
                Transaction.contraparte_id.is_not(None),
                Transaction.tipo.in_(("gasto", "ingreso")),
            )
            .group_by(Counterparty.id, Counterparty.nombre, Transaction.tipo)
        )
        cp_map: dict[int, dict[str, Decimal | int | str]] = {}
        for row in db.execute(cp_q).all():
            cp_id = int(row[0])
            bucket = cp_map.setdefault(
                cp_id,
                {
                    "nombre": row[1],
                    "ingreso": Decimal("0"),
                    "gasto": Decimal("0"),
                    "count": 0,
                },
            )
            bucket[row[2]] = Decimal(str(row[3]))
            bucket["count"] = int(bucket["count"]) + int(row[4])
        by_counterparty = sorted(
            [
                CounterpartyBreakdown(
                    contraparte_id=cp_id,
                    nombre=str(vals["nombre"]),
                    total_gastos=Decimal(str(vals["gasto"])),
                    total_ingresos=Decimal(str(vals["ingreso"])),
                    count=int(vals["count"]),
                )
                for cp_id, vals in cp_map.items()
            ],
            key=lambda item: (item.total_gastos + item.total_ingresos),
            reverse=True,
        )[:10]

        month_q = (
            select(
                extract("year", Transaction.fecha).label("y"),
                extract("month", Transaction.fecha).label("m"),
                Transaction.tipo,
                func.coalesce(func.sum(Transaction.monto), 0),
            )
            .join(Account, Transaction.account_id == Account.id)
            .where(*filters, Transaction.tipo.in_(("gasto", "ingreso")))
            .group_by("y", "m", Transaction.tipo)
            .order_by("y", "m")
        )
        month_map: dict[tuple[int, int], dict[str, Decimal]] = {}
        for row in db.execute(month_q).all():
            key = (int(row[0]), int(row[1]))
            month_map.setdefault(key, {"ingreso": Decimal("0"), "gasto": Decimal("0")})
            month_map[key][row[2]] = Decimal(str(row[3]))
        by_month = [
            MonthBucket(
                year=y,
                month=m,
                total_ingresos=vals.get("ingreso", Decimal("0")),
                total_gastos=vals.get("gasto", Decimal("0")),
                balance_neto=vals.get("ingreso", Decimal("0"))
                - vals.get("gasto", Decimal("0")),
            )
            for (y, m), vals in month_map.items()
        ]

        accounts = AccountRepository.list_filtered(
            db, user_id=current_user.id, only_active=False, limit=10_000, offset=0
        )[0]
        by_account: list[AccountSnapshot] = []
        for acc in accounts:
            if account_id is not None and acc.id != account_id:
                continue
            acc_filters = [
                Transaction.account_id == acc.id,
                Transaction.activo.is_(True),
                Transaction.tipo.in_(("gasto", "ingreso")),
            ]
            if date_from is not None:
                acc_filters.append(Transaction.fecha >= date_from)
            if date_to is not None:
                acc_filters.append(Transaction.fecha <= date_to)
            acc_q = (
                select(Transaction.tipo, func.coalesce(func.sum(Transaction.monto), 0))
                .where(*acc_filters)
                .group_by(Transaction.tipo)
            )
            acc_totals = {r[0]: Decimal(str(r[1])) for r in db.execute(acc_q).all()}
            by_account.append(
                AccountSnapshot(
                    account_id=acc.id,
                    banco=acc.banco,
                    moneda=acc.moneda,
                    saldo=Decimal(str(acc.saldo)),
                    activo=acc.activo,
                    total_ingresos=acc_totals.get("ingreso", Decimal("0")),
                    total_gastos=acc_totals.get("gasto", Decimal("0")),
                )
            )

        cur_from, cur_to, prev_from, prev_to = _resolve_comparison_windows(
            date_from, date_to
        )
        current_totals = ReportService._operative_totals(
            db,
            user_id=current_user.id,
            account_id=account_id,
            date_from=cur_from,
            date_to=cur_to,
        )
        previous_totals = ReportService._operative_totals(
            db,
            user_id=current_user.id,
            account_id=account_id,
            date_from=prev_from,
            date_to=prev_to,
        )
        period_comparison = PeriodComparison(
            current_from=cur_from,
            current_to=cur_to,
            previous_from=prev_from,
            previous_to=prev_to,
            current=current_totals,
            previous=previous_totals,
            ingresos_delta=current_totals.total_ingresos - previous_totals.total_ingresos,
            gastos_delta=current_totals.total_gastos - previous_totals.total_gastos,
            balance_neto_delta=current_totals.balance_neto - previous_totals.balance_neto,
            ingresos_change_pct=_pct_change(
                current_totals.total_ingresos, previous_totals.total_ingresos
            ),
            gastos_change_pct=_pct_change(
                current_totals.total_gastos, previous_totals.total_gastos
            ),
        )

        return ReportSummary(
            total_ingresos=total_ingresos,
            total_gastos=total_gastos,
            balance_neto=total_ingresos - total_gastos,
            total_transferencias=total_transferencias,
            by_category_gastos=_breakdown("gasto"),
            by_category_ingresos=_breakdown("ingreso"),
            by_subcategory_gastos=_sub_breakdown("gasto"),
            by_subcategory_ingresos=_sub_breakdown("ingreso"),
            by_medio_pago=by_medio_pago,
            by_counterparty=by_counterparty,
            by_month=by_month,
            by_account=by_account,
            budgets_status=BudgetService.list_status(db, current_user),
            period_comparison=period_comparison,
            date_from=date_from,
            date_to=date_to,
            account_id=account_id,
        )
