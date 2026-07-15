"""
Unit + API tests — MFA, webhooks firmados, bloqueo admin sin MFA.
"""

import pyotp
import pytest
from fastapi.testclient import TestClient
from sqlalchemy.orm import Session

from app.core.mfa import encrypt_totp_secret
from app.core.webhooks import sign_payload, verify_signature
from app.repositories.user import UserRepository
from app.services.auth import AuthService
from tests.helpers import make_user

pytestmark = pytest.mark.unit


def test_admin_login_requires_mfa_then_issues_tokens(db_session: Session):
    secret = "JBSWY3DPEHPK3PXP"
    user = make_user(db_session, correo="adm@x.com", usuario="adm1", rol="admin")
    user.mfa_secret_encrypted = encrypt_totp_secret(secret)
    user.mfa_enabled = True
    UserRepository.update(db_session, user)
    db_session.commit()

    challenge = AuthService.login(db_session, "adm1", "secreto123")
    assert challenge.mfa_required is True
    assert challenge.access_token is None
    assert challenge.mfa_token

    code = pyotp.TOTP(secret).now()
    tokens = AuthService.verify_mfa_login(
        db_session, mfa_token=challenge.mfa_token, code=code
    )
    assert tokens.access_token
    assert tokens.refresh_token


def test_webhook_signature_roundtrip():
    body = b'{"event":"ping","data":{}}'
    header = sign_payload(body, secret="x" * 32)
    verify_signature(body, header, secret="x" * 32)


def test_webhook_inbound_api(client: TestClient, monkeypatch: pytest.MonkeyPatch):
    secret = "x" * 32
    monkeypatch.setattr(
        "app.core.webhooks.settings",
        type("S", (), {"WEBHOOK_SECRET": secret})(),
    )
    body = b'{"event":"invoice.paid","data":{"id":1}}'
    sig = sign_payload(body, secret=secret)
    resp = client.post(
        "/api/v1/webhooks/inbound",
        content=body,
        headers={
            "Content-Type": "application/json",
            "X-Webhook-Signature": sig,
        },
    )
    assert resp.status_code == 202, resp.text
    assert resp.json()["event"] == "invoice.paid"

    bad = client.post(
        "/api/v1/webhooks/inbound",
        content=body,
        headers={"Content-Type": "application/json"},
    )
    assert bad.status_code == 401


def test_admin_without_mfa_blocked_on_catalog(
    client: TestClient, db_session: Session, auth_headers: dict[str, str]
):
    user = UserRepository.get_by_usuario(db_session, "ana95")
    assert user is not None
    user.rol = "admin"
    user.mfa_enabled = False
    UserRepository.update(db_session, user)
    db_session.commit()

    resp = client.post(
        "/api/v1/categories",
        json={"nombre": "X", "descripcion": ""},
        headers=auth_headers,
    )
    assert resp.status_code == 403
    assert "MFA" in resp.json()["detail"]
