# =============================================================================
# Dockerfile — Imagen de la API
# =============================================================================
# QUÉ ES:
#   Instrucciones para construir el contenedor del backend.
#
# POR QUÉ EXISTE:
#   Que la API corra igual en cualquier máquina (mismas libs, mismo Python).
#
# QUÉ NO HACE:
#   No crea tablas. Eso lo hace Alembic en el ENTRYPOINT (entrypoint.sh).
# =============================================================================

FROM python:3.12-slim

WORKDIR /app

# Sin .pyc; logs al instante en la consola de Docker.
# PYTHONPATH=/app: permite `import app` al correr scripts/ (p. ej. wait_for_db.py).
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PYTHONPATH=/app

# Herramientas para que psycopg2 (driver de Postgres) pueda instalarse.
RUN apt-get update && apt-get install -y --no-install-recommends \
    libpq-dev \
    gcc \
    && rm -rf /var/lib/apt/lists/*

COPY requirements.txt .
# Red lenta / Wi‑Fi inestable: más timeout y reintentos (evita ReadTimeoutError de PyPI).
RUN pip install --no-cache-dir --default-timeout=120 --retries=5 -r requirements.txt

COPY . .

RUN chmod +x scripts/entrypoint.sh scripts/migrate.sh

EXPOSE 8000

# Siempre: esperar BD + migrar. Luego: el CMD (uvicorn).
ENTRYPOINT ["/app/scripts/entrypoint.sh"]
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]
