"""
Unit tests — CategoryRepository y SubCategoryRepository.
"""

import pytest

from app.repositories.category import CategoryRepository
from app.repositories.sub_category import SubCategoryRepository
from tests.helpers import make_category, make_sub_category

pytestmark = pytest.mark.unit


def test_category_get_by_nombre_and_list(db_session):
    # Arrange
    make_category(db_session, nombre="Zulu")
    make_category(db_session, nombre="Alpha")

    # Act
    found = CategoryRepository.get_by_nombre(db_session, "Alpha")
    listed = CategoryRepository.list_all(db_session)

    # Assert
    assert found is not None
    assert [c.nombre for c in listed] == ["Alpha", "Zulu"]


def test_sub_category_list_by_category(db_session):
    # Arrange
    cat = make_category(db_session, nombre="Comida")
    other = make_category(db_session, nombre="Casa")
    make_sub_category(db_session, cat, nombre="Cafe")
    make_sub_category(db_session, cat, nombre="Pizza")
    make_sub_category(db_session, other, nombre="Renta")

    # Act
    listed = SubCategoryRepository.list_by_category(db_session, cat.id)

    # Assert
    assert [s.nombre for s in listed] == ["Cafe", "Pizza"]
