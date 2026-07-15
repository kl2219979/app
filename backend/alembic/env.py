"""
alembic/env.py
--------------

QUÉ ES
    El "cerebro" de Alembic: sabe a qué BD conectarse y qué modelos mirar.

POR QUÉ EXISTE
    La base desacoplada nace vacía. Necesitamos una herramienta que:
      - compare tus modelos Python con lo que hay en Postgres, y
      - cree/altere tablas de forma versionada (archivos en alembic/versions/).

    Sin Alembic tendrías que escribir SQL a mano cada vez que cambia el esquema,
    y sería fácil que tu compañero tenga tablas distintas a las tuyas.

CÓMO SE USA (tú no editas este archivo a diario)
    alembic revision --autogenerate -m "descripcion"  → genera un archivo de cambio
    alembic upgrade head                              → aplica los cambios a la BD
    (o simplemente ./scripts/migrate.sh)

PARTES IMPORTANTES
    - settings.DATABASE_URL → a qué Postgres conectarse
    - import app.models     → para que Alembic "vea" tus clases
    - Base.metadata         → catálogo de tablas definidas en el código
"""

from logging.config import fileConfig

from alembic import context
from sqlalchemy import engine_from_config, pool

from app.core.config import settings
from app.db.base import Base

# Sin importar models, Alembic cree que no hay tablas que migrar.
import app.models  # noqa: F401

config = context.config

if config.config_file_name is not None:
    fileConfig(config.config_file_name)

# La URL del alembic.ini es un placeholder; la real viene del .env.
config.set_main_option("sqlalchemy.url", settings.DATABASE_URL)

target_metadata = Base.metadata


def run_migrations_offline() -> None:
    """Modo offline: escribe SQL sin conectarse (útil para revisar/CI)."""
    url = config.get_main_option("sqlalchemy.url")
    context.configure(
        url=url,
        target_metadata=target_metadata,
        literal_binds=True,
        dialect_opts={"paramstyle": "named"},
    )

    with context.begin_transaction():
        context.run_migrations()


def run_migrations_online() -> None:
    """Modo online (el normal): se conecta a Postgres y aplica migraciones."""
    connectable = engine_from_config(
        config.get_section(config.config_ini_section, {}),
        prefix="sqlalchemy.",
        poolclass=pool.NullPool,
    )

    with connectable.connect() as connection:
        context.configure(connection=connection, target_metadata=target_metadata)

        with context.begin_transaction():
            context.run_migrations()


if context.is_offline_mode():
    run_migrations_offline()
else:
    run_migrations_online()
