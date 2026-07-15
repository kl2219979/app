"""
app/services/counterparty.py — Contrapartes externas (agenda de terceros)

Ownership por JWT. DELETE = desactivar; POST /reactivate reactiva.
"""

from __future__ import annotations

from fastapi import HTTPException, status
from sqlalchemy.orm import Session

from app.models.counterparty import Counterparty
from app.models.user import User
from app.repositories.counterparty import CounterpartyRepository
from app.schemas.counterparty import (
    CounterpartyCreate,
    CounterpartyResponse,
    CounterpartyUpdate,
)
from app.schemas.pagination import Page


class CounterpartyService:
    @staticmethod
    def list_mine(
        db: Session,
        current_user: User,
        *,
        limit: int = 20,
        offset: int = 0,
        include_inactive: bool = False,
    ) -> Page[CounterpartyResponse]:
        items, total = CounterpartyRepository.list_filtered(
            db,
            user_id=current_user.id,
            only_active=not include_inactive,
            limit=limit,
            offset=offset,
        )
        return Page[CounterpartyResponse](
            items=[CounterpartyResponse.model_validate(i) for i in items],
            total=total,
            limit=limit,
            offset=offset,
        )

    @staticmethod
    def get_mine(db: Session, current_user: User, counterparty_id: int) -> Counterparty:
        item = CounterpartyRepository.get_by_id_for_user(
            db, counterparty_id=counterparty_id, user_id=current_user.id
        )
        if item is None:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Contraparte no encontrada",
            )
        return item

    @staticmethod
    def create(db: Session, current_user: User, data: CounterpartyCreate) -> Counterparty:
        item = Counterparty(
            user_id=current_user.id,
            nombre=data.nombre,
            banco=data.banco,
            numero_cuenta=data.numero_cuenta,
            notas=data.notas,
            activo=True,
        )
        CounterpartyRepository.create(db, item)
        db.commit()
        db.refresh(item)
        return item

    @staticmethod
    def update(
        db: Session,
        current_user: User,
        counterparty_id: int,
        data: CounterpartyUpdate,
    ) -> Counterparty:
        item = CounterpartyService.get_mine(db, current_user, counterparty_id)
        if not item.activo:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="No se puede editar una contraparte inactiva; reactívala primero",
            )
        payload = data.model_dump(exclude_unset=True)
        for key, value in payload.items():
            setattr(item, key, value)
        CounterpartyRepository.update(db, item)
        db.commit()
        db.refresh(item)
        return item

    @staticmethod
    def deactivate(db: Session, current_user: User, counterparty_id: int) -> None:
        item = CounterpartyService.get_mine(db, current_user, counterparty_id)
        if not item.activo:
            return
        item.activo = False
        CounterpartyRepository.update(db, item)
        db.commit()

    @staticmethod
    def reactivate(
        db: Session, current_user: User, counterparty_id: int
    ) -> Counterparty:
        item = CounterpartyService.get_mine(db, current_user, counterparty_id)
        item.activo = True
        CounterpartyRepository.update(db, item)
        db.commit()
        db.refresh(item)
        return item
