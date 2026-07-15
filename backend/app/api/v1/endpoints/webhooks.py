"""
app/api/v1/endpoints/webhooks.py — Receptor firmado (integridad + anti-SSRF)

No realiza HTTP saliente a URLs del payload.
"""

from fastapi import APIRouter, Header, Request, status

from app.core.logging_config import get_logger
from app.core.rate_limit import enforce_rate_limit
from app.core.webhooks import verify_signature
from app.schemas.webhook import WebhookAck, WebhookEvent

router = APIRouter(prefix="/webhooks", tags=["webhooks"])
logger = get_logger("app.webhooks")


@router.post(
    "/inbound",
    response_model=WebhookAck,
    status_code=status.HTTP_202_ACCEPTED,
    summary="Webhook firmado (HMAC). No hace fetch a URLs del body.",
)
async def inbound_webhook(
    request: Request,
    x_webhook_signature: str | None = Header(default=None, alias="X-Webhook-Signature"),
) -> WebhookAck:
    enforce_rate_limit(request, scope="webhook", max_calls=30, period_seconds=60)
    body = await request.body()
    verify_signature(body, x_webhook_signature)
    event = WebhookEvent.model_validate_json(body)
    # Intencionadamente no se usa event.data.get("url") ni se hace request externo.
    logger.info("webhook_received event=%s", event.event)
    return WebhookAck(received=True, event=event.event)
