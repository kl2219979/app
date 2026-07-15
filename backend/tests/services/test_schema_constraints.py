"""Unit — schema constraints that Postgres enforces and SQLite may hide."""

import pytest

from app.models.transaction import Transaction

pytestmark = pytest.mark.unit


def test_transaction_tipo_column_fits_transfer_labels():
    """
    transferencia_salida / transferencia_entrada are 21 chars.
    A String(20) migration breaks Postgres inserts even if unit tests pass on SQLite.
    """
    length = Transaction.__table__.c.tipo.type.length
    assert length is not None and length >= 30
    assert len("transferencia_salida") <= length
    assert len("transferencia_entrada") <= length
