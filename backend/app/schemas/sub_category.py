"""Schemas Pydantic del recurso SubCategory."""

from datetime import datetime

from pydantic import BaseModel, ConfigDict, Field


class SubCategoryCreate(BaseModel):
    category_id: int = Field(gt=0)
    nombre: str = Field(min_length=1, max_length=100)
    descripcion: str = Field(default="", max_length=255)


class SubCategoryUpdate(BaseModel):
    category_id: int | None = Field(default=None, gt=0)
    nombre: str | None = Field(default=None, min_length=1, max_length=100)
    descripcion: str | None = Field(default=None, max_length=255)


class SubCategoryResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    category_id: int
    nombre: str
    descripcion: str
    activo: bool
    creado_en: datetime
    actualizado_en: datetime
