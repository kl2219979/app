"""Schemas Pydantic del recurso Transaction."""

from datetime import date, datetime
from decimal import Decimal
from typing import Literal, Self

from pydantic import BaseModel, ConfigDict, Field, model_validator

TransactionTipo = Literal[
    "gasto",
    "ingreso",
    "transferencia_salida",
    "transferencia_entrada",
]
MedioPago = Literal["cuenta", "efectivo"]


class TransactionCreate(BaseModel):
    account_id: int | None = Field(default=None, gt=0)
    category_id: int = Field(gt=0)
    sub_category_id: int = Field(gt=0)
    monto: Decimal = Field(gt=0)
    tipo: Literal["gasto", "ingreso"] = "gasto"
    medio_pago: MedioPago = "cuenta"
    moneda: str | None = Field(default=None, min_length=1, max_length=10)
    contraparte_id: int | None = Field(default=None, gt=0)
    fecha: date
    descripcion: str = Field(default="", max_length=255)

    @model_validator(mode="after")
    def validate_medio_pago(self) -> Self:
        if self.medio_pago == "cuenta":
            if self.account_id is None:
                raise ValueError("account_id es obligatorio cuando medio_pago=cuenta")
        else:
            if self.account_id is not None:
                raise ValueError(
                    "No envíes account_id cuando medio_pago=efectivo; usa moneda"
                )
            if self.moneda is None:
                raise ValueError("moneda es obligatoria cuando medio_pago=efectivo")
        return self


class TransactionUpdate(BaseModel):
    account_id: int | None = Field(default=None, gt=0)
    category_id: int | None = Field(default=None, gt=0)
    sub_category_id: int | None = Field(default=None, gt=0)
    monto: Decimal | None = Field(default=None, gt=0)
    tipo: Literal["gasto", "ingreso"] | None = None
    medio_pago: MedioPago | None = None
    moneda: str | None = Field(default=None, min_length=1, max_length=10)
    contraparte_id: int | None = Field(default=None, gt=0)
    fecha: date | None = None
    descripcion: str | None = Field(default=None, max_length=255)


class TransferCreate(BaseModel):
    """Mueve dinero entre dos cuentas propias (misma moneda)."""

    from_account_id: int = Field(gt=0)
    to_account_id: int = Field(gt=0)
    monto: Decimal = Field(gt=0)
    fecha: date
    descripcion: str = Field(default="Transferencia entre cuentas", max_length=255)
    category_id: int = Field(gt=0)
    sub_category_id: int = Field(gt=0)


class TransactionResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    account_id: int
    category_id: int
    sub_category_id: int
    contraparte_id: int | None = None
    monto: Decimal
    tipo: TransactionTipo
    medio_pago: MedioPago
    fecha: date
    descripcion: str
    activo: bool
    grupo_transferencia: str | None = None
    creado_en: datetime
    actualizado_en: datetime


class TransferResponse(BaseModel):
    grupo_transferencia: str
    salida: TransactionResponse
    entrada: TransactionResponse
