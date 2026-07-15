"""
app/core/security.py — Utilidades de autenticación y criptografía
=================================================================

QUÉ ES
------
Funciones de bajo nivel para:
  1) Hashear / verificar contraseñas (bcrypt).
  2) Crear / decodificar tokens JWT (PyJWT).

QUÉ NO ES
---------
No habla con la BD, no valida reglas de negocio, no es un endpoint.
Eso vive en services / repositories / deps / routers.


PRINCIPIOS
----------
1. Nunca guardar contraseñas en texto plano → solo hash (bcrypt).
2. No inventar criptografía → librerías probadas (bcrypt, PyJWT).
3. Secretos fuera del código → SECRET_KEY desde settings / .env.
4. Separación de capas → security solo "crypto + tokens".


CÓMO SE USA (flujo típico)
--------------------------
Registro:
  plain = "miClave123"
  user.contrasena_hash = hash_password(plain)

Login:
  if verify_password(plain, user.contrasena_hash):
      token = create_access_token(subject=str(user.id))

Request protegido:
  payload = decode_access_token(token)   # o vía get_current_user en deps


DEPENDENCIAS
------------
  bcrypt, PyJWT  (ver requirements.txt)
"""

from __future__ import annotations

import hashlib
import secrets
from datetime import UTC, datetime, timedelta
from typing import Any, Literal

import bcrypt
import jwt
from jwt.exceptions import InvalidTokenError

from app.core.config import settings

# Algoritmo de firma del JWT. HS256 = HMAC + SHA-256 con SECRET_KEY.
# Simétrico: el mismo secreto firma y verifica (adecuado para una sola API).
ALGORITHM = "HS256"
TokenKind = Literal["access", "refresh"]


# ---------------------------------------------------------------------------
# Contraseñas (bcrypt)
# ---------------------------------------------------------------------------

def hash_password(plain_password: str) -> str:
    """
    Convierte una contraseña en texto plano a un hash bcrypt.

    Parámetros
    ----------
    plain_password:
        Lo que escribió el usuario (NUNCA se guarda así en la BD).

    Retorna
    -------
    str:
        Hash en texto (utf-8), listo para guardar en User.contrasena_hash.

    Por qué bcrypt
    --------------
    - Incluye salt automático (dos hashes de la misma clave salen distintos).
    - Es lento a propósito → dificulta fuerza bruta.
    """
    password_bytes = plain_password.encode("utf-8")
    # gensalt() genera el salt; rounds por defecto son un buen equilibrio.
    hashed = bcrypt.hashpw(password_bytes, bcrypt.gensalt())
    return hashed.decode("utf-8")


def verify_password(plain_password: str, hashed_password: str) -> bool:
    """
    Comprueba si `plain_password` corresponde al hash guardado.

    Retorna True si coinciden; False si no (o si el hash es inválido).

    Por qué no comparamos strings a mano
    ------------------------------------
    bcrypt.checkpw hace la comparación segura contra el hash (con su salt).
    """
    try:
        return bcrypt.checkpw(
            plain_password.encode("utf-8"),
            hashed_password.encode("utf-8"),
        )
    except (ValueError, TypeError):
        # Hash corrupto o formato inesperado → tratar como no válido.
        return False


# ---------------------------------------------------------------------------
# JWT (JSON Web Token)
# ---------------------------------------------------------------------------

def create_access_token(
    subject: str | int,
    expires_delta: timedelta | None = None,
    extra_claims: dict[str, Any] | None = None,
) -> str:
    """
    Emite un access token JWT firmado (claim typ=access).

    Claims: sub, iat, exp, typ.
    """
    now = datetime.now(UTC)
    expire = now + (
        expires_delta
        if expires_delta is not None
        else timedelta(minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES)
    )

    payload: dict[str, Any] = {
        "sub": str(subject),
        "iat": now,
        "exp": expire,
        "typ": "access",
    }
    if extra_claims:
        payload.update(extra_claims)

    return jwt.encode(payload, settings.SECRET_KEY, algorithm=ALGORITHM)


def decode_access_token(token: str) -> dict[str, Any]:
    """
    Valida firma/expiración y exige typ=access (o ausente por compatibilidad).
    """
    payload = jwt.decode(
        token,
        settings.SECRET_KEY,
        algorithms=[ALGORITHM],
    )
    typ = payload.get("typ", "access")
    if typ != "access":
        raise InvalidTokenError("Not an access token")
    return payload


def get_subject_from_token(token: str) -> str:
    """Decodifica el access token y devuelve el claim `sub`."""
    payload = decode_access_token(token)
    subject = payload.get("sub")
    if subject is None or subject == "":
        raise InvalidTokenError("Token without subject")
    return str(subject)


def generate_refresh_token() -> str:
    """Token opaco de alto entropía (se guarda solo el hash en BD)."""
    return secrets.token_urlsafe(48)


def hash_refresh_token(raw_token: str) -> str:
    """SHA-256 hex del refresh token (lookup seguro sin guardar el claro)."""
    return hashlib.sha256(raw_token.encode("utf-8")).hexdigest()
