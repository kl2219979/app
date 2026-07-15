"""
Unit tests — TransactionRepository (join por Account.user_id).
"""

import pytest

from app.repositories.transaction import TransactionRepository
from tests.helpers import (
    make_account,
    make_category,
    make_sub_category,
    make_transaction,
    make_user,
)

pytestmark = pytest.mark.unit


def test_list_by_user_via_account_join(db_session):
    # Arrange
    owner = make_user(db_session, correo="a@x.com", usuario="a")
    other = make_user(db_session, correo="b@x.com", usuario="b")
    cat = make_category(db_session)
    sub = make_sub_category(db_session, cat)
    mine = make_transaction(
        db_session,
        account=make_account(db_session, owner),
        category=cat,
        sub_category=sub,
    )
    make_transaction(
        db_session,
        account=make_account(db_session, other),
        category=cat,
        sub_category=sub,
        descripcion="Ajena",
    )

    # Act
    listed = TransactionRepository.list_by_user(db_session, owner.id)

    # Assert
    assert [t.id for t in listed] == [mine.id]


def test_get_by_id_for_user(db_session):
    # Arrange
    owner = make_user(db_session, correo="a@x.com", usuario="a")
    other = make_user(db_session, correo="b@x.com", usuario="b")
    cat = make_category(db_session)
    sub = make_sub_category(db_session, cat)
    tx = make_transaction(
        db_session,
        account=make_account(db_session, owner),
        category=cat,
        sub_category=sub,
    )

    # Act / Assert
    assert (
        TransactionRepository.get_by_id_for_user(
            db_session, transaction_id=tx.id, user_id=owner.id
        )
        is not None
    )
    assert (
        TransactionRepository.get_by_id_for_user(
            db_session, transaction_id=tx.id, user_id=other.id
        )
        is None
    )


def test_list_by_account(db_session):
    # Arrange
    user = make_user(db_session)
    account = make_account(db_session, user)
    other_account = make_account(db_session, user, banco="Otra")
    cat = make_category(db_session)
    sub = make_sub_category(db_session, cat)
    tx = make_transaction(db_session, account=account, category=cat, sub_category=sub)
    make_transaction(
        db_session,
        account=other_account,
        category=cat,
        sub_category=sub,
        descripcion="Otra cuenta",
    )

    # Act
    listed = TransactionRepository.list_by_account(db_session, account.id)

    # Assert
    assert [t.id for t in listed] == [tx.id]
