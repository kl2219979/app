"""counterparties + transaction medio_pago / contraparte_id

Revision ID: e5f6a7b8c9d0
Revises: d4e5f6a7b8c9
Create Date: 2026-07-13 16:00:00.000000

"""

from typing import Sequence, Union

import sqlalchemy as sa
from alembic import op

revision: str = "e5f6a7b8c9d0"
down_revision: Union[str, None] = "d4e5f6a7b8c9"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.create_table(
        "counterparties",
        sa.Column("id", sa.Integer(), autoincrement=True, nullable=False),
        sa.Column("user_id", sa.Integer(), nullable=False),
        sa.Column("nombre", sa.String(length=150), nullable=False),
        sa.Column("banco", sa.String(length=100), nullable=True),
        sa.Column("numero_cuenta", sa.String(length=100), nullable=True),
        sa.Column("notas", sa.Text(), nullable=True),
        sa.Column("activo", sa.Boolean(), nullable=False, server_default=sa.text("true")),
        sa.Column(
            "creado_en",
            sa.DateTime(timezone=True),
            server_default=sa.text("now()"),
            nullable=False,
        ),
        sa.Column(
            "actualizado_en",
            sa.DateTime(timezone=True),
            server_default=sa.text("now()"),
            nullable=False,
        ),
        sa.ForeignKeyConstraint(["user_id"], ["users.id"]),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index("ix_counterparties_user_id", "counterparties", ["user_id"])

    op.add_column(
        "transactions",
        sa.Column(
            "medio_pago",
            sa.String(length=20),
            nullable=False,
            server_default="cuenta",
        ),
    )
    op.add_column(
        "transactions",
        sa.Column("contraparte_id", sa.Integer(), nullable=True),
    )
    op.create_index("ix_transactions_contraparte_id", "transactions", ["contraparte_id"])
    op.create_foreign_key(
        "fk_transactions_contraparte_id_counterparties",
        "transactions",
        "counterparties",
        ["contraparte_id"],
        ["id"],
    )


def downgrade() -> None:
    op.drop_constraint(
        "fk_transactions_contraparte_id_counterparties",
        "transactions",
        type_="foreignkey",
    )
    op.drop_index("ix_transactions_contraparte_id", table_name="transactions")
    op.drop_column("transactions", "contraparte_id")
    op.drop_column("transactions", "medio_pago")
    op.drop_index("ix_counterparties_user_id", table_name="counterparties")
    op.drop_table("counterparties")
