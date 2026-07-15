"""
Unit tests — AccountService (reglas de ownership por JWT).
"""

from decimal import Decimal

import pytest
from fastapi import HTTPException

from app.schemas.account import AccountCreate, AccountUpdate
from app.services.account import AccountService
from tests.helpers import make_account, make_user

pytestmark = pytest.mark.unit


def test_create_assigns_current_user(db_session):
    # Arrange
    user = make_user(db_session)
    data = AccountCreate(
        banco="Nequi",
        tipo="digital",
        moneda="COP",
        saldo_inicial=Decimal("10.00"),
    )

    # Act
    account = AccountService.create(db_session, user, data)

    # Assert
    assert account.id is not None
    assert account.user_id == user.id
    assert account.banco == "Nequi"


def test_list_mine_only_own_accounts(db_session):
    # Arrange
    owner = make_user(db_session, correo="a@x.com", usuario="owner")
    other = make_user(db_session, correo="b@x.com", usuario="other")
    mine = make_account(db_session, owner, banco="Mia")
    make_account(db_session, other, banco="Ajena")

    # Act
    result = AccountService.list_mine(db_session, owner)

    # Assert
    assert result.total == 1
    assert len(result.items) == 1
    assert result.items[0].id == mine.id


def test_get_mine_raises_404_for_foreign_account(db_session):
    # Arrange
    owner = make_user(db_session, correo="a@x.com", usuario="owner")
    other = make_user(db_session, correo="b@x.com", usuario="other")
    foreign = make_account(db_session, other)

    # Act / Assert
    with pytest.raises(HTTPException) as exc:
        AccountService.get_mine(db_session, owner, foreign.id)
    assert exc.value.status_code == 404


def test_update_and_delete_own_account(db_session):
    # Arrange
    user = make_user(db_session)
    account = make_account(db_session, user, banco="Viejo")

    # Act
    updated = AccountService.update(
        db_session,
        user,
        account.id,
        AccountUpdate(banco="Nuevo"),
    )
    AccountService.deactivate(db_session, user, account.id)

    # Assert
    assert updated.banco == "Nuevo"
    found = AccountService.get_mine(db_session, user, account.id)
    assert found.activo is False


def test_create_rejects_manual_cash_wallet(db_session):
    user = make_user(db_session)
    with pytest.raises(HTTPException) as exc:
        AccountService.create(
            db_session,
            user,
            AccountCreate(
                banco="Efectivo",
                tipo="efectivo",
                moneda="COP",
                saldo_inicial=Decimal("0"),
            ),
        )
    assert exc.value.status_code == 400
    assert "efectivo" in exc.value.detail.lower()
