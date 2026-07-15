"""
app/core/mfa.py — TOTP (MFA) para administradores
"""

from __future__ import annotations

import base64
import hashlib
from datetime import UTC, datetime, timedelta
from typing import Any

import jwt
import pyotp
from cryptography.fernet import Fernet, InvalidToken
from jwt.exceptions import InvalidTokenError

from app.core.config import settings
from app.core.security import ALGORITHM


def _fernet() -> Fernet:
    digest = hashlib.sha256(settings.SECRET_KEY.encode("utf-8")).digest()
    return Fernet(base64.urlsafe_b64encode(digest))


def generate_totp_secret() -> str:
    return pyotp.random_base32()


def encrypt_totp_secret(secret: str) -> str:
    return _fernet().encrypt(secret.encode("utf-8")).decode("utf-8")


def decrypt_totp_secret(encrypted: str) -> str:
    try:
        return _fernet().decrypt(encrypted.encode("utf-8")).decode("utf-8")
    except InvalidToken as exc:
        raise ValueError("Invalid MFA secret") from exc


def provisioning_uri(*, secret: str, account_name: str) -> str:
    return pyotp.TOTP(secret).provisioning_uri(
        name=account_name,
        issuer_name=settings.APP_NAME,
    )


def verify_totp(secret: str, code: str) -> bool:
    totp = pyotp.TOTP(secret)
    return bool(totp.verify(code, valid_window=1))


def create_mfa_challenge_token(user_id: int) -> str:
    """JWT corto tip=mfa_challenge tras password OK (antes del TOTP)."""
    now = datetime.now(UTC)
    payload: dict[str, Any] = {
        "sub": str(user_id),
        "iat": now,
        "exp": now + timedelta(minutes=settings.MFA_CHALLENGE_EXPIRE_MINUTES),
        "typ": "mfa_challenge",
    }
    return jwt.encode(payload, settings.SECRET_KEY, algorithm=ALGORITHM)


def decode_mfa_challenge_token(token: str) -> int:
    payload = jwt.decode(token, settings.SECRET_KEY, algorithms=[ALGORITHM])
    if payload.get("typ") != "mfa_challenge":
        raise InvalidTokenError("Not an MFA challenge token")
    sub = payload.get("sub")
    if sub is None:
        raise InvalidTokenError("Token without subject")
    return int(sub)
