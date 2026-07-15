"""
Integration (API) — smoke CRUD de categories / subcategories.
Escritura requiere admin.
"""

import pytest

pytestmark = pytest.mark.integration


def test_categories_require_auth(client):
    response = client.get("/api/v1/categories")
    assert response.status_code == 401


def test_category_create_forbidden_for_non_admin(client, auth_headers):
    response = client.post(
        "/api/v1/categories",
        json={"nombre": "Ocio", "descripcion": ""},
        headers=auth_headers,
    )
    assert response.status_code == 403


def test_category_and_subcategory_crud_smoke(client, admin_headers):
    create_cat = client.post(
        "/api/v1/categories",
        json={"nombre": "Ocio", "descripcion": "Entretenimiento"},
        headers=admin_headers,
    )
    assert create_cat.status_code == 201, create_cat.text
    cat_id = create_cat.json()["id"]

    create_sub = client.post(
        "/api/v1/subcategories",
        json={"category_id": cat_id, "nombre": "Cine", "descripcion": ""},
        headers=admin_headers,
    )
    assert create_sub.status_code == 201, create_sub.text
    sub_id = create_sub.json()["id"]

    listed = client.get(
        f"/api/v1/subcategories?category_id={cat_id}",
        headers=admin_headers,
    )
    assert listed.status_code == 200
    body = listed.json()
    assert body["total"] == 1
    assert len(body["items"]) == 1

    assert (
        client.delete(f"/api/v1/subcategories/{sub_id}", headers=admin_headers).status_code
        == 204
    )
    assert (
        client.delete(f"/api/v1/categories/{cat_id}", headers=admin_headers).status_code
        == 204
    )
    # Soft-delete: aún se puede obtener, pero activo=false
    got = client.get(f"/api/v1/categories/{cat_id}", headers=admin_headers)
    assert got.status_code == 200
    assert got.json()["activo"] is False
