"""
wait_for_db.py
--------------

QUÉ ES
    Un script que pregunta a PostgreSQL: "¿ya estás listo?" hasta que responde sí.

POR QUÉ EXISTE
    Cuando haces `docker compose up`, el contenedor de la BD tarda unos segundos
    en aceptar conexiones. Si migrate o la API intentan conectar demasiado pronto,
    falla con "Connection refused" aunque la BD vaya a estar bien 3 segundos después.

QUÉ HACE
    Cada segundo ejecuta `SELECT 1` usando settings.DATABASE_URL
(armada desde POSTGRES_* en app.core.config, o override si existe).
    Si conecta → imprime OK y sale con código 0.
    Si tras ~30 intentos no conecta → sale con código 1 (error).

QUIÉN LO LLAMA
    - scripts/migrate.sh      (cuando desarrollas en tu PC)
    - scripts/entrypoint.sh   (cuando la API corre dentro de Docker)

NO CREA TABLAS
    Solo comprueba que el motor Postgres responde. Las tablas las crea Alembic.
"""

from __future__ import annotations

import sys
import time

from sqlalchemy import create_engine, text
from sqlalchemy.exc import OperationalError

from app.core.config import settings

MAX_ATTEMPTS = 30
SLEEP_SECONDS = 1


def main() -> int:
    """0 = BD lista; 1 = se agotó el tiempo de espera."""
    engine = create_engine(settings.DATABASE_URL, pool_pre_ping=True)

    for attempt in range(1, MAX_ATTEMPTS + 1):
        try:
            with engine.connect() as conn:
                conn.execute(text("SELECT 1"))
            print(f"OK: PostgreSQL responde en {settings.POSTGRES_HOST}:{settings.POSTGRES_PORT}")
            return 0
        except OperationalError as exc:
            print(
                f"Aún no... intento {attempt}/{MAX_ATTEMPTS} ({exc.__class__.__name__})",
                file=sys.stderr,
            )
            time.sleep(SLEEP_SECONDS)

    print(
        "ERROR: PostgreSQL no respondió a tiempo. ¿Corriste `docker compose up db -d`?",
        file=sys.stderr,
    )
    return 1


if __name__ == "__main__":
    raise SystemExit(main())
