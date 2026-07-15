"""
tests/helpers.py — Factories para Arrange en tests unitarios
=============================================================

Crean entidades en la sesión SQLite sin pasar por HTTP.
Úsalas en tests/services y tests/repositories.
"""

from __future__ import annotations

from datetime import UTC, date, datetime
from decimal import Decimal

from sqlalchemy.orm import Session

from app.core.security import hash_password
from app.models.account import Account
from app.models.category import Category
from app.models.counterparty import Counterparty
from app.models.sub_category import SubCategory
from app.models.transaction import Transaction
from app.models.user import User


def _now() -> datetime:
    return datetime.now(UTC)


def make_user(
    db: Session,
    *,
    correo: str = "user@example.com",
    usuario: str = "user1",
    contrasena: str = "secreto123",
    rol: str = "user",
) -> User:
    user = User(
        nombres="Test",
        apellidos="User",
        fecha_nacimiento=date(1990, 1, 1),
        genero="M",
        correo=correo,
        usuario=usuario,
        contrasena_hash=hash_password(contrasena),
        rol=rol,
        activo=True,
        mfa_enabled=False,
        creado_en=_now(),
    )
    db.add(user)
    db.flush()
    db.refresh(user)
    return user


def make_account(
    db: Session,
    user: User,
    *,
    banco: str = "Bancolombia",
    tipo: str = "ahorros",
    moneda: str = "COP",
    saldo: Decimal = Decimal("100.00"),
) -> Account:
    now = _now()
    account = Account(
        user_id=user.id,
        banco=banco,
        tipo=tipo,
        moneda=moneda,
        saldo=saldo,
        activo=True,
        creado_en=now,
        actualizado_en=now,
    )
    db.add(account)
    db.flush()
    db.refresh(account)
    return account


def make_counterparty(
    db: Session,
    user: User,
    *,
    nombre: str = "Juan Pérez",
    banco: str | None = "Davivienda",
    numero_cuenta: str | None = "1234567890",
    notas: str | None = None,
) -> Counterparty:
    now = _now()
    item = Counterparty(
        user_id=user.id,
        nombre=nombre,
        banco=banco,
        numero_cuenta=numero_cuenta,
        notas=notas,
        activo=True,
        creado_en=now,
        actualizado_en=now,
    )
    db.add(item)
    db.flush()
    db.refresh(item)
    return item


def make_category(
    db: Session,
    *,
    nombre: str = "Comida",
    descripcion: str = "Gastos de alimentación",
) -> Category:
    now = _now()
    category = Category(
        nombre=nombre,
        descripcion=descripcion,
        activo=True,
        creado_en=now,
        actualizado_en=now,
    )
    db.add(category)
    db.flush()
    db.refresh(category)
    return category


def make_sub_category(
    db: Session,
    category: Category,
    *,
    nombre: str = "Restaurante",
    descripcion: str = "",
) -> SubCategory:
    now = _now()
    sub = SubCategory(
        category_id=category.id,
        nombre=nombre,
        descripcion=descripcion,
        activo=True,
        creado_en=now,
        actualizado_en=now,
    )
    db.add(sub)
    db.flush()
    db.refresh(sub)
    return sub


def make_transaction(
    db: Session,
    *,
    account: Account,
    category: Category,
    sub_category: SubCategory,
    monto: Decimal = Decimal("25.50"),
    tipo: str = "gasto",
    fecha: date | None = None,
    descripcion: str = "Almuerzo",
    adjust_saldo: bool = True,
) -> Transaction:
    now = _now()
    item = Transaction(
        account_id=account.id,
        category_id=category.id,
        sub_category_id=sub_category.id,
        monto=monto,
        tipo=tipo,
        medio_pago="cuenta",
        fecha=fecha or date(2026, 7, 1),
        descripcion=descripcion,
        activo=True,
        creado_en=now,
        actualizado_en=now,
    )
    db.add(item)
    if adjust_saldo:
        if tipo in {"ingreso", "transferencia_entrada"}:
            account.saldo = Decimal(account.saldo) + monto
        else:
            account.saldo = Decimal(account.saldo) - monto
    db.flush()
    db.refresh(item)
    return item
