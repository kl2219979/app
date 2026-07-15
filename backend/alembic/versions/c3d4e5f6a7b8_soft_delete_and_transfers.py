"""soft delete activo and transfer group

Revision ID: c3d4e5f6a7b8
Revises: b2c3d4e5f6a7
Create Date: 2026-07-12 19:20:00.000000

"""

from typing import Sequence, Union

import sqlalchemy as sa
from alembic import op

revision: str = "c3d4e5f6a7b8"
down_revision: Union[str, None] = "b2c3d4e5f6a7"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    for table in ("users", "accounts", "categories", "sub_categories", "transactions"):
        op.add_column(
            table,
            sa.Column("activo", sa.Boolean(), nullable=False, server_default=sa.text("true")),
        )
    op.add_column(
        "transactions",
        sa.Column("grupo_transferencia", sa.String(length=36), nullable=True),
    )
    op.create_index(
        "ix_transactions_grupo_transferencia",
        "transactions",
        ["grupo_transferencia"],
    )


def downgrade() -> None:
    op.drop_index("ix_transactions_grupo_transferencia", table_name="transactions")
    op.drop_column("transactions", "grupo_transferencia")
    for table in ("transactions", "sub_categories", "categories", "accounts", "users"):
        op.drop_column(table, "activo")
