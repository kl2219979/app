"""
app/models/ — Modelos SQLAlchemy (entidades ↔ tablas).

QUÉ ES
    Cada archivo define una clase que hereda de Base = una tabla en Postgres.

CÓMO AGREGAR UN MODELO NUEVO
    1. Crea app/models/mi_entidad.py con class MiEntidad(Base): ...
    2. Impórtalo aquí (si no, Alembic no lo detecta).
    3. alembic revision --autogenerate -m "descripcion"
    4. ./scripts/migrate.sh

MAPA DE RELACIONES
    Ver docs/MODELS.md

IMPORTANTE
    Definir el modelo NO inserta filas.
    INSERT/UPDATE los hacen services + repositories.
"""

from app.models.account import Account  # noqa: F401
from app.models.budget import Budget  # noqa: F401
from app.models.category import Category  # noqa: F401
from app.models.counterparty import Counterparty  # noqa: F401
from app.models.refresh_token import RefreshToken  # noqa: F401
from app.models.sub_category import SubCategory  # noqa: F401
from app.models.transaction import Transaction  # noqa: F401
from app.models.user import User  # noqa: F401
