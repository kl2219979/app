#!/usr/bin/env python3
"""
scripts/promote_admin.py — Promueve un usuario a rol admin

Uso:
  python scripts/promote_admin.py ana95
"""

from __future__ import annotations

import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))

from app.db.session import SessionLocal
from app.repositories.user import UserRepository


def main() -> None:
    if len(sys.argv) != 2:
        print("Uso: python scripts/promote_admin.py <usuario_o_correo>")
        sys.exit(1)
    value = sys.argv[1]
    db = SessionLocal()
    try:
        user = UserRepository.get_by_correo_or_usuario(db, value)
        if user is None:
            print(f"[promote] No existe usuario: {value}")
            sys.exit(1)
        user.rol = "admin"
        UserRepository.update(db, user)
        db.commit()
        print(f"[promote] {user.usuario} ahora es admin (id={user.id})")
        print("[promote] Activa MFA: POST /auth/mfa/setup → confirm (obligatorio para catálogo)")
    finally:
        db.close()


if __name__ == "__main__":
    main()
