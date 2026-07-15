"""
Unit tests — SubCategoryService (categoría padre obligatoria).
"""

import pytest
from fastapi import HTTPException

from app.schemas.sub_category import SubCategoryCreate, SubCategoryUpdate
from app.services.sub_category import SubCategoryService
from tests.helpers import make_category, make_sub_category

pytestmark = pytest.mark.unit


def test_create_requires_existing_category(db_session):
    # Arrange
    data = SubCategoryCreate(category_id=999, nombre="Uber")

    # Act / Assert
    with pytest.raises(HTTPException) as exc:
        SubCategoryService.create(db_session, data)
    assert exc.value.status_code == 404


def test_create_and_list_by_category(db_session):
    # Arrange
    cat = make_category(db_session, nombre="Transporte")
    other = make_category(db_session, nombre="Comida")
    data = SubCategoryCreate(category_id=cat.id, nombre="Taxi")

    # Act
    created = SubCategoryService.create(db_session, data)
    make_sub_category(db_session, other, nombre="Pizza")
    filtered = SubCategoryService.list_all(db_session, category_id=cat.id)

    # Assert
    assert created.category_id == cat.id
    assert filtered.total == 1
    assert filtered.items[0].nombre == "Taxi"


def test_list_by_missing_category_raises_404(db_session):
    # Arrange / Act / Assert
    with pytest.raises(HTTPException) as exc:
        SubCategoryService.list_all(db_session, category_id=404)
    assert exc.value.status_code == 404


def test_update_rejects_unknown_category(db_session):
    # Arrange
    cat = make_category(db_session)
    sub = make_sub_category(db_session, cat)

    # Act / Assert
    with pytest.raises(HTTPException) as exc:
        SubCategoryService.update(
            db_session,
            sub.id,
            SubCategoryUpdate(category_id=999),
        )
    assert exc.value.status_code == 404


def test_get_and_delete(db_session):
    # Arrange
    cat = make_category(db_session)
    sub = make_sub_category(db_session, cat, nombre="Cafe")

    # Act
    found = SubCategoryService.get(db_session, sub.id)
    SubCategoryService.deactivate(db_session, sub.id)

    # Assert
    assert found.nombre == "Cafe"
    inactive = SubCategoryService.get(db_session, sub.id)
    assert inactive.activo is False
