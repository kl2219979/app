#!/usr/bin/env python3
"""
scripts/seed.py — CLI para cargar categorías iniciales

Uso:
  docker compose up db -d
  ./scripts/migrate.sh
  python scripts/seed.py
"""

from __future__ import annotations

import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))

from app.db.session import SessionLocal
from app.services.seed import seed_categories


def main() -> None:
    db = SessionLocal()
    try:
        cats, subs = seed_categories(db)
        print(f"[seed] Categorías nuevas: {cats} | Subcategorías nuevas: {subs}")
        print("[seed] Listo (idempotente: puedes volver a correrlo).")
    finally:
        db.close()


if __name__ == "__main__":
    main()
