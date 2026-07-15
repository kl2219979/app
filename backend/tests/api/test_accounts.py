"""
Integration (API) — smoke CRUD de accounts (JWT + SQLite).
"""

import pytest

pytestmark = pytest.mark.integration


def test_create_and_list_account(client, auth_headers):
    payload = {
        "banco": "Bancolombia",
        "tipo": "ahorros",
        "moneda": "COP",
        "saldo_inicial": "1000.00",
    }

    create_resp = client.post("/api/v1/accounts", json=payload, headers=auth_headers)
    list_resp = client.get("/api/v1/accounts", headers=auth_headers)

    assert create_resp.status_code == 201, create_resp.text
    created = create_resp.json()
    assert created["banco"] == "Bancolombia"
    assert created["saldo"] == "1000.00"
    assert created["activo"] is True

    assert list_resp.status_code == 200
    page = list_resp.json()
    assert page["total"] == 1
    assert page["items"][0]["id"] == created["id"]


def test_accounts_require_auth(client):
    response = client.get("/api/v1/accounts")
    assert response.status_code == 401


def test_get_update_deactivate_account(client, auth_headers):
    created = client.post(
        "/api/v1/accounts",
        json={
            "banco": "Nequi",
            "tipo": "digital",
            "moneda": "COP",
            "saldo_inicial": "50",
        },
        headers=auth_headers,
    ).json()
    account_id = created["id"]

    get_resp = client.get(f"/api/v1/accounts/{account_id}", headers=auth_headers)
    upd_resp = client.put(
        f"/api/v1/accounts/{account_id}",
        json={"banco": "Nequi Pro"},
        headers=auth_headers,
    )
    # saldo no es editable por PUT
    bad_saldo = client.put(
        f"/api/v1/accounts/{account_id}",
        json={"saldo": "999"},
        headers=auth_headers,
    )
    del_resp = client.delete(f"/api/v1/accounts/{account_id}", headers=auth_headers)
    still_there = client.get(f"/api/v1/accounts/{account_id}", headers=auth_headers)
    listed = client.get("/api/v1/accounts", headers=auth_headers)

    assert get_resp.status_code == 200
    assert upd_resp.status_code == 200
    assert upd_resp.json()["banco"] == "Nequi Pro"
    assert bad_saldo.status_code == 422
    assert del_resp.status_code == 204
    assert still_there.status_code == 200
    assert still_there.json()["activo"] is False
    assert listed.json()["total"] == 0
