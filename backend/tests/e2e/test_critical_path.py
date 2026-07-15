"""
E2E — camino crítico (opt-in). Requiere API viva + catálogo seed:

  python scripts/seed.py
  RUN_E2E=1 E2E_BASE_URL=http://localhost:8000 pytest -m e2e

Flujo: health → register → login → account → usar categoría seed → transaction → report
"""

from __future__ import annotations

import os
import uuid

import httpx
import pytest

pytestmark = pytest.mark.e2e


@pytest.fixture()
def e2e_base_url() -> str:
    if os.getenv("RUN_E2E", "").lower() not in {"1", "true", "yes"}:
        pytest.skip("E2E deshabilitado. Exporta RUN_E2E=1 y opcionalmente E2E_BASE_URL.")
    return os.getenv("E2E_BASE_URL", "http://localhost:8000").rstrip("/")


def test_critical_money_path(e2e_base_url: str):
    suffix = uuid.uuid4().hex[:8]
    register_payload = {
        "nombres": "E2E",
        "apellidos": "Runner",
        "fecha_nacimiento": "1992-02-02",
        "genero": "O",
        "correo": f"e2e_{suffix}@example.com",
        "usuario": f"e2e_{suffix}",
        "contrasena": "secreto12345",
    }

    with httpx.Client(base_url=e2e_base_url, timeout=30.0) as client:
        health = client.get("/api/v1/health")
        assert health.status_code == 200, health.text

        reg = client.post("/api/v1/auth/register", json=register_payload)
        assert reg.status_code == 201, reg.text

        login = client.post(
            "/api/v1/auth/login",
            data={
                "username": register_payload["usuario"],
                "password": register_payload["contrasena"],
            },
        )
        assert login.status_code == 200, login.text
        body = login.json()
        assert "refresh_token" in body
        headers = {"Authorization": f"Bearer {body['access_token']}"}

        account = client.post(
            "/api/v1/accounts",
            json={
                "banco": "E2E Bank",
                "tipo": "ahorros",
                "moneda": "COP",
                "saldo_inicial": "100",
            },
            headers=headers,
        )
        assert account.status_code == 201, account.text

        cats = client.get("/api/v1/categories?limit=5", headers=headers)
        assert cats.status_code == 200, cats.text
        assert cats.json()["total"] >= 1, "Ejecuta python scripts/seed.py antes del E2E"
        category = cats.json()["items"][0]

        subs = client.get(
            f"/api/v1/subcategories?category_id={category['id']}&limit=5",
            headers=headers,
        )
        assert subs.status_code == 200, subs.text
        assert subs.json()["total"] >= 1
        sub = subs.json()["items"][0]

        tx = client.post(
            "/api/v1/transactions",
            json={
                "account_id": account.json()["id"],
                "category_id": category["id"],
                "sub_category_id": sub["id"],
                "monto": "9.99",
                "tipo": "gasto",
                "fecha": "2026-07-11",
                "descripcion": "e2e path",
            },
            headers=headers,
        )
        assert tx.status_code == 201, tx.text
        assert tx.json()["descripcion"] == "e2e path"

        summary = client.get("/api/v1/reports/summary", headers=headers)
        assert summary.status_code == 200, summary.text
        assert float(summary.json()["total_gastos"]) >= 9.99
