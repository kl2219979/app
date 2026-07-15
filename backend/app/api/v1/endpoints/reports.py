"""
app/api/v1/endpoints/reports.py — Resumen agregado (dashboard)
"""

from datetime import date

from fastapi import APIRouter, Depends, Query
from sqlalchemy.orm import Session

from app.api.deps import get_current_user, get_db
from app.models.user import User
from app.schemas.report import ReportSummary
from app.services.report import ReportService

router = APIRouter(prefix="/reports", tags=["reports"])


@router.get("/summary", response_model=ReportSummary)
def get_summary(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
    account_id: int | None = Query(default=None, gt=0),
    date_from: date | None = Query(default=None),
    date_to: date | None = Query(default=None),
) -> ReportSummary:
    return ReportService.summary(
        db,
        current_user,
        account_id=account_id,
        date_from=date_from,
        date_to=date_to,
    )
