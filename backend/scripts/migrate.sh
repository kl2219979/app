#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# migrate.sh
# -----------------------------------------------------------------------------
# QUÉ ES:
#   Comando para crear/actualizar las TABLAS en PostgreSQL desde tu PC.
#
# POR QUÉ EXISTE:
#   La BD desacoplada nace vacía (solo el motor).
#   Quien define tablas/columnas es el backend, vía Alembic + modelos.
#   Este script es la forma cómoda de aplicar eso en desarrollo local.
#
# CUÁNDO USARLO:
#   - Después de `docker compose up db -d`
#   - Después de generar una migración nueva (`alembic revision --autogenerate`)
#
# QUÉ HACE POR DENTRO:
#   1) Activa el .venv si existe
#   2) Espera a Postgres (wait_for_db.py)
#   3) Corre: alembic upgrade head
# -----------------------------------------------------------------------------
set -euo pipefail

cd "$(dirname "$0")/.."
# Raíz del repo en el path de Python (para `import app` desde scripts/).
export PYTHONPATH="$(pwd)${PYTHONPATH:+:$PYTHONPATH}"

if [ -f ".venv/bin/activate" ]; then
  # shellcheck disable=SC1091
  source .venv/bin/activate
fi

echo "[migrate] Esperando PostgreSQL..."
python scripts/wait_for_db.py

echo "[migrate] Aplicando migraciones..."
alembic upgrade head

echo "[migrate] Listo. El esquema de la BD quedó al día con el código."
