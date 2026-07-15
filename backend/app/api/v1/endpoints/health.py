"""
app/api/v1/endpoints/health.py
------------------------------

QUÉ ES
    Un endpoint simple: GET /api/v1/health → {"status": "ok"}

POR QUÉ EXISTE
    Para comprobar rápido que la API está viva (navegador, Docker, monitoreo).
    No consulta la base de datos a propósito: si Postgres cae, igual puedes
    saber si el proceso HTTP sigue corriendo.
"""

from fastapi import APIRouter

router = APIRouter()


@router.get("/health")
def health_check() -> dict[str, str]:
    """Responde ok si el servidor HTTP está arriba."""
    return {"status": "ok"}
