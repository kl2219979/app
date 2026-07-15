"""
Unit tests — TransactionService (reglas de negocio críticas).

Prioridad alta: ownership de cuenta + coherencia categoría/subcategoría.
"""

from datetime import date
from decimal import Decimal

import pytest
from fastapi import HTTPException

from app.schemas.transaction import TransactionCreate, TransactionUpdate
from app.services.transaction import TransactionService
from tests.helpers import (
    make_account,
    make_category,
    make_sub_category,
    make_transaction,
    make_user,
)

pytestmark = pytest.mark.unit


def _create_payload(account_id: int, category_id: int, sub_category_id: int) -> TransactionCreate:
    return TransactionCreate(
        account_id=account_id,
        category_id=category_id,
        sub_category_id=sub_category_id,
        monto=Decimal("40.00"),
        fecha=date(2026, 7, 10),
        descripcion="Compra",
    )


def test_create_happy_path(db_session):
    # Arrange
    user = make_user(db_session)
    account = make_account(db_session, user)
    category = make_category(db_session)
    sub = make_sub_category(db_session, category)
    data = _create_payload(account.id, category.id, sub.id)

    # Act
    item = TransactionService.create(db_session, user, data)

    # Assert
    assert item.id is not None
    assert item.account_id == account.id
    assert item.monto == Decimal("40.00")


def test_create_rejects_foreign_account(db_session):
    # Arrange
    owner = make_user(db_session, correo="a@x.com", usuario="owner")
    other = make_user(db_session, correo="b@x.com", usuario="other")
    foreign_account = make_account(db_session, other)
    category = make_category(db_session)
    sub = make_sub_category(db_session, category)
    data = _create_payload(foreign_account.id, category.id, sub.id)

    # Act / Assert
    with pytest.raises(HTTPException) as exc:
        TransactionService.create(db_session, owner, data)
    assert exc.value.status_code == 404
    assert "Cuenta" in exc.value.detail


def test_create_rejects_mismatched_subcategory(db_session):
    # Arrange
    user = make_user(db_session)
    account = make_account(db_session, user)
    cat_a = make_category(db_session, nombre="A")
    cat_b = make_category(db_session, nombre="B")
    sub_of_b = make_sub_category(db_session, cat_b, nombre="SubB")
    data = _create_payload(account.id, cat_a.id, sub_of_b.id)

    # Act / Assert
    with pytest.raises(HTTPException) as exc:
        TransactionService.create(db_session, user, data)
    assert exc.value.status_code == 400
    assert "subcategoría" in exc.value.detail.lower()


def test_create_rejects_missing_category(db_session):
    # Arrange
    user = make_user(db_session)
    account = make_account(db_session, user)
    category = make_category(db_session)
    sub = make_sub_category(db_session, category)
    data = _create_payload(account.id, 999, sub.id)

    # Act / Assert
    with pytest.raises(HTTPException) as exc:
        TransactionService.create(db_session, user, data)
    assert exc.value.status_code == 404


def test_list_and_get_only_own(db_session):
    # Arrange
    owner = make_user(db_session, correo="a@x.com", usuario="owner")
    other = make_user(db_session, correo="b@x.com", usuario="other")
    cat = make_category(db_session)
    sub = make_sub_category(db_session, cat)
    mine_acc = make_account(db_session, owner)
    other_acc = make_account(db_session, other)
    mine_tx = make_transaction(db_session, account=mine_acc, category=cat, sub_category=sub)
    foreign_tx = make_transaction(
        db_session,
        account=other_acc,
        category=cat,
        sub_category=sub,
        descripcion="Ajena",
    )

    # Act
    page = TransactionService.list_mine(db_session, owner)

    # Assert
    assert [t.id for t in page.items] == [mine_tx.id]
    assert page.total == 1
    with pytest.raises(HTTPException) as exc:
        TransactionService.get_mine(db_session, owner, foreign_tx.id)
    assert exc.value.status_code == 404


def test_create_gasto_decreases_saldo_and_ingreso_increases(db_session):
    # Arrange
    user = make_user(db_session)
    account = make_account(db_session, user, saldo=Decimal("100.00"))
    category = make_category(db_session)
    sub = make_sub_category(db_session, category)

    # Act — gasto
    TransactionService.create(
        db_session,
        user,
        TransactionCreate(
            account_id=account.id,
            category_id=category.id,
            sub_category_id=sub.id,
            monto=Decimal("30.00"),
            tipo="gasto",
            fecha=date(2026, 7, 10),
            descripcion="Gasto",
        ),
    )
    db_session.refresh(account)

    # Assert
    assert account.saldo == Decimal("70.00")

    # Act — ingreso
    TransactionService.create(
        db_session,
        user,
        TransactionCreate(
            account_id=account.id,
            category_id=category.id,
            sub_category_id=sub.id,
            monto=Decimal("15.00"),
            tipo="ingreso",
            fecha=date(2026, 7, 10),
            descripcion="Ingreso",
        ),
    )
    db_session.refresh(account)
    assert account.saldo == Decimal("85.00")


def test_delete_restores_saldo(db_session):
    # Arrange
    user = make_user(db_session)
    account = make_account(db_session, user, saldo=Decimal("100.00"))
    category = make_category(db_session)
    sub = make_sub_category(db_session, category)
    tx = TransactionService.create(
        db_session,
        user,
        TransactionCreate(
            account_id=account.id,
            category_id=category.id,
            sub_category_id=sub.id,
            monto=Decimal("40.00"),
            tipo="gasto",
            fecha=date(2026, 7, 10),
            descripcion="Temporal",
        ),
    )

    # Act
    TransactionService.deactivate(db_session, user, tx.id)
    db_session.refresh(account)

    # Assert
    assert account.saldo == Decimal("100.00")


def test_list_filters_by_tipo_and_pagination(db_session):
    # Arrange
    user = make_user(db_session)
    account = make_account(db_session, user, saldo=Decimal("1000"))
    category = make_category(db_session)
    sub = make_sub_category(db_session, category)
    for i in range(3):
        TransactionService.create(
            db_session,
            user,
            TransactionCreate(
                account_id=account.id,
                category_id=category.id,
                sub_category_id=sub.id,
                monto=Decimal("10.00"),
                tipo="gasto",
                fecha=date(2026, 7, i + 1),
                descripcion=f"g{i}",
            ),
        )
    TransactionService.create(
        db_session,
        user,
        TransactionCreate(
            account_id=account.id,
            category_id=category.id,
            sub_category_id=sub.id,
            monto=Decimal("50.00"),
            tipo="ingreso",
            fecha=date(2026, 7, 15),
            descripcion="sueldo",
        ),
    )

    # Act
    gastos = TransactionService.list_mine(db_session, user, tipo="gasto", limit=2, offset=0)
    page2 = TransactionService.list_mine(db_session, user, tipo="gasto", limit=2, offset=2)

    # Assert
    assert gastos.total == 3
    assert len(gastos.items) == 2
    assert page2.total == 3
    assert len(page2.items) == 1


def test_update_revalidates_category_pair(db_session):
    # Arrange
    user = make_user(db_session)
    account = make_account(db_session, user)
    cat_a = make_category(db_session, nombre="A")
    cat_b = make_category(db_session, nombre="B")
    sub_a = make_sub_category(db_session, cat_a, nombre="SubA")
    sub_b = make_sub_category(db_session, cat_b, nombre="SubB")
    tx = make_transaction(db_session, account=account, category=cat_a, sub_category=sub_a)

    # Act / Assert — category B + sub A → 400
    with pytest.raises(HTTPException) as exc:
        TransactionService.update(
            db_session,
            user,
            tx.id,
            TransactionUpdate(category_id=cat_b.id, sub_category_id=sub_a.id),
        )
    assert exc.value.status_code == 400

    # Act — pair coherente
    updated = TransactionService.update(
        db_session,
        user,
        tx.id,
        TransactionUpdate(category_id=cat_b.id, sub_category_id=sub_b.id, monto=Decimal("99")),
    )

    # Assert
    assert updated.category_id == cat_b.id
    assert updated.sub_category_id == sub_b.id
    assert updated.monto == Decimal("99")


def test_delete_own_transaction(db_session):
    # Arrange
    user = make_user(db_session)
    account = make_account(db_session, user)
    cat = make_category(db_session)
    sub = make_sub_category(db_session, cat)
    tx = make_transaction(db_session, account=account, category=cat, sub_category=sub)

    # Act
    TransactionService.deactivate(db_session, user, tx.id)

    # Assert
    with pytest.raises(HTTPException) as exc:
        TransactionService.get_mine(db_session, user, tx.id)
    assert exc.value.status_code == 404
