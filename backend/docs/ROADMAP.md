# Roadmap — maturation history (steps 1–12)
# ==================================================
#
# This document is a DIARY of what was implemented at each stage.
# It is not the onboarding guide: for that, start at docs/INDEX.md
# and docs/HOW_IT_WORKS.md.
#
# ---------------------------------------------------------------------------
# Step 1 — Unify Alembic (a single head)
# ---------------------------------------------------------------------------
# Problem: there were several empty revisions in parallel → two heads.
# Solution: the empty migrations were removed:
#   - 08a8c3ba63f4_add_initial_schema.py
#   - c70ed89af933_add_initial_schema.py
#   - 72606699bc47_add_initial_schema.py
# Only one remained: 72b0c849201b_add_initial_schema.py (real DDL).
#
# If your local DB had a deleted revision_id:
#   docker compose up db -d
#   alembic stamp 72b0c849201b
#   # or, if the DB is empty:
#   ./scripts/migrate.sh
#
# Verify:
#   alembic heads   → must show a single head
#
# ---------------------------------------------------------------------------
# Step 2 — Real Account CRUD (JWT + service + repository)
# ---------------------------------------------------------------------------
# Layers:
#   schemas/account.py     AccountCreate / Update / Response (no user_id in create)
#   services/account.py    AccountService (only the token user's accounts)
#   endpoints/account.py   /api/v1/accounts  (Bearer required)
#   repositories/account.py (already existed)
#
# Flow: Endpoint → Service → Repository → Postgres
#
# ---------------------------------------------------------------------------
# Step 3 — AAA tests for auth + accounts
# ---------------------------------------------------------------------------
#   tests/conftest.py          In-memory SQLite + auth_headers fixtures
#   tests/api/test_auth.py     register / login / me
#   tests/api/test_accounts.py create / list / get / update / delete
#   tests/core/test_security.py (already existed)
#
# Run:  pytest -q
#
# ---------------------------------------------------------------------------
# Step 4 — Category, SubCategory, Transaction
# ---------------------------------------------------------------------------
# Same template as Account:
#   services/category.py, sub_category.py, transaction.py
#   endpoints with plural routes and JWT
#
# Extra rules in TransactionService:
#   - the account must belong to the user
#   - the subcategory must belong to the category
#
# ---------------------------------------------------------------------------
# Step 5 — Cleanup and unification
# ---------------------------------------------------------------------------
# - Schemas in PascalCase (AccountCreate, …)
# - Plural routes:
#     /accounts  /categories  /subcategories  /transactions  /users
# - Hot-reload stubs removed
# - Users: creation only in /auth/register; /users/{id} is the own profile
# - services/ populated (no longer an empty folder)
#
# Quick API map (all except health/auth-login/register require JWT
# except register/login/health):
#   POST /api/v1/auth/register
#   POST /api/v1/auth/login
#   GET  /api/v1/auth/me
#   CRUD /api/v1/accounts
#   CRUD /api/v1/categories
#   CRUD /api/v1/subcategories
#   CRUD /api/v1/transactions
#   GET/PUT/DELETE /api/v1/users/{id}  (own id only)
#
# See also: docs/SECURITY.md, docs/REPOSITORIES.md, docs/TESTING.md
#
# ---------------------------------------------------------------------------
# Step 6 — Test pyramid (many unit, some integration, few E2E)
# ---------------------------------------------------------------------------
# Goal: mature the coverage without inflating E2E.
#
# Unit (majority):
#   tests/core/           security (hash + JWT)
#   tests/services/       test_*_service.py (account, category, sub_category,
#                         transaction, user)
#   tests/repositories/   test_*_repository.py (filters, joins, lookups)
#   tests/helpers.py      make_* factories for Arrange without HTTP
#
# Integration (some):
#   tests/api/            HTTP smoke with TestClient + SQLite
#                         (auth, accounts, categories, transactions, health)
#   tests/integration/    Real Postgres — only with RUN_INTEGRATION=1
#
# E2E (few, opt-in):
#   tests/e2e/test_critical_path.py
#     health → register → login → account → category/sub → transaction
#     Enable: RUN_E2E=1 E2E_BASE_URL=http://localhost:8000 pytest -m e2e
#
# Markers: unit | integration | e2e  (see pyproject.toml and docs/TESTING.md)
#
# Commands:
#   pytest -q                 # daily (Postgres/E2E auto-skipped)
#   pytest -m unit -q         # unit only
#   pytest -m integration -q  # API smoke (+ Postgres if RUN_INTEGRATION=1)
#
# Detailed documentation and PR policy: docs/TESTING.md
#
# ---------------------------------------------------------------------------
# Step 7 — CI, pagination, seeds, and account balance
# ---------------------------------------------------------------------------
# CI (GitHub Actions):
#   .github/workflows/ci.yml
#   - ruff check app tests
#   - pytest -q -m "not e2e"  (daily suite; Postgres/E2E opt-in outside CI)
#
# Pagination + filters (transactions):
#   GET /api/v1/transactions?limit=&offset=&account_id=&category_id=
#       &tipo=gasto|ingreso&date_from=&date_to=
#   Response: { items, total, limit, offset }  (schemas/pagination.py)
#
# Transaction type + balance:
#   transactions.tipo = "gasto" | "ingreso"  (migration a1b2c3d4e5f6)
#   gasto subtracts from Account.saldo; ingreso adds; delete/update revert
#
# Seeds:
#   python scripts/seed.py
#   Catalog in app/services/seed.py (idempotent)
#
# Apply locally after pull:
#   ./scripts/migrate.sh
#   python scripts/seed.py
#   docker compose up --build -d   # if you use the API in Docker
#
# ---------------------------------------------------------------------------
# Step 8 — Refresh token, admin roles, general pagination, reports, coverage
# ---------------------------------------------------------------------------
# Auth:
#   login → { access_token, refresh_token, token_type }
#   POST /auth/refresh  { refresh_token }  (rotates the refresh)
#   POST /auth/logout   Bearer + optional refresh_token (revokes)
#   refresh_tokens table (SHA-256 hash); users.rol = user|admin
#
# Admin:
#   POST/PUT/DELETE /categories and /subcategories → admin only
#   GET remains open to any JWT
#   Promote: python scripts/promote_admin.py <user_or_email>
#
# Unified pagination (Page):
#   /accounts  /categories  /subcategories  /transactions
#   → { items, total, limit, offset }
#
# Reports:
#   GET /reports/summary?account_id=&date_from=&date_to=
#   → total_ingresos, total_gastos, balance_neto, by_category[]
#
# CI:
#   pytest --cov=app --cov-fail-under=70
#
# Out of scope (deliberately):
#   notifications, uploads, complex multi-tenant
#
# ---------------------------------------------------------------------------
# Step 9 — Conservative cleanup (only unused code with no clear future)
# ---------------------------------------------------------------------------
# Criterion: before deleting, ask whether it has future use.
#
# Removed:
#   - camelCase aliases in schemas (accountCreate, …) — zero imports
#   - SubCategoryRepository.list_all — duplicated list_filtered
#
# Kept on purpose (future use):
#   - UserCreate        → admin user creation
#   - PageParams        → unified Depends in listings
#   - TokenPayload      → typed JWT validation
#   - pytest-asyncio    → async tests if needed
#   - UserPublic vs UserResponse — auth vs /users profile
#
# Updated docs: REPOSITORIES, MODELS, this file.
#
# ---------------------------------------------------------------------------
# Step 10 — Accounting consistency, soft-delete, and dashboard
# ---------------------------------------------------------------------------
# Soft-delete (`activo`):
#   DELETE on accounts / categories / subcategories / transactions / users
#   deactivates; does not delete history or cascade-wipe the ledger.
#   POST /accounts/{id}/reactivate to reopen an account.
#
# Balance:
#   AccountCreate uses saldo_inicial (opening only).
#   AccountUpdate does NOT allow editing saldo; only transactions change it.
#
# Transfers:
#   POST /transactions/transfers
#   Two legs + grupo_transferencia; deactivating one reverts both.
#
# Reports (dashboard):
#   GET /reports/summary
#   → operational income/expenses, transfers separate,
#     by_category_gastos / by_category_ingresos, by_month, by_account
#
# Migration: c3d4e5f6a7b8 (activo + grupo_transferencia)
#
# ---------------------------------------------------------------------------
# Step 11 — OWASP hardening (full security)
# ---------------------------------------------------------------------------
# Auth/webhooks rate limit, failed-auth logs, admin TOTP MFA,
# strict CORS, DEBUG=False in production, FORCE_HTTPS + HSTS,
# HMAC webhooks (/webhooks/inbound), pip-audit + Dependabot.
# See docs/SECURITY.md. MFA migration: d4e5f6a7b8c9
#
# ---------------------------------------------------------------------------
# Step 12 — Documentation aligned with the project's reality
# ---------------------------------------------------------------------------
# The documentation was rewritten/expanded for onboarding without prior knowledge:
#   docs/INDEX.md       → reading map
#   docs/HOW_IT_WORKS.md
#   docs/BUSINESS.md    → money, soft-delete, transfers, reports
#   docs/MODELS.md
#   docs/API.md          → full HTTP catalog
#   docs/SECURITY.md
#   docs/REPOSITORIES.md
#   docs/TESTING.md
#   README.md
#
# ---------------------------------------------------------------------------
# Step 13 — External counterparties + cash payment method
# ---------------------------------------------------------------------------
# Counterparties (`counterparties`): address book of third parties outside the system.
#   JWT CRUD + soft-delete/reactivate; ownership by user_id.
#   Optional Transaction.contraparte_id on expense/income.
#
# Payment method:
#   medio_pago = cuenta | efectivo
#   efectivo → currency required, no account_id; auto wallet
#   (banco="Efectivo", tipo="efectivo") per user+currency.
#   Bank↔cash via POST /transactions/transfers.
#
# Migration: e5f6a7b8c9d0
# Docs: BUSINESS, MODELS, API, this file.
#
# ---------------------------------------------------------------------------
# Step 14 — Accounting hardening + demo seed 100 users
# ---------------------------------------------------------------------------
# - transactions.tipo → varchar(30) (f6a7b8c9d0e1): transferencia_* fits
#   Insufficient funds → 400 on gasto / transferencia_salida
# - POST /accounts with tipo=efectivo rejected (wallet auto only)
# - Seed: scripts/data/demo_100_users.sql + generate_demo_100_users_sql.py
#   non-negative balances, early income, bounded cash
# - Tests: schema length, insufficient funds, Postgres column check
#
# ---------------------------------------------------------------------------
# Step 15 — FE priority: reports v2 + filters + frontend kit
# ---------------------------------------------------------------------------
# Expanded reports summary:
#   by_subcategory_*, by_medio_pago, by_counterparty (top 10),
#   period_comparison (current vs previous window).
# Transactions list: medio_pago, contraparte_id, sub_category_id filters;
#   documented order fecha DESC, id DESC.
# FE kit: docs/FRONTEND.md + Postman collection + scripts/export_openapi.py
#
# ---------------------------------------------------------------------------
# Step 16 — Medium priority: budgets, export, CI Postgres
# ---------------------------------------------------------------------------
# Budgets (`budgets`): monthly limit per category (CRUD + soft-delete).
#   GET /budgets/status + budgets_status in reports/summary (calendar month).
# Export: GET /transactions/export?format=csv|json (same filters; max 10k).
# CI: Postgres 16 service + migrate + pytest unit/API + `postgres` marker.
# Migration: a7b8c9d0e1f2
#
#
