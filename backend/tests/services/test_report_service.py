"""
Unit tests — ReportService (agregados).
"""

from datetime import date
from decimal import Decimal

import pytest

from app.schemas.transaction import TransactionCreate, TransferCreate
from app.services.report import ReportService
from app.services.transaction import TransactionService
from tests.helpers import make_account, make_category, make_sub_category, make_user

pytestmark = pytest.mark.unit


def test_summary_separates_gastos_ingresos_and_ignores_transfers_in_totals(db_session):
    user = make_user(db_session)
    account = make_account(db_session, user, saldo=Decimal("1000"))
    other = make_account(db_session, user, banco="Otra", saldo=Decimal("100"))
    category = make_category(db_session)
    sub = make_sub_category(db_session, category)

    TransactionService.create(
        db_session,
        user,
        TransactionCreate(
            account_id=account.id,
            category_id=category.id,
            sub_category_id=sub.id,
            monto=Decimal("100"),
            tipo="ingreso",
            fecha=date(2026, 7, 1),
            descripcion="sueldo",
        ),
    )
    TransactionService.create(
        db_session,
        user,
        TransactionCreate(
            account_id=account.id,
            category_id=category.id,
            sub_category_id=sub.id,
            monto=Decimal("40"),
            tipo="gasto",
            fecha=date(2026, 7, 2),
            descripcion="compra",
        ),
    )
    TransactionService.transfer(
        db_session,
        user,
        TransferCreate(
            from_account_id=account.id,
            to_account_id=other.id,
            monto=Decimal("10"),
            fecha=date(2026, 7, 3),
            category_id=category.id,
            sub_category_id=sub.id,
        ),
    )

    summary = ReportService.summary(db_session, user)

    assert summary.total_ingresos == Decimal("100")
    assert summary.total_gastos == Decimal("40")
    assert summary.balance_neto == Decimal("60")
    assert summary.total_transferencias == Decimal("10")
    assert len(summary.by_category_gastos) == 1
    assert summary.by_category_gastos[0].total == Decimal("40")
    assert len(summary.by_category_ingresos) == 1
    assert summary.by_category_ingresos[0].total == Decimal("100")
    assert len(summary.by_subcategory_gastos) == 1
    assert summary.by_subcategory_gastos[0].nombre == sub.nombre
    assert summary.by_medio_pago
    assert any(m.medio_pago == "cuenta" for m in summary.by_medio_pago)
    assert summary.period_comparison.current_from <= summary.period_comparison.current_to
    assert len(summary.by_month) >= 1
    assert len(summary.by_account) == 2


def test_summary_includes_counterparty_and_period_comparison(db_session):
    from tests.helpers import make_counterparty

    user = make_user(db_session)
    account = make_account(db_session, user, saldo=Decimal("500"))
    category = make_category(db_session)
    sub = make_sub_category(db_session, category)
    cp = make_counterparty(db_session, user, nombre="Tienda X")

    TransactionService.create(
        db_session,
        user,
        TransactionCreate(
            account_id=account.id,
            category_id=category.id,
            sub_category_id=sub.id,
            monto=Decimal("200"),
            tipo="ingreso",
            fecha=date(2026, 6, 10),
        ),
    )
    TransactionService.create(
        db_session,
        user,
        TransactionCreate(
            account_id=account.id,
            category_id=category.id,
            sub_category_id=sub.id,
            monto=Decimal("30"),
            tipo="gasto",
            fecha=date(2026, 7, 5),
            contraparte_id=cp.id,
        ),
    )

    summary = ReportService.summary(
        db_session,
        user,
        date_from=date(2026, 7, 1),
        date_to=date(2026, 7, 31),
    )

    assert summary.total_gastos == Decimal("30")
    assert summary.by_counterparty
    assert summary.by_counterparty[0].nombre == "Tienda X"
    assert summary.by_counterparty[0].total_gastos == Decimal("30")
    assert summary.period_comparison.current_from == date(2026, 7, 1)
    assert summary.period_comparison.current_to == date(2026, 7, 31)
    assert summary.period_comparison.previous_from == date(2026, 5, 31)
    assert summary.period_comparison.previous_to == date(2026, 6, 30)
    assert summary.period_comparison.previous.total_ingresos == Decimal("200")
