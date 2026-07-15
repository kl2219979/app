"""
Unit tests — medio_pago efectivo + contraparte en TransactionService.
"""

from datetime import date
from decimal import Decimal

import pytest
from fastapi import HTTPException
from pydantic import ValidationError

from app.repositories.account import CASH_TIPO, AccountRepository
from app.schemas.transaction import TransactionCreate, TransferCreate
from app.services.transaction import TransactionService
from tests.helpers import (
    make_account,
    make_category,
    make_counterparty,
    make_sub_category,
    make_user,
)

pytestmark = pytest.mark.unit


def test_create_with_counterparty(db_session):
    user = make_user(db_session)
    account = make_account(db_session, user, saldo=Decimal("100"))
    category = make_category(db_session)
    sub = make_sub_category(db_session, category)
    cp = make_counterparty(db_session, user)

    item = TransactionService.create(
        db_session,
        user,
        TransactionCreate(
            account_id=account.id,
            category_id=category.id,
            sub_category_id=sub.id,
            monto=Decimal("20"),
            tipo="gasto",
            fecha=date(2026, 7, 13),
            contraparte_id=cp.id,
            descripcion="Pago a tercero",
        ),
    )

    db_session.refresh(account)
    assert item.contraparte_id == cp.id
    assert item.medio_pago == "cuenta"
    assert account.saldo == Decimal("80")


def test_create_rejects_foreign_or_inactive_counterparty(db_session):
    owner = make_user(db_session, correo="a@x.com", usuario="owner")
    other = make_user(db_session, correo="b@x.com", usuario="other")
    account = make_account(db_session, owner)
    category = make_category(db_session)
    sub = make_sub_category(db_session, category)
    foreign = make_counterparty(db_session, other)
    inactive = make_counterparty(db_session, owner, nombre="Inactiva")
    inactive.activo = False
    db_session.flush()

    with pytest.raises(HTTPException) as exc:
        TransactionService.create(
            db_session,
            owner,
            TransactionCreate(
                account_id=account.id,
                category_id=category.id,
                sub_category_id=sub.id,
                monto=Decimal("10"),
                fecha=date(2026, 7, 13),
                contraparte_id=foreign.id,
            ),
        )
    assert exc.value.status_code == 404

    with pytest.raises(HTTPException) as exc2:
        TransactionService.create(
            db_session,
            owner,
            TransactionCreate(
                account_id=account.id,
                category_id=category.id,
                sub_category_id=sub.id,
                monto=Decimal("10"),
                fecha=date(2026, 7, 13),
                contraparte_id=inactive.id,
            ),
        )
    assert exc2.value.status_code == 404


def test_create_cash_creates_wallet_and_moves_saldo(db_session):
    user = make_user(db_session)
    category = make_category(db_session)
    sub = make_sub_category(db_session, category)

    # Fund cash wallet first (auto-created on first cash ingreso).
    TransactionService.create(
        db_session,
        user,
        TransactionCreate(
            category_id=category.id,
            sub_category_id=sub.id,
            monto=Decimal("100"),
            tipo="ingreso",
            medio_pago="efectivo",
            moneda="COP",
            fecha=date(2026, 7, 13),
            descripcion="Apertura efectivo",
        ),
    )
    item = TransactionService.create(
        db_session,
        user,
        TransactionCreate(
            category_id=category.id,
            sub_category_id=sub.id,
            monto=Decimal("15"),
            tipo="gasto",
            medio_pago="efectivo",
            moneda="COP",
            fecha=date(2026, 7, 13),
            descripcion="Taxi",
        ),
    )

    wallet = AccountRepository.get_cash_wallet(db_session, user_id=user.id, moneda="COP")
    assert wallet is not None
    assert wallet.tipo == CASH_TIPO
    assert item.account_id == wallet.id
    assert item.medio_pago == "efectivo"
    assert wallet.saldo == Decimal("85.00")

    # Reuse same wallet on second cash tx
    TransactionService.create(
        db_session,
        user,
        TransactionCreate(
            category_id=category.id,
            sub_category_id=sub.id,
            monto=Decimal("5"),
            tipo="ingreso",
            medio_pago="efectivo",
            moneda="COP",
            fecha=date(2026, 7, 13),
        ),
    )
    db_session.refresh(wallet)
    wallets = [
        a
        for a in AccountRepository.list_by_user(db_session, user.id)
        if a.tipo == CASH_TIPO and a.moneda == "COP"
    ]
    assert len(wallets) == 1
    assert wallet.saldo == Decimal("90.00")


def test_create_rejects_insufficient_funds(db_session):
    user = make_user(db_session)
    account = make_account(db_session, user, saldo=Decimal("10"))
    category = make_category(db_session)
    sub = make_sub_category(db_session, category)

    with pytest.raises(HTTPException) as exc:
        TransactionService.create(
            db_session,
            user,
            TransactionCreate(
                account_id=account.id,
                category_id=category.id,
                sub_category_id=sub.id,
                monto=Decimal("50"),
                tipo="gasto",
                fecha=date(2026, 7, 13),
            ),
        )
    assert exc.value.status_code == 400
    assert "Fondos insuficientes" in exc.value.detail
    db_session.refresh(account)
    assert account.saldo == Decimal("10")


def test_schema_rejects_cash_with_account_id():
    with pytest.raises(ValidationError):
        TransactionCreate(
            account_id=1,
            category_id=1,
            sub_category_id=1,
            monto=Decimal("10"),
            medio_pago="efectivo",
            moneda="COP",
            fecha=date(2026, 7, 13),
        )


def test_schema_rejects_cuenta_without_account_id():
    with pytest.raises(ValidationError):
        TransactionCreate(
            category_id=1,
            sub_category_id=1,
            monto=Decimal("10"),
            medio_pago="cuenta",
            fecha=date(2026, 7, 13),
        )


def test_transfer_bank_to_cash_wallet(db_session):
    user = make_user(db_session)
    bank = make_account(db_session, user, banco="Bancolombia", saldo=Decimal("200"))
    wallet = AccountRepository.get_or_create_cash_wallet(
        db_session, user_id=user.id, moneda="COP"
    )
    cat = make_category(db_session, nombre="Transferencias")
    sub = make_sub_category(db_session, cat)

    result = TransactionService.transfer(
        db_session,
        user,
        TransferCreate(
            from_account_id=bank.id,
            to_account_id=wallet.id,
            monto=Decimal("40"),
            fecha=date(2026, 7, 13),
            category_id=cat.id,
            sub_category_id=sub.id,
            descripcion="Retiro ATM",
        ),
    )

    db_session.refresh(bank)
    db_session.refresh(wallet)
    assert bank.saldo == Decimal("160")
    assert wallet.saldo == Decimal("40")
    assert result.salida.medio_pago == "cuenta"
    assert result.entrada.medio_pago == "cuenta"
