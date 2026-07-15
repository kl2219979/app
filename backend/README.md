# App Backend

API REST de **finanzas personales**: cuentas, movimientos (gastos/ingresos), transferencias entre cuentas, catálogo de categorías y reportes para dashboard.

Stack: **FastAPI** · **SQLAlchemy** · **Alembic** · **PostgreSQL** · **JWT + MFA (admin)**

---

## Empieza aquí (lectura)

> Guía de navegación: **[`docs/INDICE.md`](docs/INDICE.md)**

| Si quieres… | Abre |
|-------------|------|
| Entender la arquitectura paso a paso | [`docs/COMO_FUNCIONA.md`](docs/COMO_FUNCIONA.md) |
| Reglas de dinero / soft-delete (producto) | [`docs/NEGOCIO.md`](docs/NEGOCIO.md) |
| Tablas y migraciones | [`docs/MODELOS.md`](docs/MODELOS.md) |
| Todos los endpoints HTTP | [`docs/API.md`](docs/API.md) |
| Auth, MFA, OWASP, prod | [`docs/SEGURIDAD.md`](docs/SEGURIDAD.md) |
| Repositories | [`docs/REPOSITORIOS.md`](docs/REPOSITORIOS.md) |
| Cómo testear | [`docs/TESTING.md`](docs/TESTING.md) |
| Historial de evolución | [`docs/HOJA_RUTA.md`](docs/HOJA_RUTA.md) |

---

## Equipo

| Rol | Responsable |
| ----- | ------------ |
| Scrum Master | — |
| Product Owner | — |
| Frontend (×2) | Rama propia (repo frontend) |
| Backend (×2) | Andrés → `dev_andres`, Kevin → `dev_kevin` |
| QA | Kevin |

---

## Qué hace (en una pantalla)

```
Usuario
  ├─ se registra / inicia sesión (JWT; admin con MFA TOTP)
  ├─ crea cuentas con saldo_inicial
  ├─ registra gastos e ingresos  → el saldo de la cuenta cambia solo así
  ├─ transfiere entre sus cuentas (misma moneda)
  ├─ consulta reportes (totales, por categoría, mes, cuenta)
  └─ “borra” = desactiva (el historial contable se conserva)
```

Admin (con MFA) mantiene el catálogo global de categorías/subcategorías.

Detalle de reglas: [`docs/NEGOCIO.md`](docs/NEGOCIO.md).

---

## Arquitectura de datos

```
┌─────────────────────┐                      ┌──────────────────────────┐
│  Contenedor Postgres │ ◄──── SQL / URL ──── │  Backend (FastAPI)       │
│  Solo motor + volumen│                      │  • Alembic → esquema     │
│  Sin lógica de negocio│                     │  • Services → reglas     │
└─────────────────────┘                      │  • Repositories → ORM    │
                                             └──────────────────────────┘
```

El frontend **nunca** habla con Postgres; solo con `/api/v1/...`.

### Capas

1. **Endpoints** (`app/api/`) — HTTP, status codes, Depends  
2. **Schemas** (`app/schemas/`) — validación Pydantic  
3. **Services** (`app/services/`) — negocio (saldos, ownership, MFA…)  
4. **Repositories** (`app/repositories/`) — persistencia  
5. **Models** (`app/models/`) — tablas SQLAlchemy  

---

## Estructura del repositorio

```
backend/
├── app/                    # Código de la API
├── alembic/versions/       # Migraciones (fuente de verdad del esquema)
├── scripts/                # setup, migrate, seed, promote_admin, entrypoint
├── tests/                  # Pirámide unit / api / e2e
├── docs/                   # Documentación (empieza en INDICE.md)
├── docker-compose.yml
├── Dockerfile
├── requirements.txt
├── requirements-dev.txt
└── .env.example
```

---

## Ramas Git

```
main          → Producción (solo merges vía PR)
  └── dev     → Integración del backend
        ├── dev_andres
        └── dev_kevin
```

1. Trabaja en tu rama personal.  
2. PR hacia `dev`.  
3. Tras QA, PR `dev` → `main`.  
4. **Nunca** push directo a `main`.

---

## Requisitos

- Python **3.11+** (CI usa 3.12; local puede ser 3.12/3.14)  
- Docker (PostgreSQL)  
- pip / venv  

---

## Inicio rápido

### A) BD en Docker + API en tu máquina (recomendado)

```bash
chmod +x scripts/*.sh
./scripts/setup.sh
source .venv/bin/activate

docker compose up db -d
./scripts/migrate.sh
python scripts/seed.py          # catálogo de categorías

uvicorn app.main:app --reload
```

- API: http://localhost:8000  
- Health: http://localhost:8000/api/v1/health → `{"status":"ok"}`  
- Swagger (si `DEBUG=true`): http://localhost:8000/docs  

### B) Stack completo Docker

```bash
cp .env.example .env
docker compose up --build
```

El contenedor `api` espera Postgres, migra y arranca Uvicorn.

---

## Primeros pasos útiles

```bash
# Registro / login → ver docs/API.md y docs/SEGURIDAD.md

# Promover admin (luego activar MFA obligatoriamente)
python scripts/promote_admin.py <usuario_o_correo>
# POST /api/v1/auth/mfa/setup  →  Authenticator  →  POST /auth/mfa/confirm
```

---

## Migraciones

```bash
# Tras cambiar app/models/ (y exportar en models/__init__.py):
alembic revision --autogenerate -m "descripcion"
# Revisar alembic/versions/…
./scripts/migrate.sh
```

Head actual: `d4e5f6a7b8c9` (incluye soft-delete, transferencias, MFA).  
Detalle: [`docs/MODELOS.md`](docs/MODELOS.md).

---

## Comandos del día a día

```bash
docker compose up db -d
./scripts/migrate.sh
python scripts/seed.py
uvicorn app.main:app --reload

pytest -q -m "not e2e"
pytest -q -m "not e2e" --cov=app --cov-fail-under=70
ruff check app tests
pip-audit -r requirements.txt -r requirements-dev.txt
```

CI (GitHub Actions): Ruff + **pip-audit** + Pytest con coverage ≥ 70%.

---

## API (resumen)

Prefijo: `/api/v1`

| Área | Ejemplos |
|------|----------|
| Auth | register, login, MFA, refresh, logout, me |
| Users | perfil propio (GET/PUT/DELETE = desactivar) |
| Accounts | CRUD + reactivate; create con `saldo_inicial`; wallet efectivo auto |
| Counterparties | CRUD + reactivate; terceros fuera del sistema |
| Categories / Subcategories | lectura JWT; escritura **admin+MFA** |
| Transactions | CRUD + transfers; `medio_pago`; `contraparte_id`; **sin sobregiro** |
| Reports | `GET /reports/summary` |
| Webhooks | `POST /webhooks/inbound` (HMAC) |

Listados: `{ items, total, limit, offset }`.

Catálogo completo: [`docs/API.md`](docs/API.md).  
Guía para frontend: [`docs/FRONTEND.md`](docs/FRONTEND.md) + Postman en `docs/postman/`.

Demo seed (100 users): `scripts/data/demo_100_users.sql` — ver [`docs/TESTING.md`](docs/TESTING.md).

---

## Variables de entorno

Copia `.env.example` → `.env`. **No subas `.env`.**

| Variable | Rol |
|----------|-----|
| `POSTGRES_*` | Conexión (la URL se arma en `config.py`) |
| `SECRET_KEY` | JWT + cifrado MFA |
| `WEBHOOK_SECRET` | Firma de webhooks |
| `FORCE_HTTPS` | Obligatorio `true` en production |
| `CORS_ORIGINS` | Frontends permitidos |
| `APP_ENV` | `production` activa guards duros |
| `DEBUG` | Docs Swagger; forzado a `false` en production |

Checklist production: [`docs/SEGURIDAD.md`](docs/SEGURIDAD.md).

---

## QA

Antes de cada PR a `dev`:

```bash
pytest -q -m "not e2e"
ruff check app tests
```

Política completa: [`docs/TESTING.md`](docs/TESTING.md).
