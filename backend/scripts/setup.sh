#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# setup.sh
# -----------------------------------------------------------------------------
# QUÉ ES:
#   Preparación inicial del proyecto en tu máquina (una vez, o cuando cambien deps).
#
# POR QUÉ EXISTE:
#   Evita pasos manuales olvidados: venv, pip install, archivo .env, permisos.
#
# QUÉ HACE:
#   - Crea .venv si no existe O si está incompleto (falta activate/pip)
#   - Instala requirements-dev.txt (app + pytest + ruff)
#   - Copia .env.example → .env si aún no tienes .env
#   - Da permiso de ejecución a migrate/entrypoint
#
# QUÉ NO HACE:
#   No enciende la base ni la API. Eso lo haces después (ver mensajes al final).
#
# Guía completa: docs/COMO_FUNCIONA.md
# -----------------------------------------------------------------------------
set -euo pipefail

cd "$(dirname "$0")/.."

# -----------------------------------------------------------------------------
# Paso 1: entorno virtual (.venv)
# -----------------------------------------------------------------------------
# Un venv es una carpeta con su propio Python y pip, aislado del sistema.
# Así las librerías del proyecto no se mezclan con las del resto de tu PC.
#
# A veces queda una carpeta .venv "a medias" (sin activate ni pip).
# En ese caso hay que borrarla y crearla de nuevo.
# -----------------------------------------------------------------------------
venv_ok=false
if [ -f ".venv/bin/activate" ] && [ -x ".venv/bin/python" ]; then
  venv_ok=true
fi

if [ "$venv_ok" = false ]; then
  if [ -d ".venv" ]; then
    echo "[setup] La carpeta .venv existe pero está incompleta (falta activate/pip)."
    echo "[setup] La borro y la vuelvo a crear..."
    rm -rf .venv
  else
    echo "[setup] Creando entorno virtual .venv ..."
  fi

  # Si esto falla en Ubuntu/Debian, instala: sudo apt install python3-venv python3-pip
  if ! python3 -m venv .venv; then
    echo ""
    echo "[setup] ERROR: no se pudo crear el entorno virtual."
    echo "        En Ubuntu/Debian suele faltar el paquete python3-venv:"
    echo "          sudo apt update && sudo apt install python3-venv python3-pip"
    echo "        Luego vuelve a correr: ./scripts/setup.sh"
    exit 1
  fi
else
  echo "[setup] Entorno virtual .venv ya existe y se ve completo."
fi

# shellcheck disable=SC1091
source .venv/bin/activate

# -----------------------------------------------------------------------------
# Paso 2: instalar dependencias
# -----------------------------------------------------------------------------
# pip lee requirements-dev.txt e instala FastAPI, SQLAlchemy, Alembic, pytest, etc.
# -----------------------------------------------------------------------------
echo "[setup] Instalando dependencias (puede tardar un poco)..."
pip install -r requirements-dev.txt

# -----------------------------------------------------------------------------
# Paso 3: archivo .env
# -----------------------------------------------------------------------------
# La app lee contraseñas/URLs desde .env (no se sube a Git).
# .env.example es la plantilla segura para clonar.
# -----------------------------------------------------------------------------
if [ ! -f ".env" ]; then
  cp .env.example .env
  echo "[setup] Creado .env a partir de .env.example (ajusta secretos si hace falta)."
else
  echo "[setup] Ya existe .env; no lo sobrescribo."
fi

chmod +x scripts/migrate.sh scripts/entrypoint.sh

echo ""
echo "[setup] Entorno listo."
echo ""
echo "Siguiente (BD desacoplada + Alembic crea las tablas):"
echo "  1. docker compose up db -d"
echo "  2. ./scripts/migrate.sh"
echo "  3. source .venv/bin/activate && uvicorn app.main:app --reload"
echo ""
echo "Lee docs/COMO_FUNCIONA.md si quieres entender el porqué de cada paso."
echo "O todo junto: docker compose up --build"
