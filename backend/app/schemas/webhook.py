"""Schemas de webhooks entrantes (JSON validado + firma HMAC)."""

from typing import Any

from pydantic import BaseModel, Field


class WebhookEvent(BaseModel):
    """Payload genérico. No se hace fetch a URLs embebidas (anti-SSRF)."""

    event: str = Field(min_length=1, max_length=100)
    data: dict[str, Any] = Field(default_factory=dict)


class WebhookAck(BaseModel):
    received: bool = True
    event: str
