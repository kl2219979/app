"""Schemas Pydantic del recurso Category."""

from datetime import datetime

from pydantic import BaseModel, ConfigDict, Field


class CategoryCreate(BaseModel):
    nombre: str = Field(min_length=1, max_length=100)
    descripcion: str = Field(default="", max_length=255)


class CategoryUpdate(BaseModel):
    nombre: str | None = Field(default=None, min_length=1, max_length=100)
    descripcion: str | None = Field(default=None, max_length=255)


class CategoryResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    nombre: str
    descripcion: str
    activo: bool
    creado_en: datetime
    actualizado_en: datetime
