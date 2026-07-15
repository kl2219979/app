"""
app/services/seed.py — Catálogo inicial de categorías / subcategorías
=====================================================================

Idempotente: solo crea lo que falta (por nombre de categoría / subcategoría).
"""

from __future__ import annotations

from sqlalchemy.orm import Session

from app.models.category import Category
from app.models.sub_category import SubCategory
from app.repositories.category import CategoryRepository
from app.repositories.sub_category import SubCategoryRepository

SEED_CATALOG: dict[str, list[str]] = {
    "Alimentación": ["Supermercado", "Restaurante", "Café"],
    "Transporte": ["Combustible", "Transporte público", "Taxi / apps"],
    "Vivienda": ["Arriendo", "Servicios", "Mantenimiento"],
    "Salud": ["Medicamentos", "Consultas"],
    "Ocio": ["Cine", "Suscripciones", "Salidas"],
    "Educación": ["Cursos", "Libros"],
    "Ingresos": ["Salario", "Freelance", "Otros ingresos"],
    "Transferencias": ["Entre mis cuentas"],
}


def seed_categories(db: Session) -> tuple[int, int]:
    """Inserta catálogo base. Retorna (categorías_nuevas, subcategorías_nuevas)."""
    created_cats = 0
    created_subs = 0

    for cat_name, sub_names in SEED_CATALOG.items():
        category = CategoryRepository.get_by_nombre(db, cat_name)
        if category is None:
            category = Category(nombre=cat_name, descripcion=f"Categoría seed: {cat_name}")
            CategoryRepository.create(db, category)
            created_cats += 1

        existing = {s.nombre for s in SubCategoryRepository.list_by_category(db, category.id)}
        for sub_name in sub_names:
            if sub_name in existing:
                continue
            SubCategoryRepository.create(
                db,
                SubCategory(
                    category_id=category.id,
                    nombre=sub_name,
                    descripcion="",
                ),
            )
            created_subs += 1

    db.commit()
    return created_cats, created_subs
