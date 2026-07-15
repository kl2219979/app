"""
Schemas de paginación reutilizables.
"""

from typing import Generic, TypeVar

from pydantic import BaseModel, Field

T = TypeVar("T")


class PageParams(BaseModel):
    """
    Query params tipados para paginación.

    Reservado para unificar limit/offset vía Depends(PageParams) en endpoints.
    Hoy los endpoints declaran Query(...) directamente.
    """

    limit: int = Field(default=20, ge=1, le=100)
    offset: int = Field(default=0, ge=0)


class Page(BaseModel, Generic[T]):
    """Respuesta paginada estándar."""

    items: list[T]
    total: int = Field(ge=0)
    limit: int = Field(ge=1)
    offset: int = Field(ge=0)
