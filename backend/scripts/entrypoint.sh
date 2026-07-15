#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# entrypoint.sh
# -----------------------------------------------------------------------------
# QUÉ ES:
#   El "arranque" del contenedor de la API. Docker lo ejecuta ANTES que Uvicorn.
#
# POR QUÉ EXISTE:
#   1) Postgres puede tardar unos segundos en estar listo.
#      Si la API arranca antes, falla al conectar.
#   2) Las tablas las crea Alembic, no el contenedor de la BD.
#      Hay que migrar antes de atender peticiones HTTP.
#
# ORDEN:
#   esperar BD  →  alembic upgrade head  →  lanzar el comando (uvicorn)
#
# exec "$@":
#   Reemplaza este script por el proceso final (uvicorn).
#   Así Docker puede detener/reiniciar bien la API.
# -----------------------------------------------------------------------------
set -euo pipefail

cd /app
# Sin esto, `python scripts/wait_for_db.py` no encuentra el paquete `app`.
export PYTHONPATH="/app${PYTHONPATH:+:$PYTHONPATH}"

echo "[entrypoint] 1/3 Esperando a que PostgreSQL acepte conexiones..."
python scripts/wait_for_db.py

echo "[entrypoint] 2/3 Aplicando esquema con Alembic..."
alembic upgrade head

echo "[entrypoint] 3/3 Arrancando la API: $*"
exec "$@"
