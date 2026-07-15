"""
app/api/v1/endpoints/account.py — Cuentas (JWT)

DELETE desactiva (soft-delete). POST /{id}/reactivate reactiva.
El saldo no se edita por PUT; solo por movimientos.
"""

from fastapi import APIRouter, Depends, Query, status
from sqlalchemy.orm import Session

from app.api.deps import get_current_user, get_db
from app.models.user import User
from app.schemas.account import AccountCreate, AccountResponse, AccountUpdate
from app.schemas.pagination import Page
from app.services.account import AccountService

router = APIRouter(prefix="/accounts", tags=["accounts"])


@router.get("", response_model=Page[AccountResponse])
def list_accounts(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
    limit: int = Query(default=20, ge=1, le=100),
    offset: int = Query(default=0, ge=0),
    include_inactive: bool = Query(default=False),
) -> Page[AccountResponse]:
    return AccountService.list_mine(
        db,
        current_user,
        limit=limit,
        offset=offset,
        include_inactive=include_inactive,
    )


@router.get("/{account_id}", response_model=AccountResponse)
def get_account(
    account_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    return AccountService.get_mine(db, current_user, account_id)


@router.post("", response_model=AccountResponse, status_code=status.HTTP_201_CREATED)
def create_account(
    data: AccountCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    return AccountService.create(db, current_user, data)


@router.put("/{account_id}", response_model=AccountResponse)
def update_account(
    account_id: int,
    data: AccountUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    return AccountService.update(db, current_user, account_id, data)


@router.delete("/{account_id}", status_code=status.HTTP_204_NO_CONTENT)
def deactivate_account(
    account_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> None:
    """Desactiva la cuenta. El historial de movimientos se conserva."""
    AccountService.deactivate(db, current_user, account_id)


@router.post("/{account_id}/reactivate", response_model=AccountResponse)
def reactivate_account(
    account_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    return AccountService.reactivate(db, current_user, account_id)
