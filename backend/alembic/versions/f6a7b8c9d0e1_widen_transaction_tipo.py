"""widen transactions.tipo to fit transferencia_* values

Revision ID: f6a7b8c9d0e1
Revises: e5f6a7b8c9d0
Create Date: 2026-07-13 16:10:00.000000

"""

from typing import Sequence, Union

import sqlalchemy as sa
from alembic import op

revision: str = "f6a7b8c9d0e1"
down_revision: Union[str, None] = "e5f6a7b8c9d0"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    # transferencia_salida / transferencia_entrada are 21 chars; model uses String(30).
    op.alter_column(
        "transactions",
        "tipo",
        existing_type=sa.String(length=20),
        type_=sa.String(length=30),
        existing_nullable=False,
        existing_server_default=sa.text("'gasto'"),
    )


def downgrade() -> None:
    op.alter_column(
        "transactions",
        "tipo",
        existing_type=sa.String(length=30),
        type_=sa.String(length=20),
        existing_nullable=False,
        existing_server_default=sa.text("'gasto'"),
    )
