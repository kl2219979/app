"""
Integration (API) — efectivo y contraparte en transactions.
"""

from decimal import Decimal

import pytest

pytestmark = pytest.mark.integration


def _seed_catalog(client, admin_headers):
    category = client.post(
        "/api/v1/categories",
        json={"nombre": "Extras", "descripcion": ""},
        headers=admin_headers,
    ).json()
    sub = client.post(
        "/api/v1/subcategories",
        json={"category_id": category["id"], "nombre": "Varios"},
        headers=admin_headers,
    ).json()
    return category, sub


def test_cash_transaction_and_counterparty(client, auth_headers, admin_headers):
    category, sub = _seed_catalog(client, admin_headers)
    cp = client.post(
        "/api/v1/counterparties",
        json={"nombre": "Tienda Local", "banco": None, "numero_cuenta": None},
        headers=auth_headers,
    ).json()

    funded = client.post(
        "/api/v1/transactions",
        json={
            "category_id": category["id"],
            "sub_category_id": sub["id"],
            "monto": "100.00",
            "tipo": "ingreso",
            "medio_pago": "efectivo",
            "moneda": "COP",
            "fecha": "2026-07-13",
            "descripcion": "Apertura efectivo",
        },
        headers=auth_headers,
    )
    assert funded.status_code == 201, funded.text

    created = client.post(
        "/api/v1/transactions",
        json={
            "category_id": category["id"],
            "sub_category_id": sub["id"],
            "monto": "12.50",
            "tipo": "gasto",
            "medio_pago": "efectivo",
            "moneda": "COP",
            "contraparte_id": cp["id"],
            "fecha": "2026-07-13",
            "descripcion": "Compra en efectivo",
        },
        headers=auth_headers,
    )
    assert created.status_code == 201, created.text
    body = created.json()
    assert body["medio_pago"] == "efectivo"
    assert body["contraparte_id"] == cp["id"]
    assert body["account_id"] is not None

    accounts = client.get("/api/v1/accounts", headers=auth_headers).json()
    cash = next(a for a in accounts["items"] if a["tipo"] == "efectivo")
    assert cash["id"] == body["account_id"]
    assert Decimal(str(cash["saldo"])) == Decimal("87.50")


def test_cash_with_account_id_rejected(client, auth_headers, admin_headers):
    category, sub = _seed_catalog(client, admin_headers)
    account = client.post(
        "/api/v1/accounts",
        json={
            "banco": "Nequi",
            "tipo": "digital",
            "moneda": "COP",
            "saldo_inicial": "100",
        },
        headers=auth_headers,
    ).json()

    resp = client.post(
        "/api/v1/transactions",
        json={
            "account_id": account["id"],
            "category_id": category["id"],
            "sub_category_id": sub["id"],
            "monto": "5",
            "tipo": "gasto",
            "medio_pago": "efectivo",
            "moneda": "COP",
            "fecha": "2026-07-13",
        },
        headers=auth_headers,
    )
    assert resp.status_code == 422


def test_cuenta_without_account_id_rejected(client, auth_headers, admin_headers):
    category, sub = _seed_catalog(client, admin_headers)

    resp = client.post(
        "/api/v1/transactions",
        json={
            "category_id": category["id"],
            "sub_category_id": sub["id"],
            "monto": "5",
            "tipo": "gasto",
            "medio_pago": "cuenta",
            "fecha": "2026-07-13",
        },
        headers=auth_headers,
    )
    assert resp.status_code == 422
