"""
app/db/session.py — Cable hacia PostgreSQL
------------------------------------------

QUÉ ES
    Crea el "motor" SQLAlchemy y la fábrica de sesiones (`SessionLocal`).

POR QUÉ EXISTE
    La API necesita abrir conexiones a la BD desacoplada de forma ordenada.
    Este archivo concentra esa configuración en un solo sitio.

QUÉ NO HACE
    No decide reglas de negocio ni crea tablas.
    - Tablas → Alembic
    - Reglas → services
    - SQL de CRUD → repositories (usando SessionLocal / get_db)

pool_pre_ping=True
    Antes de reutilizar una conexión, comprueba que siga viva.
    Útil si reiniciaste el contenedor db mientras la API seguía arriba.
"""

from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker

from app.core.config import settings

engine = create_engine(
    settings.DATABASE_URL,
    pool_pre_ping=True,
)

# El código que usa la sesión decide cuándo hacer commit (no automático).
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
