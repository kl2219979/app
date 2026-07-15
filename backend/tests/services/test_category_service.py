"""
Unit tests — CategoryService (unicidad de nombre, 404).
"""

import pytest
from fastapi import HTTPException

from app.schemas.category import CategoryCreate, CategoryUpdate
from app.services.category import CategoryService
from tests.helpers import make_category

pytestmark = pytest.mark.unit


def test_create_category(db_session):
    # Arrange
    data = CategoryCreate(nombre="Transporte", descripcion="Movilidad")

    # Act
    category = CategoryService.create(db_session, data)

    # Assert
    assert category.id is not None
    assert category.nombre == "Transporte"


def test_create_rejects_duplicate_nombre(db_session):
    # Arrange
    make_category(db_session, nombre="Comida")
    data = CategoryCreate(nombre="Comida")

    # Act / Assert
    with pytest.raises(HTTPException) as exc:
        CategoryService.create(db_session, data)
    assert exc.value.status_code == 409


def test_get_missing_raises_404(db_session):
    # Arrange / Act / Assert
    with pytest.raises(HTTPException) as exc:
        CategoryService.get(db_session, 999)
    assert exc.value.status_code == 404


def test_update_rejects_nombre_taken_by_other(db_session):
    # Arrange
    make_category(db_session, nombre="A")
    target = make_category(db_session, nombre="B")

    # Act / Assert
    with pytest.raises(HTTPException) as exc:
        CategoryService.update(db_session, target.id, CategoryUpdate(nombre="A"))
    assert exc.value.status_code == 409


def test_list_and_delete(db_session):
    # Arrange
    cat = make_category(db_session, nombre="Salud")

    # Act
    listed = CategoryService.list_all(db_session)
    CategoryService.deactivate(db_session, cat.id)

    # Assert
    assert any(c.id == cat.id for c in listed.items)
    found = CategoryService.get(db_session, cat.id)
    assert found.activo is False
