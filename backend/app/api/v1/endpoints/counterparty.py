"""
app/api/v1/endpoints/counterparty.py — Contrapartes externas (JWT)

DELETE desactiva (soft-delete). POST /{id}/reactivate reactiva.
"""

from fastapi import APIRouter, Depends, Query, status
from sqlalchemy.orm import Session

from app.api.deps import get_current_user, get_db
from app.models.user import User
from app.schemas.counterparty import (
    CounterpartyCreate,
    CounterpartyResponse,
    CounterpartyUpdate,
)
from app.schemas.pagination import Page
from app.services.counterparty import CounterpartyService

router = APIRouter(prefix="/counterparties", tags=["counterparties"])


@router.get("", response_model=Page[CounterpartyResponse])
def list_counterparties(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
    limit: int = Query(default=20, ge=1, le=100),
    offset: int = Query(default=0, ge=0),
    include_inactive: bool = Query(default=False),
) -> Page[CounterpartyResponse]:
    return CounterpartyService.list_mine(
        db,
        current_user,
        limit=limit,
        offset=offset,
        include_inactive=include_inactive,
    )


@router.get("/{counterparty_id}", response_model=CounterpartyResponse)
def get_counterparty(
    counterparty_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    return CounterpartyService.get_mine(db, current_user, counterparty_id)


@router.post("", response_model=CounterpartyResponse, status_code=status.HTTP_201_CREATED)
def create_counterparty(
    data: CounterpartyCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    return CounterpartyService.create(db, current_user, data)


@router.put("/{counterparty_id}", response_model=CounterpartyResponse)
def update_counterparty(
    counterparty_id: int,
    data: CounterpartyUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    return CounterpartyService.update(db, current_user, counterparty_id, data)


@router.delete("/{counterparty_id}", status_code=status.HTTP_204_NO_CONTENT)
def deactivate_counterparty(
    counterparty_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> None:
    CounterpartyService.deactivate(db, current_user, counterparty_id)


@router.post("/{counterparty_id}/reactivate", response_model=CounterpartyResponse)
def reactivate_counterparty(
    counterparty_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    return CounterpartyService.reactivate(db, current_user, counterparty_id)
