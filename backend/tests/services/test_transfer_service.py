"""
Unit tests — transferencias entre cuentas.
"""

from datetime import date
from decimal import Decimal

import pytest
from fastapi import HTTPException

from app.schemas.transaction import TransferCreate
from app.services.transaction import TransactionService
from tests.helpers import make_account, make_category, make_sub_category, make_user

pytestmark = pytest.mark.unit


def test_transfer_moves_saldo_between_accounts(db_session):
    user = make_user(db_session)
    origen = make_account(db_session, user, banco="A", saldo=Decimal("200"))
    destino = make_account(db_session, user, banco="B", saldo=Decimal("50"))
    cat = make_category(db_session, nombre="Transferencias")
    sub = make_sub_category(db_session, cat, nombre="Entre mis cuentas")

    result = TransactionService.transfer(
        db_session,
        user,
        TransferCreate(
            from_account_id=origen.id,
            to_account_id=destino.id,
            monto=Decimal("30"),
            fecha=date(2026, 7, 12),
            category_id=cat.id,
            sub_category_id=sub.id,
        ),
    )

    db_session.refresh(origen)
    db_session.refresh(destino)
    assert origen.saldo == Decimal("170")
    assert destino.saldo == Decimal("80")
    assert result.salida.tipo == "transferencia_salida"
    assert result.entrada.tipo == "transferencia_entrada"
    assert result.salida.grupo_transferencia == result.entrada.grupo_transferencia


def test_deactivate_transfer_reverts_both_legs(db_session):
    user = make_user(db_session)
    origen = make_account(db_session, user, saldo=Decimal("200"))
    destino = make_account(db_session, user, banco="B", saldo=Decimal("50"))
    cat = make_category(db_session)
    sub = make_sub_category(db_session, cat)

    result = TransactionService.transfer(
        db_session,
        user,
        TransferCreate(
            from_account_id=origen.id,
            to_account_id=destino.id,
            monto=Decimal("25"),
            fecha=date(2026, 7, 12),
            category_id=cat.id,
            sub_category_id=sub.id,
        ),
    )
    TransactionService.deactivate(db_session, user, result.salida.id)
    db_session.refresh(origen)
    db_session.refresh(destino)

    assert origen.saldo == Decimal("200")
    assert destino.saldo == Decimal("50")
    with pytest.raises(HTTPException):
        TransactionService.get_mine(db_session, user, result.salida.id)
