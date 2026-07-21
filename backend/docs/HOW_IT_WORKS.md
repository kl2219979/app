# How this backend works (step-by-step guide)

This guide explains **what each thing is** and **why it exists**.
Read it in order the first time. Index of all documentation: [INDEX.md](INDEX.md).

---

## 1. The general idea

Imagine three separate pieces:

```
[ Frontend (Vite/React/…) ]  --HTTPS/HTTP-->  [ FastAPI API ]  --SQL-->  [ PostgreSQL ]
        screens                                logic + auth               persistent data
```

- The **frontend** only talks to the API (never to the database).
- The **API** decides what can be done and applies money/security rules.
- **PostgreSQL** only stores and returns rows. It knows nothing about JWT or “expense vs income”.

The database is **decoupled**: it lives in its own Docker container; the schema is versioned by **Alembic** alongside the code.

Product (personal finance): [BUSINESS.md](BUSINESS.md).

---

## 2. What problem does each tool solve?

| Tool | Question it answers | Analogy |
|-------------|----------------------|----------|
| **Docker / Postgres** | Where does the database run? | Fridge: stores, doesn't cook |
| **Alembic** | How do the tables change? | Kitchen blueprints |
| **SQLAlchemy models** | What does a table look like in Python? | Labels on each shelf |
| **Repositories** | How do I read/write rows? | Opening the fridge |
| **Services** | Is it allowed? | The cook / the recipe |
| **Endpoints** | Which URL does the front call? | Service window |
| **Schemas (Pydantic)** | Is the JSON valid? | Checking the order |
| **core/security, mfa…** | How do we authenticate and sign? | Keys and locks |

Mental rule:

- **Alembic** = structure  
- **Services** = business logic  
- **Repositories** = technical access  

---

## 3. Layers inside `app/`

```
HTTP Request
    ↓
endpoints/     → receive the request, almost no logic
    ↓
schemas/       → validate the input/output JSON
    ↓
services/      → decide WHETHER it's allowed and WHAT to do
    ↓
repositories/  → run the ORM
    ↓
PostgreSQL
```

| Layer | Decides | Should not |
|------|--------|------------|
| Endpoint | Route, status, Depends | Long business rules |
| Service | Permissions, balances, soft-delete | Raw SQL details |
| Repository | Queries, flush | “Is admin?” |
| Model | Columns and relationships | HTTP responses |
| Schema | JSON shape | Talk to the DB |

### Map of real folders

```
app/
├── main.py                 # Creates FastAPI, CORS, headers, router
├── api/
│   ├── deps.py             # get_db, get_current_user, get_current_admin
│   └── v1/
│       ├── router.py       # Mounts all endpoints
│       └── endpoints/      # auth, accounts, transactions, …
├── core/
│   ├── config.py           # settings from .env
│   ├── security.py         # bcrypt + JWT
│   ├── mfa.py              # admin TOTP
│   ├── rate_limit.py
│   ├── webhooks.py         # HMAC
│   └── logging_config.py
├── db/                     # Base + SessionLocal
├── models/                 # SQLAlchemy tables
├── schemas/                # Pydantic DTOs
├── services/               # Business (+ seed)
└── repositories/           # Data access
```

---

## 4. The flow when you start everything

### Option A — Development (recommended)

```bash
chmod +x scripts/*.sh
./scripts/setup.sh              # 1) venv + deps + .env
source .venv/bin/activate
docker compose up db -d         # 2) Postgres only
./scripts/migrate.sh            # 3) Tables (Alembic)
python scripts/seed.py          # 4) Category catalog (optional)
uvicorn app.main:app --reload   # 5) API
```

| Step | What / why |
|------|----------------|
| `setup.sh` | Creates `.venv`, installs `requirements-dev.txt`, copies `.env.example` → `.env` |
| `docker compose up db -d` | Empty Postgres (engine + `app_db` DB only) |
| `migrate.sh` | Waits for DB + `alembic upgrade head` |
| `seed.py` | Idempotent base categories |
| `uvicorn` | Serves HTTP on `:8000` |

API: http://localhost:8000  
Interactive docs (if `DEBUG=true`): http://localhost:8000/docs

### Option B — All Docker

```bash
cp .env.example .env
docker compose up --build
```

The `entrypoint.sh` of the `api` service:

1. Waits for Postgres  
2. Migrates  
3. Starts Uvicorn  

Inside Docker, `POSTGRES_HOST=db` (the service name), not `localhost`.

---

## 5. Infrastructure files (what / why)

| File | Role |
|---------|-----|
| `docker-compose.yml` | `db` and `api` services |
| `Dockerfile` | Python image for the API |
| `scripts/setup.sh` | Local onboarding |
| `scripts/wait_for_db.py` | Avoids a race when Postgres starts |
| `scripts/migrate.sh` | Migrate locally |
| `scripts/entrypoint.sh` | Migrate + exec uvicorn in the container |
| `scripts/seed.py` | Initial catalog |
| `scripts/promote_admin.py` | Promotes admin role (then MFA) |
| `.env` / `.env.example` | Secrets and config (`.env` is not committed) |
| `alembic/` | Schema history |
| `.github/workflows/ci.yml` | Ruff + pip-audit + pytest |
| `.github/dependabot.yml` | Dependency PRs |

---

## 6. Authenticated request (mental example)

1. The client sends `Authorization: Bearer <access_jwt>`.
2. `get_current_user` validates signature/exp and loads the active `User`.
3. The endpoint calls the service with `current_user` + a body already validated by Pydantic.
4. The service checks ownership / balance rules / active status.
5. The repository persists; the service does `commit`.
6. It responds with a `*Response` schema.

If it is a category write:

- `get_current_admin` requires admin **and** MFA.

Detail: [SECURITY.md](SECURITY.md), [API.md](API.md).

---

## 7. Money in one sentence

> An account's balance only changes through transactions (and through `saldo_inicial` when it is created).  
> DELETE does not erase history: it deactivates.  
> Transfers are two linked legs and do not count as the month's expense.

Read more: [BUSINESS.md](BUSINESS.md).

---

## 8. Quick mental map

```
Start only the DB?                 → docker compose up db -d
Create/update tables?              → ./scripts/migrate.sh
Local API?                         → uvicorn app.main:app --reload
Base catalog?                      → python scripts/seed.py
Make admin?                        → promote_admin + MFA setup/confirm
Where does a business rule go?     → app/services/
Where does a SELECT go?            → app/repositories/
Where does a new URL go?           → app/api/v1/endpoints/
JSON contract?                     → app/schemas/
New table?                         → app/models/ + Alembic
Test?                              → pytest -q   (see TESTING.md)
```

---

## 9. If something fails

| Symptom | Likely cause | What to do |
|---------|----------------|-----------|
| `Connection refused` to Postgres | DB down | `docker compose up db -d` |
| API without tables | You didn't migrate | `./scripts/migrate.sh` |
| Autogenerate doesn't see the model | Missing import | `app/models/__init__.py` |
| Front doesn't call the API | CORS | `CORS_ORIGINS` in `.env` |
| API in Docker doesn't see the DB | You used `localhost` | Host must be `db` |
| 429 on login during tests | Global rate limit | Already cleared in conftest; restart suite |
| 403 on categories | You are not admin or without MFA | `promote_admin` + `/auth/mfa/*` |
| 422 when editing an account balance | Intentional design | Use transactions |
| App won't start in `production` | Missing SECRET/WEBHOOK/HTTPS | See checklist in SECURITY |

---

## 10. Next reading

1. [BUSINESS.md](BUSINESS.md) — product behavior  
2. [API.md](API.md) — endpoints one by one  
3. [MODELS.md](MODELS.md) — tables  
4. [SECURITY.md](SECURITY.md) — auth and OWASP  
5. [TESTING.md](TESTING.md) — how not to break anything  
