"""Unit — filtros de listado de transacciones."""

from datetime import date
from decimal import Decimal

import pytest

from app.schemas.transaction import TransactionCreate
from app.services.transaction import TransactionService
from tests.helpers import (
    make_account,
    make_category,
    make_counterparty,
    make_sub_category,
    make_user,
)

pytestmark = pytest.mark.unit


def test_list_filters_medio_pago_subcategory_and_contraparte(db_session):
    user = make_user(db_session)
    account = make_account(db_session, user, saldo=Decimal("500"))
    category = make_category(db_session)
    sub = make_sub_category(db_session, category)
    cp = make_counterparty(db_session, user)

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
        ),
    )
    TransactionService.create(
        db_session,
        user,
        TransactionCreate(
            account_id=account.id,
            category_id=category.id,
            sub_category_id=sub.id,
            monto=Decimal("20"),
            tipo="gasto",
            contraparte_id=cp.id,
            fecha=date(2026, 7, 2),
        ),
    )
    TransactionService.create(
        db_session,
        user,
        TransactionCreate(
            category_id=category.id,
            sub_category_id=sub.id,
            monto=Decimal("50"),
            tipo="ingreso",
            medio_pago="efectivo",
            moneda="COP",
            fecha=date(2026, 7, 3),
        ),
    )
    TransactionService.create(
        db_session,
        user,
        TransactionCreate(
            category_id=category.id,
            sub_category_id=sub.id,
            monto=Decimal("10"),
            tipo="gasto",
            medio_pago="efectivo",
            moneda="COP",
            fecha=date(2026, 7, 4),
        ),
    )

    cash = TransactionService.list_mine(
        db_session, user, medio_pago="efectivo", limit=50
    )
    assert cash.total == 2
    assert all(i.medio_pago == "efectivo" for i in cash.items)
    # stable order: newest first
    assert cash.items[0].fecha >= cash.items[1].fecha

    by_cp = TransactionService.list_mine(
        db_session, user, contraparte_id=cp.id, limit=50
    )
    assert by_cp.total == 1
    assert by_cp.items[0].contraparte_id == cp.id

    by_sub = TransactionService.list_mine(
        db_session, user, sub_category_id=sub.id, limit=50
    )
    assert by_sub.total == 4
