"""
Unit tests — UserRepository.
"""

import pytest

from app.repositories.user import UserRepository
from tests.helpers import make_user

pytestmark = pytest.mark.unit


def test_lookups_by_correo_usuario_and_either(db_session):
    # Arrange
    user = make_user(db_session, correo="ana@x.com", usuario="ana")

    # Act / Assert
    assert UserRepository.get_by_correo(db_session, "ana@x.com").id == user.id
    assert UserRepository.get_by_usuario(db_session, "ana").id == user.id
    assert UserRepository.get_by_correo_or_usuario(db_session, "ana@x.com").id == user.id
    assert UserRepository.get_by_correo_or_usuario(db_session, "ana").id == user.id
    assert UserRepository.get_by_correo_or_usuario(db_session, "missing") is None


def test_exists_correo_or_usuario(db_session):
    # Arrange
    make_user(db_session, correo="a@x.com", usuario="alice")

    # Act / Assert
    assert UserRepository.exists_correo_or_usuario(
        db_session, correo="a@x.com", usuario="nuevo"
    )
    assert UserRepository.exists_correo_or_usuario(
        db_session, correo="nuevo@x.com", usuario="alice"
    )
    assert not UserRepository.exists_correo_or_usuario(
        db_session, correo="nuevo@x.com", usuario="nuevo"
    )
