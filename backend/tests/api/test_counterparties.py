"""
Integration (API) — smoke CRUD de counterparties (JWT + SQLite).
"""

import pytest

pytestmark = pytest.mark.integration


def test_counterparties_require_auth(client):
    response = client.get("/api/v1/counterparties")
    assert response.status_code == 401


def test_create_list_update_deactivate_counterparty(client, auth_headers):
    payload = {
        "nombre": "Carlos Ruiz",
        "banco": "Davivienda",
        "numero_cuenta": "555444",
        "notas": "Arriendo",
    }

    create_resp = client.post(
        "/api/v1/counterparties", json=payload, headers=auth_headers
    )
    assert create_resp.status_code == 201, create_resp.text
    created = create_resp.json()
    assert created["nombre"] == "Carlos Ruiz"
    assert created["activo"] is True
    cp_id = created["id"]

    listed = client.get("/api/v1/counterparties", headers=auth_headers)
    assert listed.status_code == 200
    assert listed.json()["total"] == 1

    upd = client.put(
        f"/api/v1/counterparties/{cp_id}",
        json={"nombre": "Carlos R."},
        headers=auth_headers,
    )
    assert upd.status_code == 200
    assert upd.json()["nombre"] == "Carlos R."

    deleted = client.delete(f"/api/v1/counterparties/{cp_id}", headers=auth_headers)
    assert deleted.status_code == 204
    assert client.get("/api/v1/counterparties", headers=auth_headers).json()["total"] == 0

    get_inactive = client.get(f"/api/v1/counterparties/{cp_id}", headers=auth_headers)
    assert get_inactive.status_code == 200
    assert get_inactive.json()["activo"] is False

    reactivated = client.post(
        f"/api/v1/counterparties/{cp_id}/reactivate",
        headers=auth_headers,
    )
    assert reactivated.status_code == 200
    assert reactivated.json()["activo"] is True
