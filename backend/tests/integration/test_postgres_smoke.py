"""
Integration — smoke opcional contra PostgreSQL real.

No corre en el flujo diario (`pytest`). Solo con:
  RUN_INTEGRATION=1 TEST_DATABASE_URL=postgresql+psycopg2://... pytest -m postgres

Requisitos:
  - Postgres accesible (p. ej. `docker compose up db -d`)
  - Esquema aplicado (`./scripts/migrate.sh` / `alembic upgrade head`)
  - Preferible una BD dedicada de test (no la de desarrollo con datos importantes)
"""

from __future__ import annotations

import os

import pytest
from sqlalchemy import create_engine, text

pytestmark = [pytest.mark.integration, pytest.mark.postgres]


@pytest.fixture()
def postgres_engine(postgres_url: str | None):
    if not postgres_url:
        pytest.skip(
            "Integration Postgres deshabilitada. "
            "Exporta RUN_INTEGRATION=1 y TEST_DATABASE_URL (o DATABASE_URL)."
        )
    if not postgres_url.startswith("postgresql"):
        pytest.skip(f"TEST_DATABASE_URL no es Postgres: {postgres_url!r}")
    engine = create_engine(postgres_url)
    try:
        yield engine
    finally:
        engine.dispose()


def test_postgres_accepts_connection_and_has_alembic_version(postgres_engine):
    # Arrange / Act
    with postgres_engine.connect() as conn:
        one = conn.execute(text("SELECT 1")).scalar()
        version = conn.execute(
            text("SELECT version_num FROM alembic_version LIMIT 1")
        ).scalar()

    # Assert
    assert one == 1
    assert version is not None
    assert os.getenv("RUN_INTEGRATION", "").lower() in {"1", "true", "yes"}


def test_postgres_transaction_tipo_fits_transfer_labels(postgres_engine):
    with postgres_engine.connect() as conn:
        length = conn.execute(
            text(
                """
                SELECT character_maximum_length
                FROM information_schema.columns
                WHERE table_schema = 'public'
                  AND table_name = 'transactions'
                  AND column_name = 'tipo'
                """
            )
        ).scalar()

    assert length is not None and length >= len("transferencia_salida")
    assert length >= len("transferencia_entrada")
