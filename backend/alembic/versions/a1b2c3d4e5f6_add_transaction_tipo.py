"""add transaction tipo and index helpers

Revision ID: a1b2c3d4e5f6
Revises: 72b0c849201b
Create Date: 2026-07-12 18:30:00.000000

"""

from typing import Sequence, Union

import sqlalchemy as sa
from alembic import op

revision: str = "a1b2c3d4e5f6"
down_revision: Union[str, None] = "72b0c849201b"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.add_column(
        "transactions",
        sa.Column("tipo", sa.String(length=20), nullable=False, server_default="gasto"),
    )


def downgrade() -> None:
    op.drop_column("transactions", "tipo")
