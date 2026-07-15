"""Unit/API smoke — export CSV/JSON."""

from datetime import date
from decimal import Decimal

import pytest

from app.schemas.transaction import TransactionCreate
from app.services.export import ExportService
from app.services.transaction import TransactionService
from tests.helpers import make_account, make_category, make_sub_category, make_user

pytestmark = pytest.mark.unit


def test_export_json_and_csv(db_session):
    user = make_user(db_session)
    account = make_account(db_session, user, saldo=Decimal("200"))
    category = make_category(db_session)
    sub = make_sub_category(db_session, category)
    TransactionService.create(
        db_session,
        user,
        TransactionCreate(
            account_id=account.id,
            category_id=category.id,
            sub_category_id=sub.id,
            monto=Decimal("25"),
            tipo="gasto",
            fecha=date(2026, 7, 10),
        ),
    )

    json_resp = ExportService.export_transactions(db_session, user, fmt="json")
    assert json_resp.media_type.startswith("application/json")
    assert b'"total": 1' in json_resp.body

    csv_resp = ExportService.export_transactions(db_session, user, fmt="csv")
    assert "text/csv" in csv_resp.media_type
