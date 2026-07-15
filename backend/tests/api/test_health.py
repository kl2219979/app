"""
Integration (API) — healthcheck.
"""

import pytest

pytestmark = pytest.mark.integration


def test_health_check_returns_ok(client):
    # Arrange
    # (el fixture `client` ya prepara el TestClient)

    # Act
    response = client.get("/api/v1/health")

    # Assert
    assert response.status_code == 200
    body = response.json()
    assert body["status"] == "ok"
