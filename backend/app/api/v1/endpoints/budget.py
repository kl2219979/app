"""
app/api/v1/endpoints/budget.py — Presupuestos mensuales (JWT)
"""

from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy.orm import Session

from app.api.deps import get_current_user, get_db
from app.models.user import User
from app.repositories.budget import BudgetRepository
from app.schemas.budget import BudgetCreate, BudgetResponse, BudgetStatus, BudgetUpdate
from app.schemas.pagination import Page
from app.services.budget import BudgetService

router = APIRouter(prefix="/budgets", tags=["budgets"])


@router.get("/status", response_model=list[BudgetStatus])
def list_budget_status(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> list[BudgetStatus]:
    """Presupuestos activos con consumo del mes calendario actual."""
    return BudgetService.list_status(db, current_user)


@router.get("", response_model=Page[BudgetResponse])
def list_budgets(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
    limit: int = Query(default=20, ge=1, le=100),
    offset: int = Query(default=0, ge=0),
    include_inactive: bool = Query(default=False),
) -> Page[BudgetResponse]:
    items, total = BudgetRepository.list_filtered(
        db,
        user_id=current_user.id,
        only_active=not include_inactive,
        limit=limit,
        offset=offset,
    )
    return Page[BudgetResponse](
        items=[BudgetResponse.model_validate(i) for i in items],
        total=total,
        limit=limit,
        offset=offset,
    )


@router.get("/{budget_id}/status", response_model=BudgetStatus)
def get_budget_status(
    budget_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    item = BudgetService.get_mine(db, current_user, budget_id)
    if not item.activo:
        raise HTTPException(status_code=400, detail="Presupuesto inactivo")
    return BudgetService.to_status(db, item)


@router.get("/{budget_id}", response_model=BudgetResponse)
def get_budget(
    budget_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    return BudgetService.get_mine(db, current_user, budget_id)


@router.post("", response_model=BudgetResponse, status_code=status.HTTP_201_CREATED)
def create_budget(
    data: BudgetCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    return BudgetService.create(db, current_user, data)


@router.put("/{budget_id}", response_model=BudgetResponse)
def update_budget(
    budget_id: int,
    data: BudgetUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    return BudgetService.update(db, current_user, budget_id, data)


@router.delete("/{budget_id}", status_code=status.HTTP_204_NO_CONTENT)
def deactivate_budget(
    budget_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> None:
    BudgetService.deactivate(db, current_user, budget_id)


@router.post("/{budget_id}/reactivate", response_model=BudgetResponse)
def reactivate_budget(
    budget_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    return BudgetService.reactivate(db, current_user, budget_id)
