"""
app/schemas/ — Contratos HTTP (Pydantic)

Convención: PascalCase (AccountCreate, CategoryResponse, …).
Importar desde el submódulo concreto: from app.schemas.account import AccountCreate
"""

from app.schemas.account import AccountCreate, AccountResponse, AccountUpdate
from app.schemas.auth import Token, UserPublic, UserRegister
from app.schemas.category import CategoryCreate, CategoryResponse, CategoryUpdate
from app.schemas.pagination import Page, PageParams
from app.schemas.report import AccountSnapshot, CategoryBreakdown, MonthBucket, ReportSummary
from app.schemas.sub_category import SubCategoryCreate, SubCategoryResponse, SubCategoryUpdate
from app.schemas.transaction import (
    TransactionCreate,
    TransactionResponse,
    TransactionUpdate,
    TransferCreate,
    TransferResponse,
)
from app.schemas.user import UserCreate, UserResponse, UserUpdate

__all__ = [
    "AccountCreate",
    "AccountResponse",
    "AccountSnapshot",
    "AccountUpdate",
    "CategoryBreakdown",
    "CategoryCreate",
    "CategoryResponse",
    "CategoryUpdate",
    "MonthBucket",
    "Page",
    "PageParams",
    "ReportSummary",
    "SubCategoryCreate",
    "SubCategoryResponse",
    "SubCategoryUpdate",
    "Token",
    "TransactionCreate",
    "TransactionResponse",
    "TransactionUpdate",
    "TransferCreate",
    "TransferResponse",
    "UserCreate",
    "UserPublic",
    "UserRegister",
    "UserResponse",
    "UserUpdate",
]
