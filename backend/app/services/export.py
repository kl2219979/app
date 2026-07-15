"""Export de movimientos del usuario (CSV / JSON)."""

from __future__ import annotations

import csv
import io
import json
from datetime import date
from decimal import Decimal

from fastapi import HTTPException, status
from fastapi.responses import Response, StreamingResponse
from sqlalchemy.orm import Session

from app.models.user import User
from app.repositories.transaction import TransactionRepository
from app.services.transaction import TransactionService


def _serialize_row(item) -> dict:
    return {
        "id": item.id,
        "account_id": item.account_id,
        "category_id": item.category_id,
        "sub_category_id": item.sub_category_id,
        "contraparte_id": item.contraparte_id,
        "monto": str(Decimal(item.monto)),
        "tipo": item.tipo,
        "medio_pago": item.medio_pago,
        "fecha": item.fecha.isoformat(),
        "descripcion": item.descripcion,
        "activo": item.activo,
        "grupo_transferencia": item.grupo_transferencia,
    }


class ExportService:
    @staticmethod
    def export_transactions(
        db: Session,
        current_user: User,
        *,
        fmt: str,
        account_id: int | None = None,
        category_id: int | None = None,
        sub_category_id: int | None = None,
        contraparte_id: int | None = None,
        medio_pago: str | None = None,
        tipo: str | None = None,
        date_from: date | None = None,
        date_to: date | None = None,
    ) -> Response:
        fmt = fmt.lower().strip()
        if fmt not in {"csv", "json"}:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="format debe ser csv o json",
            )

        # Reusa validaciones de ownership de list_mine (cuenta / contraparte).
        if account_id is not None or contraparte_id is not None:
            TransactionService.list_mine(
                db,
                current_user,
                account_id=account_id,
                contraparte_id=contraparte_id,
                limit=1,
                offset=0,
            )

        items, _ = TransactionRepository.list_filtered(
            db,
            user_id=current_user.id,
            account_id=account_id,
            category_id=category_id,
            sub_category_id=sub_category_id,
            contraparte_id=contraparte_id,
            medio_pago=medio_pago,
            tipo=tipo,
            date_from=date_from,
            date_to=date_to,
            only_active=True,
            limit=10_000,
            offset=0,
        )
        rows = [_serialize_row(i) for i in items]
        filename = "transactions_export"

        if fmt == "json":
            payload = json.dumps(
                {"total": len(rows), "items": rows},
                ensure_ascii=False,
                indent=2,
            )
            return Response(
                content=payload,
                media_type="application/json; charset=utf-8",
                headers={
                    "Content-Disposition": f'attachment; filename="{filename}.json"'
                },
            )

        buffer = io.StringIO()
        fieldnames = list(rows[0].keys()) if rows else [
            "id",
            "account_id",
            "category_id",
            "sub_category_id",
            "contraparte_id",
            "monto",
            "tipo",
            "medio_pago",
            "fecha",
            "descripcion",
            "activo",
            "grupo_transferencia",
        ]
        writer = csv.DictWriter(buffer, fieldnames=fieldnames)
        writer.writeheader()
        for row in rows:
            writer.writerow(row)
        return StreamingResponse(
            iter([buffer.getvalue()]),
            media_type="text/csv; charset=utf-8",
            headers={"Content-Disposition": f'attachment; filename="{filename}.csv"'},
        )
