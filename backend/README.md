# App Backend

**Personal finance** REST API: accounts, transactions (expenses/income), transfers between accounts, category catalog, and dashboard reports.

Stack: **FastAPI** · **SQLAlchemy** · **Alembic** · **PostgreSQL** · **JWT + MFA (admin)**

---

## Start here (reading)

> Navigation guide: **[`docs/INDEX.md`](docs/INDEX.md)**

| If you want to… | Open |
|-------------|------|
| Understand the architecture step by step | [`docs/HOW_IT_WORKS.md`](docs/HOW_IT_WORKS.md) |
| Money / soft-delete rules (product) | [`docs/BUSINESS.md`](docs/BUSINESS.md) |
| Tables and migrations | [`docs/MODELS.md`](docs/MODELS.md) |
| All HTTP endpoints | [`docs/API.md`](docs/API.md) |
| Auth, MFA, OWASP, prod | [`docs/SECURITY.md`](docs/SECURITY.md) |
| Repositories | [`docs/REPOSITORIES.md`](docs/REPOSITORIES.md) |
| How to test | [`docs/TESTING.md`](docs/TESTING.md) |
| Evolution history | [`docs/ROADMAP.md`](docs/ROADMAP.md) |

---

## Team

| Role | Owner |
| ----- | ------------ |
| Scrum Master | Daniela |
| Product Owner | Andrés |
| Frontend | Juan |
| Backend | Andrés |
| QA | Kevin |

---

## What it does (on one screen)

```
User
  ├─ registers / logs in (JWT; admin with TOTP MFA)
  ├─ creates accounts with initial_balance
  ├─ records expenses and income  → the account balance only changes this way
  ├─ transfers between their accounts (same currency)
  ├─ queries reports (totals, by category, month, account)
  └─ “delete” = deactivate (the accounting history is preserved)
```

Admin (with MFA) maintains the global catalog of categories/subcategories.

Rules detail: [`docs/BUSINESS.md`](docs/BUSINESS.md).

---

## Data architecture

```
┌─────────────────────┐                      ┌──────────────────────────┐
│  Postgres container  │ ◄──── SQL / URL ──── │  Backend (FastAPI)       │
│  Engine + volume only│                      │  • Alembic → schema      │
│  No business logic   │                      │  • Services → rules      │
└─────────────────────┘                      │  • Repositories → ORM    │
                                             └──────────────────────────┘
```

The frontend **never** talks to Postgres; only to `/api/v1/...`.

### Layers

1. **Endpoints** (`app/api/`) — HTTP, status codes, Depends  
2. **Schemas** (`app/schemas/`) — Pydantic validation  
3. **Services** (`app/services/`) — business (balances, ownership, MFA…)  
4. **Repositories** (`app/repositories/`) — persistence  
5. **Models** (`app/models/`) — SQLAlchemy tables  

---

## Repository structure

```
backend/
├── app/                    # API code
├── alembic/versions/       # Migrations (source of truth for the schema)
├── scripts/                # setup, migrate, seed, promote_admin, entrypoint
├── tests/                  # unit / api / e2e pyramid
├── docs/                   # Documentation (start at INDEX.md)
├── docker-compose.yml
├── Dockerfile
├── requirements.txt
├── requirements-dev.txt
└── .env.example
```

---

## Git branches

```
main          → Production (merges via PR only)
  └── dev     → Backend integration
        ├── dev_andres
        └── dev_kevin
```

1. Work on your personal branch.  
2. PR to `dev`.  
3. After QA, PR `dev` → `main`.  
4. **Never** push directly to `main`.

---

## Requirements

- Python **3.11+** (CI uses 3.12; local can be 3.12/3.14)  
- Docker (PostgreSQL)  
- pip / venv  

---

## Quick start

### A) DB in Docker + API on your machine (recommended)

```bash
chmod +x scripts/*.sh
./scripts/setup.sh
source .venv/bin/activate

docker compose up db -d
./scripts/migrate.sh
python scripts/seed.py          # category catalog

uvicorn app.main:app --reload
```

- API: http://localhost:8000  
- Health: http://localhost:8000/api/v1/health → `{"status":"ok"}`  
- Swagger (if `DEBUG=true`): http://localhost:8000/docs  

### B) Full Docker stack

```bash
cp .env.example .env
docker compose up --build
```

The `api` container waits for Postgres, migrates, and starts Uvicorn.

---

## Useful first steps

```bash
# Register / login → see docs/API.md and docs/SECURITY.md

# Promote admin (then MFA must be enabled)
python scripts/promote_admin.py <user_or_email>
# POST /api/v1/auth/mfa/setup  →  Authenticator  →  POST /auth/mfa/confirm
```

---

## Migrations

```bash
# After changing app/models/ (and exporting in models/__init__.py):
alembic revision --autogenerate -m "description"
# Review alembic/versions/…
./scripts/migrate.sh
```

Current head: `d4e5f6a7b8c9` (includes soft-delete, transfers, MFA).  
Detail: [`docs/MODELS.md`](docs/MODELS.md).

---

## Day-to-day commands

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

CI (GitHub Actions): Ruff + **pip-audit** + Pytest with coverage ≥ 70%.

---

## API (summary)

Prefix: `/api/v1`

| Area | Examples |
|------|----------|
| Auth | register, login, MFA, refresh, logout, me |
| Users | own profile (GET/PUT/DELETE = deactivate) |
| Accounts | CRUD + reactivate; create with `saldo_inicial`; auto cash wallet |
| Counterparties | CRUD + reactivate; third parties outside the system |
| Categories / Subcategories | JWT read; **admin+MFA** write |
| Transactions | CRUD + transfers; `medio_pago`; `contraparte_id`; **no overdraft** |
| Reports | `GET /reports/summary` |
| Webhooks | `POST /webhooks/inbound` (HMAC) |

Listings: `{ items, total, limit, offset }`.

Full catalog: [`docs/API.md`](docs/API.md).  
Frontend guide: [`docs/FRONTEND.md`](docs/FRONTEND.md) + Postman in `docs/postman/`.

Demo seed (100 users): `scripts/data/demo_100_users.sql` — see [`docs/TESTING.md`](docs/TESTING.md).

---

## Environment variables

Copy `.env.example` → `.env`. **Do not commit `.env`.**

| Variable | Role |
|----------|-----|
| `POSTGRES_*` | Connection (the URL is built in `config.py`) |
| `SECRET_KEY` | JWT + MFA encryption |
| `WEBHOOK_SECRET` | Webhook signing |
| `FORCE_HTTPS` | Must be `true` in production |
| `CORS_ORIGINS` | Allowed frontends |
| `APP_ENV` | `production` enables hard guards |
| `DEBUG` | Swagger docs; forced to `false` in production |

Production checklist: [`docs/SECURITY.md`](docs/SECURITY.md).

---

## QA

Before each PR to `dev`:

```bash
pytest -q -m "not e2e"
ruff check app tests
```

Full policy: [`docs/TESTING.md`](docs/TESTING.md).
