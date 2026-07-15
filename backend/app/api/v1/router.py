"""
app/api/v1/router.py — Índice de rutas v1
"""

from fastapi import APIRouter

from app.api.v1.endpoints import (
    account,
    auth,
    budget,
    category,
    counterparty,
    health,
    reports,
    sub_category,
    transaction,
    users,
    webhooks,
)

api_router = APIRouter()
api_router.include_router(health.router, tags=["health"])
api_router.include_router(auth.router, tags=["auth"])
api_router.include_router(users.router)
api_router.include_router(account.router)
api_router.include_router(counterparty.router)
api_router.include_router(budget.router)
api_router.include_router(category.router)
api_router.include_router(sub_category.router)
api_router.include_router(transaction.router)
api_router.include_router(reports.router)
api_router.include_router(webhooks.router)
