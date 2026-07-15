"""
Unit tests — app.core.security (hash + JWT, sin BD ni HTTP).
"""

from datetime import timedelta

import jwt
import pytest
from jwt.exceptions import ExpiredSignatureError, InvalidTokenError

from app.core.config import settings
from app.core.security import (
    ALGORITHM,
    create_access_token,
    decode_access_token,
    get_subject_from_token,
    hash_password,
    verify_password,
)

pytestmark = pytest.mark.unit


def test_hash_password_returns_bcrypt_hash_not_plaintext():
    # Arrange
    plain = "MiClaveSegura123"

    # Act
    hashed = hash_password(plain)

    # Assert
    assert hashed != plain
    assert hashed.startswith("$2")  # prefijo típico de bcrypt


def test_verify_password_accepts_correct_password():
    # Arrange
    plain = "secreto123"
    hashed = hash_password(plain)

    # Act
    ok = verify_password(plain, hashed)

    # Assert
    assert ok is True


def test_verify_password_rejects_wrong_password():
    # Arrange
    hashed = hash_password("correcta")

    # Act
    ok = verify_password("incorrecta", hashed)

    # Assert
    assert ok is False


def test_create_access_token_includes_subject():
    # Arrange
    user_id = 42

    # Act
    token = create_access_token(subject=user_id)

    # Assert
    payload = jwt.decode(token, settings.SECRET_KEY, algorithms=[ALGORITHM])
    assert payload["sub"] == "42"


def test_get_subject_from_token_returns_user_id():
    # Arrange
    token = create_access_token(subject=7)

    # Act
    subject = get_subject_from_token(token)

    # Assert
    assert subject == "7"


def test_decode_access_token_rejects_expired_token():
    # Arrange: token que ya expiró (expires_delta negativo)
    token = create_access_token(subject=1, expires_delta=timedelta(seconds=-1))

    # Act / Assert
    with pytest.raises(ExpiredSignatureError):
        decode_access_token(token)


def test_get_subject_from_token_rejects_tampered_token():
    # Arrange: token firmado y luego alterado
    token = create_access_token(subject=1)
    tampered = token[:-4] + ("AAAA" if not token.endswith("AAAA") else "BBBB")

    # Act / Assert
    with pytest.raises(InvalidTokenError):
        get_subject_from_token(tampered)
