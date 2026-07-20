# LucCash

Aplicación de **finanzas personales**: cuentas, movimientos, transferencias, presupuestos, catálogo de categorías y reportes.

Este repositorio agrupa dos partes:

| Carpeta | Rol |
|---------|-----|
| [`backend/`](backend/) | API REST (FastAPI + PostgreSQL + JWT/MFA) |
| [`frontend/`](frontend/) | SPA cliente (Vite + JavaScript vanilla) |

El frontend **nunca** habla con Postgres: solo consume ` /api/v1/... `.

---

## Arquitectura

```
┌─────────────────┐      HTTP (proxy Vite en dev)      ┌──────────────────┐
│  Frontend SPA   │ ─────────────────────────────────► │  Backend FastAPI │
│  localhost:5173 │         /api/v1/...                │  localhost:8000  │
└─────────────────┘                                    └────────┬─────────┘
                                                                │
                                                                ▼
                                                       ┌──────────────────┐
                                                       │  PostgreSQL      │
                                                       │  (Docker :5433)  │
                                                       └──────────────────┘
```

---

## Requisitos

- **Node.js** 18+ (frontend)
- **Docker** + Docker Compose (backend: API + Postgres)
- Opcional: Python 3.11+ y `.venv` si corres el backend fuera de Docker

---

## Arranque rápido

### 1. Backend

```bash
cd backend
docker compose up -d          # db + api en :8000 (y Postgres en :5433)
# Documentación detallada: backend/README.md
```

- API: http://localhost:8000  
- OpenAPI: http://localhost:8000/docs (si `DEBUG=true`)  
- Prefijo: `/api/v1`

Seed demo (recomendado):

```bash
# Ver backend/docs/FRONTEND.md y backend/scripts/data/demo_100_users.sql
```

Credenciales demo (usuarios normales, sin MFA):

| Campo | Valor |
|-------|--------|
| Usuario | `demo001` … `demo100` |
| Contraseña | `Password123!` |

Admin: no hay admin fijo. Se promueve un usuario existente:

```bash
cd backend
python scripts/promote_admin.py demo001
# Luego activar MFA desde la UI (Ajustes) o vía API
```

### 2. Frontend

```bash
cd frontend
npm install
npm run dev
```

Abre **http://localhost:5173** (puerto fijo; proxy de `/api` → `http://127.0.0.1:8000`).

Documentación del cliente: [`frontend/README.md`](frontend/README.md).

---

## Funcionalidades (producto)

- Registro / login JWT (refresh automático)
- MFA TOTP (obligatorio para operaciones de **admin**)
- Cuentas (saldo inicial al crear; el saldo solo cambia con movimientos)
- Transacciones gasto/ingreso (cuenta o efectivo)
- Transferencias entre cuentas propias (misma moneda)
- Contrapartes
- Presupuestos mensuales + estado de consumo
- Reportes de dashboard (totales, categorías, medios, cuentas, comparativa de periodo)
- Export CSV/JSON de transacciones
- Catálogo global de categorías/subcategorías (**admin + MFA**)
- Soft-delete (desactivar / reactivar) en la mayoría de recursos

---

## Documentación

| Ámbito | Dónde |
|--------|--------|
| Índice backend | [`backend/docs/INDICE.md`](backend/docs/INDICE.md) |
| API HTTP | [`backend/docs/API.md`](backend/docs/API.md) |
| Negocio / reglas | [`backend/docs/NEGOCIO.md`](backend/docs/NEGOCIO.md) |
| Seguridad / MFA | [`backend/docs/SEGURIDAD.md`](backend/docs/SEGURIDAD.md) |
| Integración frontend↔API | [`backend/docs/FRONTEND.md`](backend/docs/FRONTEND.md) |
| SPA cliente | [`frontend/README.md`](frontend/README.md) |

---

## Estructura del workspace

```
Trabajando/
├── README.md           ← este archivo
├── backend/            ← API FastAPI (git propio o módulo)
│   ├── app/
│   ├── docs/
│   ├── scripts/
│   └── README.md
└── frontend/           ← SPA Vite (git propio en muchos flujos)
    ├── src/
    ├── index.html
    └── README.md
```

> Monorepo: el código de `backend/` y `frontend/` vive en este mismo repositorio (`kl2219979/app`).

---

## Licencia / uso

Proyecto académico / de práctica de equipo. Ver roles y convenciones en [`backend/README.md`](backend/README.md).
