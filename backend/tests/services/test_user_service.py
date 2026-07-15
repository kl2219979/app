"""
Unit tests — UserService (perfil propio, conflictos de correo/usuario).
"""

import pytest
from fastapi import HTTPException

from app.core.security import verify_password
from app.schemas.user import UserUpdate
from app.services.user import UserService
from tests.helpers import make_user

pytestmark = pytest.mark.unit


def test_get_by_id_for_viewer_allows_self(db_session):
    # Arrange
    user = make_user(db_session)

    # Act
    found = UserService.get_by_id_for_viewer(db_session, user, user.id)

    # Assert
    assert found.id == user.id


def test_get_by_id_for_viewer_forbids_other(db_session):
    # Arrange
    viewer = make_user(db_session, correo="a@x.com", usuario="a")
    other = make_user(db_session, correo="b@x.com", usuario="b")

    # Act / Assert
    with pytest.raises(HTTPException) as exc:
        UserService.get_by_id_for_viewer(db_session, viewer, other.id)
    assert exc.value.status_code == 403


def test_update_me_hashes_password_and_changes_nombre(db_session):
    # Arrange
    user = make_user(db_session, contrasena="secreto123")

    # Act
    updated = UserService.update_me(
        db_session,
        user,
        UserUpdate(nombres="Nuevo", contrasena="otraclave99"),
    )

    # Assert
    assert updated.nombres == "Nuevo"
    assert verify_password("otraclave99", updated.contrasena_hash)


def test_update_me_rejects_taken_correo(db_session):
    # Arrange
    me = make_user(db_session, correo="me@x.com", usuario="me")
    make_user(db_session, correo="taken@x.com", usuario="other")

    # Act / Assert
    with pytest.raises(HTTPException) as exc:
        UserService.update_me(db_session, me, UserUpdate(correo="taken@x.com"))
    assert exc.value.status_code == 409


def test_update_me_rejects_taken_usuario(db_session):
    # Arrange
    me = make_user(db_session, correo="me@x.com", usuario="me")
    make_user(db_session, correo="o@x.com", usuario="taken")

    # Act / Assert
    with pytest.raises(HTTPException) as exc:
        UserService.update_me(db_session, me, UserUpdate(usuario="taken"))
    assert exc.value.status_code == 409


def test_delete_me(db_session):
    # Arrange
    from app.repositories.user import UserRepository

    user = make_user(db_session)
    user_id = user.id

    # Act
    UserService.deactivate_me(db_session, user)

    # Assert
    assert UserRepository.get_by_id(db_session, user_id).activo is False
