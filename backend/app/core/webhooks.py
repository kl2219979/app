"""
app/core/webhooks.py — Integridad de webhooks (HMAC-SHA256)

No hace requests a URLs del payload (mitiga SSRF).
Solo verifica firma y valida el cuerpo vía Pydantic en el endpoint.
"""

from __future__ import annotations

import hashlib
import hmac
import time

from fastapi import HTTPException, status

from app.core.config import settings


def sign_payload(body: bytes, *, secret: str | None = None, timestamp: int | None = None) -> str:
    """Devuelve header `t=<ts>,v1=<hex>` firmado."""
    key = (secret or settings.WEBHOOK_SECRET or "").encode("utf-8")
    if not key:
        raise ValueError("WEBHOOK_SECRET is not configured")
    ts = timestamp if timestamp is not None else int(time.time())
    signed = f"{ts}.".encode() + body
    digest = hmac.new(key, signed, hashlib.sha256).hexdigest()
    return f"t={ts},v1={digest}"


def verify_signature(
    body: bytes,
    signature_header: str | None,
    *,
    secret: str | None = None,
    max_age_seconds: int = 300,
) -> None:
    """Valida X-Webhook-Signature. Lanza 401 si falla."""
    key = (secret if secret is not None else settings.WEBHOOK_SECRET) or ""
    if not key:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="Webhooks no configurados (WEBHOOK_SECRET)",
        )
    if not signature_header:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Falta firma de webhook",
        )

    parts = dict(p.split("=", 1) for p in signature_header.split(",") if "=" in p)
    try:
        ts = int(parts.get("t", ""))
        expected = parts.get("v1", "")
    except ValueError as exc:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Firma de webhook inválida",
        ) from exc

    if abs(int(time.time()) - ts) > max_age_seconds:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Firma de webhook expirada",
        )

    signed = f"{ts}.".encode() + body
    computed = hmac.new(key.encode("utf-8"), signed, hashlib.sha256).hexdigest()
    if not expected or not hmac.compare_digest(computed, expected):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Firma de webhook no válida",
        )
