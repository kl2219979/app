"""
app/repositories/user.py — Acceso a datos de User
=================================================

QUÉ ES
------
Consultas y persistencia de la tabla `users`.
Solo habla con SQLAlchemy (modelo User + Session).

QUÉ NO HACE
-----------
- No hashea contraseñas (eso es security.py / service).
- No valida JSON HTTP (eso es schema / endpoint).
- No hace commit: el service o endpoint decide cuándo `db.commit()`.
"""

from __future__ import annotations

from sqlalchemy import or_, select
from sqlalchemy.orm import Session

from app.models.user import User


class UserRepository:
    """Operaciones CRUD / lookup sobre User."""

    @staticmethod
    def get_by_id(db: Session, user_id: int) -> User | None:
        """Busca un usuario por clave primaria."""
        return db.get(User, user_id)

    @staticmethod
    def get_by_correo(db: Session, correo: str) -> User | None:
        """Busca por correo (único)."""
        return db.scalar(select(User).where(User.correo == correo))

    @staticmethod
    def get_by_usuario(db: Session, usuario: str) -> User | None:
        """Busca por nombre de usuario (único)."""
        return db.scalar(select(User).where(User.usuario == usuario))

    @staticmethod
    def get_by_correo_or_usuario(db: Session, value: str) -> User | None:
        """
        Busca por correo O por usuario (útil en login).
        `value` puede ser cualquiera de los dos.
        """
        return db.scalar(
            select(User).where(or_(User.correo == value, User.usuario == value))
        )

    @staticmethod
    def exists_correo_or_usuario(
        db: Session,
        *,
        correo: str,
        usuario: str,
    ) -> bool:
        """True si ya hay alguien con ese correo o ese usuario."""
        found = db.scalar(
            select(User.id).where(or_(User.correo == correo, User.usuario == usuario))
        )
        return found is not None

    @staticmethod
    def create(db: Session, user: User) -> User:
        """
        Inserta un User ya construido (con contrasena_hash listo).

        Hace flush para asignar `id` sin cerrar la transacción.
        El caller debe hacer db.commit().
        """
        db.add(user)
        db.flush()
        db.refresh(user)
        return user

    @staticmethod
    def update(db: Session, user: User) -> User:
        """Persiste cambios ya hechos sobre la instancia `user`."""
        db.add(user)
        db.flush()
        db.refresh(user)
        return user

    @staticmethod
    def delete(db: Session, user: User) -> None:
        """Elimina el usuario (flush; commit afuera)."""
        db.delete(user)
        db.flush()
