"""
Unit tests — seed de categorías (idempotente).
"""

import pytest

from app.repositories.category import CategoryRepository
from app.services.seed import SEED_CATALOG, seed_categories

pytestmark = pytest.mark.unit


def test_seed_categories_is_idempotent(db_session):
    # Arrange / Act
    first_cats, first_subs = seed_categories(db_session)
    second_cats, second_subs = seed_categories(db_session)

    # Assert
    assert first_cats == len(SEED_CATALOG)
    assert first_subs > 0
    assert second_cats == 0
    assert second_subs == 0
    assert CategoryRepository.get_by_nombre(db_session, "Alimentación") is not None
