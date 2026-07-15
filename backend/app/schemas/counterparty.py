"""Schemas Pydantic del recurso Counterparty (contraparte externa)."""

from datetime import datetime

from pydantic import BaseModel, ConfigDict, Field


class CounterpartyCreate(BaseModel):
    nombre: str = Field(min_length=1, max_length=150)
    banco: str | None = Field(default=None, max_length=100)
    numero_cuenta: str | None = Field(default=None, max_length=100)
    notas: str | None = None


class CounterpartyUpdate(BaseModel):
    model_config = ConfigDict(extra="forbid")

    nombre: str | None = Field(default=None, min_length=1, max_length=150)
    banco: str | None = Field(default=None, max_length=100)
    numero_cuenta: str | None = Field(default=None, max_length=100)
    notas: str | None = None


class CounterpartyResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    user_id: int
    nombre: str
    banco: str | None
    numero_cuenta: str | None
    notas: str | None
    activo: bool
    creado_en: datetime
    actualizado_en: datetime
