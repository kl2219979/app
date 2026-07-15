"""
app/core/rate_limit.py — Rate limiting in-memory (por IP + ruta)
"""

from __future__ import annotations

import time
from collections import defaultdict, deque

from fastapi import HTTPException, Request, status

from app.core.config import settings


class SlidingWindowLimiter:
    def __init__(self) -> None:
        self._hits: dict[str, deque[float]] = defaultdict(deque)

    def allow(self, key: str, *, max_calls: int, period_seconds: float) -> bool:
        now = time.monotonic()
        window = self._hits[key]
        while window and now - window[0] > period_seconds:
            window.popleft()
        if len(window) >= max_calls:
            return False
        window.append(now)
        return True


_limiter = SlidingWindowLimiter()


def client_ip(request: Request) -> str:
    forwarded = request.headers.get("x-forwarded-for")
    if forwarded:
        return forwarded.split(",")[0].strip()
    if request.client:
        return request.client.host
    return "unknown"


def enforce_rate_limit(
    request: Request,
    *,
    max_calls: int | None = None,
    period_seconds: float | None = None,
    scope: str = "default",
) -> None:
    """Dependency/helper: 429 si se excede el cupo."""
    limit = max_calls if max_calls is not None else settings.RATE_LIMIT_AUTH_MAX
    period = (
        period_seconds
        if period_seconds is not None
        else float(settings.RATE_LIMIT_AUTH_WINDOW_SECONDS)
    )
    key = f"{scope}:{client_ip(request)}:{request.url.path}"
    if not _limiter.allow(key, max_calls=limit, period_seconds=period):
        raise HTTPException(
            status_code=status.HTTP_429_TOO_MANY_REQUESTS,
            detail="Demasiados intentos. Espera un momento e inténtalo de nuevo.",
        )
