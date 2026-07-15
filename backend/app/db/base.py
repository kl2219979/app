"""
app/db/base.py — Raíz de los modelos
------------------------------------

QUÉ ES
    La clase `Base`. Todos los modelos ORM heredan de ella:
        class User(Base): ...

POR QUÉ EXISTE
    SQLAlchemy y Alembic necesitan un "registro" de tablas del código.
    Ese registro es `Base.metadata`.
    Si no heredas de Base, Alembic no sabrá que tu tabla existe.
"""

from sqlalchemy.orm import DeclarativeBase


class Base(DeclarativeBase):
    """Clase padre de todas las entidades de base de datos."""
