"""
app/services/budget.py — Presupuestos mensuales por categoría

Una meta activa por (usuario, categoría). Soft-delete + reactivate.
"""

from __future__ import annotations

from calendar import monthrange
from datetime import date
from decimal import Decimal

from fastapi import HTTPException, status
from sqlalchemy import func, select
from sqlalchemy.orm import Session

from app.models.account import Account
from app.models.budget import Budget
from app.models.transaction import Transaction
from app.models.user import User
from app.repositories.budget import BudgetRepository
from app.repositories.category import CategoryRepository
from app.schemas.budget import BudgetCreate, BudgetStatus, BudgetUpdate


class BudgetService:
    @staticmethod
    def _month_window(today: date | None = None) -> tuple[date, date]:
        today = today or date.today()
        start = today.replace(day=1)
        end = date(today.year, today.month, monthrange(today.year, today.month)[1])
        return start, end

    @staticmethod
    def _spent_in_period(
        db: Session,
        *,
        user_id: int,
        category_id: int,
        date_from: date,
        date_to: date,
    ) -> Decimal:
        q = (
            select(func.coalesce(func.sum(Transaction.monto), 0))
            .join(Account, Transaction.account_id == Account.id)
            .where(
                Account.user_id == user_id,
                Transaction.category_id == category_id,
                Transaction.tipo == "gasto",
                Transaction.activo.is_(True),
                Transaction.fecha >= date_from,
                Transaction.fecha <= date_to,
            )
        )
        return Decimal(str(db.scalar(q) or 0))

    @staticmethod
    def to_status(db: Session, item: Budget, *, today: date | None = None) -> BudgetStatus:
        period_from, period_to = BudgetService._month_window(today)
        category = CategoryRepository.get_by_id(db, item.category_id)
        nombre = category.nombre if category else f"#{item.category_id}"
        gastado = BudgetService._spent_in_period(
            db,
            user_id=item.user_id,
            category_id=item.category_id,
            date_from=period_from,
            date_to=period_to,
        )
        limite = Decimal(item.limite)
        restante = limite - gastado
        pct = (
            (gastado / limite * Decimal("100")).quantize(Decimal("0.01"))
            if limite > 0
            else Decimal("0")
        )
        return BudgetStatus(
            budget_id=item.id,
            category_id=item.category_id,
            category_nombre=nombre,
            limite=limite,
            moneda=item.moneda,
            periodo=item.periodo,
            gastado=gastado,
            restante=restante,
            pct_usado=pct,
            excedido=gastado > limite,
            period_from=period_from.isoformat(),
            period_to=period_to.isoformat(),
        )

    @staticmethod
    def list_status(db: Session, current_user: User) -> list[BudgetStatus]:
        items, _ = BudgetRepository.list_filtered(
            db, user_id=current_user.id, only_active=True, limit=10_000, offset=0
        )
        return [BudgetService.to_status(db, i) for i in items]

    @staticmethod
    def get_mine(db: Session, current_user: User, budget_id: int) -> Budget:
        item = BudgetRepository.get_by_id_for_user(
            db, budget_id=budget_id, user_id=current_user.id
        )
        if item is None:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Presupuesto no encontrado",
            )
        return item

    @staticmethod
    def create(db: Session, current_user: User, data: BudgetCreate) -> Budget:
        category = CategoryRepository.get_by_id(db, data.category_id)
        if category is None or not category.activo:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Categoría no encontrada o inactiva",
            )
        existing = BudgetRepository.get_by_category_for_user(
            db, user_id=current_user.id, category_id=data.category_id
        )
        if existing is not None:
            if existing.activo:
                raise HTTPException(
                    status_code=status.HTTP_409_CONFLICT,
                    detail="Ya existe un presupuesto activo para esa categoría",
                )
            existing.activo = True
            existing.limite = data.limite
            existing.moneda = data.moneda
            existing.periodo = data.periodo
            BudgetRepository.update(db, existing)
            db.commit()
            db.refresh(existing)
            return existing

        item = Budget(
            user_id=current_user.id,
            category_id=data.category_id,
            limite=data.limite,
            moneda=data.moneda,
            periodo=data.periodo,
            activo=True,
        )
        BudgetRepository.create(db, item)
        db.commit()
        db.refresh(item)
        return item

    @staticmethod
    def update(
        db: Session,
        current_user: User,
        budget_id: int,
        data: BudgetUpdate,
    ) -> Budget:
        item = BudgetService.get_mine(db, current_user, budget_id)
        if not item.activo:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="No se puede editar un presupuesto inactivo; reactívalo primero",
            )
        payload = data.model_dump(exclude_unset=True)
        for key, value in payload.items():
            setattr(item, key, value)
        BudgetRepository.update(db, item)
        db.commit()
        db.refresh(item)
        return item

    @staticmethod
    def deactivate(db: Session, current_user: User, budget_id: int) -> None:
        item = BudgetService.get_mine(db, current_user, budget_id)
        if not item.activo:
            return
        item.activo = False
        BudgetRepository.update(db, item)
        db.commit()

    @staticmethod
    def reactivate(db: Session, current_user: User, budget_id: int) -> Budget:
        item = BudgetService.get_mine(db, current_user, budget_id)
        item.activo = True
        BudgetRepository.update(db, item)
        db.commit()
        db.refresh(item)
        return item
