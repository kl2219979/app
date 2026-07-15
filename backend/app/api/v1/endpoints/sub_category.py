"""
app/api/v1/endpoints/sub_category.py — Soft-delete de subcategorías
"""

from fastapi import APIRouter, Depends, Query, status
from sqlalchemy.orm import Session

from app.api.deps import get_current_admin, get_current_user, get_db
from app.models.user import User
from app.schemas.pagination import Page
from app.schemas.sub_category import SubCategoryCreate, SubCategoryResponse, SubCategoryUpdate
from app.services.sub_category import SubCategoryService

router = APIRouter(prefix="/subcategories", tags=["subcategories"])


@router.get("", response_model=Page[SubCategoryResponse])
def list_subcategories(
    category_id: int | None = Query(default=None),
    limit: int = Query(default=20, ge=1, le=100),
    offset: int = Query(default=0, ge=0),
    include_inactive: bool = Query(default=False),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> Page[SubCategoryResponse]:
    _ = current_user
    return SubCategoryService.list_all(
        db,
        category_id=category_id,
        limit=limit,
        offset=offset,
        include_inactive=include_inactive,
    )


@router.get("/{subcategory_id}", response_model=SubCategoryResponse)
def get_subcategory(
    subcategory_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    _ = current_user
    return SubCategoryService.get(db, subcategory_id)


@router.post("", response_model=SubCategoryResponse, status_code=status.HTTP_201_CREATED)
def create_subcategory(
    data: SubCategoryCreate,
    db: Session = Depends(get_db),
    _: User = Depends(get_current_admin),
):
    return SubCategoryService.create(db, data)


@router.put("/{subcategory_id}", response_model=SubCategoryResponse)
def update_subcategory(
    subcategory_id: int,
    data: SubCategoryUpdate,
    db: Session = Depends(get_db),
    _: User = Depends(get_current_admin),
):
    return SubCategoryService.update(db, subcategory_id, data)


@router.delete("/{subcategory_id}", status_code=status.HTTP_204_NO_CONTENT)
def deactivate_subcategory(
    subcategory_id: int,
    db: Session = Depends(get_db),
    _: User = Depends(get_current_admin),
) -> None:
    SubCategoryService.deactivate(db, subcategory_id)
