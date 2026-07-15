"""Unit — BudgetService (presupuestos mensuales)."""

from datetime import date
from decimal import Decimal

import pytest
from fastapi import HTTPException

from app.schemas.budget import BudgetCreate
from app.schemas.transaction import TransactionCreate
from app.services.budget import BudgetService
from app.services.transaction import TransactionService
from tests.helpers import make_account, make_category, make_sub_category, make_user

pytestmark = pytest.mark.unit


def test_create_budget_and_status_tracks_month_spend(db_session):
    user = make_user(db_session)
    account = make_account(db_session, user, saldo=Decimal("1000"))
    category = make_category(db_session, nombre="Comida")
    sub = make_sub_category(db_session, category)
    budget = BudgetService.create(
        db_session,
        user,
        BudgetCreate(category_id=category.id, limite=Decimal("100")),
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
            fecha=date(2026, 7, 10),
        ),
    )

    status = BudgetService.to_status(db_session, budget, today=date(2026, 7, 15))
    assert status.limite == Decimal("100")
    assert status.gastado == Decimal("40")
    assert status.restante == Decimal("60")
    assert status.pct_usado == Decimal("40.00")
    assert status.excedido is False
    assert status.period_from == "2026-07-01"
    assert status.period_to == "2026-07-31"


def test_create_budget_conflict_same_category(db_session):
    user = make_user(db_session)
    category = make_category(db_session)
    BudgetService.create(
        db_session, user, BudgetCreate(category_id=category.id, limite=Decimal("50"))
    )
    with pytest.raises(HTTPException) as exc:
        BudgetService.create(
            db_session,
            user,
            BudgetCreate(category_id=category.id, limite=Decimal("80")),
        )
    assert exc.value.status_code == 409
