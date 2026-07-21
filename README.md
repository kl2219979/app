# LuCash

**Personal finance** application: accounts, transactions, transfers, budgets, category catalog, and reports.

This repository groups two parts:

| Folder | Role |
|---------|-----|
| [`backend/`](backend/) | REST API (FastAPI + PostgreSQL + JWT/MFA) |
| [`frontend/`](frontend/) | Client SPA (Vite + vanilla JavaScript) |

The frontend **never** talks to Postgres directly: it only consumes ` /api/v1/... `.

---

## Architecture

```
┌─────────────────┐      HTTP (Vite proxy in dev)      ┌──────────────────┐
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

## Requirements

- **Node.js** 18+ (frontend)
- **Docker** + Docker Compose (backend: API + Postgres)
- Optional: Python 3.11+ and `.venv` if you run the backend outside Docker

---

## Quick start

### 1. Backend

```bash
cd backend
docker compose up -d          # db + api on :8000 (and Postgres on :5433)
# Detailed documentation: backend/README.md
```

- API: http://localhost:8000  
- OpenAPI: http://localhost:8000/docs (if `DEBUG=true`)  
- Prefix: `/api/v1`

Demo seed (recommended):

```bash
# See backend/docs/FRONTEND.md and backend/scripts/data/demo_100_users.sql
```

Demo credentials (regular users, no MFA):

| Field | Value |
|-------|--------|
| Username | `demo001` … `demo100` |
| Password | `Password123!` |

Admin: there is no fixed admin. An existing user is promoted:

```bash
cd backend
python scripts/promote_admin.py demo001
# Then enable MFA from the UI (Settings) or via API
```

### 2. Frontend

```bash
cd frontend
npm install
npm run dev
```

Open **http://localhost:5173** (fixed port; proxy from `/api` → `http://127.0.0.1:8000`).

Client documentation: [`frontend/README.md`](frontend/README.md).

---

## Features (product)

- JWT registration / login (automatic refresh)
- TOTP MFA (required for **admin** operations)
- Accounts (initial balance at creation; balance only changes through transactions)
- Expense/income transactions (account or cash)
- Transfers between your own accounts (same currency)
- Counterparties
- Monthly budgets + consumption status
- Dashboard reports (totals, categories, payment methods, accounts, period comparison)
- CSV/JSON export of transactions
- Global catalog of categories/subcategories (**admin + MFA**)
- Soft-delete (deactivate / reactivate) on most resources

---

## Documentation

| Area | Where |
|--------|--------|
| Backend index | [`backend/docs/INDEX.md`](backend/docs/INDEX.md) |
| HTTP API | [`backend/docs/API.md`](backend/docs/API.md) |
| Business / rules | [`backend/docs/BUSINESS.md`](backend/docs/BUSINESS.md) |
| Security / MFA | [`backend/docs/SECURITY.md`](backend/docs/SECURITY.md) |
| Frontend↔API integration | [`backend/docs/FRONTEND.md`](backend/docs/FRONTEND.md) |
| Client SPA | [`frontend/README.md`](frontend/README.md) |

---

## Workspace structure

```
Trabajando/
├── README.md           ← this file
├── backend/            ← FastAPI API (own git or module)
│   ├── app/
│   ├── docs/
│   ├── scripts/
│   └── README.md
└── frontend/           ← Vite SPA (own git in many workflows)
    ├── src/
    ├── index.html
    └── README.md
```

> Monorepo: the `backend/` and `frontend/` code lives in this same repository (`kl2219979/app`).

---

## License / usage

Academic / team practice project. See roles and conventions in [`backend/README.md`](backend/README.md).
