# Hoja de ruta — historial de maduración (pasos 1–12)
# ==================================================
#
# Este documento es un DIARIO de lo que se implementó en cada etapa.
# No es la guía de onboarding: para eso empieza en docs/INDICE.md
# y docs/COMO_FUNCIONA.md.
#
# ---------------------------------------------------------------------------
# Paso 1 — Unificar Alembic (un solo head)
# ---------------------------------------------------------------------------
# Problema: había varias revisiones vacías en paralelo → dos heads.
# Solución: se eliminaron las migraciones vacías:
#   - 08a8c3ba63f4_add_initial_schema.py
#   - c70ed89af933_add_initial_schema.py
#   - 72606699bc47_add_initial_schema.py
# Quedó solo: 72b0c849201b_add_initial_schema.py (DDL real).
#
# Si tu BD local tenía un revision_id borrado:
#   docker compose up db -d
#   alembic stamp 72b0c849201b
#   # o, si la BD está vacía:
#   ./scripts/migrate.sh
#
# Verificar:
#   alembic heads   → debe mostrar un solo head
#
# ---------------------------------------------------------------------------
# Paso 2 — CRUD real de Account (JWT + service + repository)
# ---------------------------------------------------------------------------
# Capas:
#   schemas/account.py     AccountCreate / Update / Response (sin user_id en create)
#   services/account.py    AccountService (solo cuentas del usuario del token)
#   endpoints/account.py   /api/v1/accounts  (Bearer obligatorio)
#   repositories/account.py (ya existía)
#
# Flujo: Endpoint → Service → Repository → Postgres
#
# ---------------------------------------------------------------------------
# Paso 3 — Tests AAA de auth + accounts
# ---------------------------------------------------------------------------
#   tests/conftest.py          SQLite en memoria + fixtures auth_headers
#   tests/api/test_auth.py     register / login / me
#   tests/api/test_accounts.py create / list / get / update / delete
#   tests/core/test_security.py (ya existía)
#
# Correr:  pytest -q
#
# ---------------------------------------------------------------------------
# Paso 4 — Category, SubCategory, Transaction
# ---------------------------------------------------------------------------
# Misma plantilla que Account:
#   services/category.py, sub_category.py, transaction.py
#   endpoints con rutas plurales y JWT
#
# Reglas extra en TransactionService:
#   - la cuenta debe ser del usuario
#   - subcategoría debe pertenecer a la categoría
#
# ---------------------------------------------------------------------------
# Paso 5 — Limpieza y unificación
# ---------------------------------------------------------------------------
# - Schemas en PascalCase (AccountCreate, …)
# - Rutas plurales:
#     /accounts  /categories  /subcategories  /transactions  /users
# - Stubs de hot-reload eliminados
# - Users: alta solo en /auth/register; /users/{id} es perfil propio
# - services/ poblado (ya no carpeta vacía)
#
# Mapa rápido de API (todas salvo health/auth-login/register requieren JWT
# excepto register/login/health):
#   POST /api/v1/auth/register
#   POST /api/v1/auth/login
#   GET  /api/v1/auth/me
#   CRUD /api/v1/accounts
#   CRUD /api/v1/categories
#   CRUD /api/v1/subcategories
#   CRUD /api/v1/transactions
#   GET/PUT/DELETE /api/v1/users/{id}  (solo el propio id)
#
# Ver también: docs/SEGURIDAD.md, docs/REPOSITORIOS.md, docs/TESTING.md
#
# ---------------------------------------------------------------------------
# Paso 6 — Pirámide de tests (muchos unitarios, algunos integration, pocos E2E)
# ---------------------------------------------------------------------------
# Objetivo: madurar cobertura sin inflar E2E.
#
# Unit (mayoría):
#   tests/core/           security (hash + JWT)
#   tests/services/       test_*_service.py (account, category, sub_category,
#                         transaction, user)
#   tests/repositories/   test_*_repository.py (filtros, joins, lookups)
#   tests/helpers.py      factories make_* para Arrange sin HTTP
#
# Integration (algunos):
#   tests/api/            smoke HTTP con TestClient + SQLite
#                         (auth, accounts, categories, transactions, health)
#   tests/integration/    Postgres real — solo con RUN_INTEGRATION=1
#
# E2E (pocos, opt-in):
#   tests/e2e/test_critical_path.py
#     health → register → login → account → category/sub → transaction
#     Activar: RUN_E2E=1 E2E_BASE_URL=http://localhost:8000 pytest -m e2e
#
# Markers: unit | integration | e2e  (ver pyproject.toml y docs/TESTING.md)
#
# Comandos:
#   pytest -q                 # diario (Postgres/E2E se auto-omiten)
#   pytest -m unit -q         # solo unitarios
#   pytest -m integration -q  # API smoke (+ Postgres si RUN_INTEGRATION=1)
#
# Documentación detallada y política PR: docs/TESTING.md
#
# ---------------------------------------------------------------------------
# Paso 7 — CI, paginación, seeds y saldo de cuentas
# ---------------------------------------------------------------------------
# CI (GitHub Actions):
#   .github/workflows/ci.yml
#   - ruff check app tests
#   - pytest -q -m "not e2e"  (suite diaria; Postgres/E2E opt-in fuera de CI)
#
# Paginación + filtros (transactions):
#   GET /api/v1/transactions?limit=&offset=&account_id=&category_id=
#       &tipo=gasto|ingreso&date_from=&date_to=
#   Respuesta: { items, total, limit, offset }  (schemas/pagination.py)
#
# Tipo de movimiento + saldo:
#   transactions.tipo = "gasto" | "ingreso"  (migración a1b2c3d4e5f6)
#   gasto resta del Account.saldo; ingreso suma; delete/update revierten
#
# Seeds:
#   python scripts/seed.py
#   Catálogo en app/services/seed.py (idempotente)
#
# Aplicar en local tras pull:
#   ./scripts/migrate.sh
#   python scripts/seed.py
#   docker compose up --build -d   # si usas API en Docker
#
# ---------------------------------------------------------------------------
# Paso 8 — Refresh token, roles admin, paginación general, reports, coverage
# ---------------------------------------------------------------------------
# Auth:
#   login → { access_token, refresh_token, token_type }
#   POST /auth/refresh  { refresh_token }  (rota el refresh)
#   POST /auth/logout   Bearer + opcional refresh_token (revoca)
#   Tabla refresh_tokens (hash SHA-256); users.rol = user|admin
#
# Admin:
#   POST/PUT/DELETE /categories y /subcategories → solo admin
#   GET sigue abierto a cualquier JWT
#   Promover: python scripts/promote_admin.py <usuario_o_correo>
#
# Paginación unificada (Page):
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
# Fuera de alcance (consciente):
#   notificaciones, uploads, multi-tenant complejo
#
# ---------------------------------------------------------------------------
# Paso 9 — Limpieza conservadora (solo código sin uso ni futuro claro)
# ---------------------------------------------------------------------------
# Criterio: antes de borrar, preguntar si tiene uso futuro.
#
# Eliminado:
#   - Alias camelCase en schemas (accountCreate, …) — cero imports
#   - SubCategoryRepository.list_all — duplicaba list_filtered
#
# Mantenido a propósito (uso futuro):
#   - UserCreate        → alta admin de usuarios
#   - PageParams        → Depends unificado en listados
#   - TokenPayload      → validación tipada de JWT
#   - pytest-asyncio    → tests async si se necesitan
#   - UserPublic vs UserResponse — auth vs perfil /users
#
# Docs actualizadas: REPOSITORIOS, MODELOS, este archivo.
#
# ---------------------------------------------------------------------------
# Paso 10 — Consistencia contable, soft-delete y dashboard
# ---------------------------------------------------------------------------
# Soft-delete (`activo`):
#   DELETE en accounts / categories / subcategories / transactions / users
#   desactiva; no borra historial ni hace cascade wipe del ledger.
#   POST /accounts/{id}/reactivate para reabrir una cuenta.
#
# Saldo:
#   AccountCreate usa saldo_inicial (solo apertura).
#   AccountUpdate NO permite editar saldo; solo movimientos lo cambian.
#
# Transferencias:
#   POST /transactions/transfers
#   Dos piernas + grupo_transferencia; desactivar una revierte ambas.
#
# Reports (dashboard):
#   GET /reports/summary
#   → ingresos/gastos operativos, transferencias aparte,
#     by_category_gastos / by_category_ingresos, by_month, by_account
#
# Migración: c3d4e5f6a7b8 (activo + grupo_transferencia)
#
# ---------------------------------------------------------------------------
# Paso 11 — Hardening OWASP (seguridad completa)
# ---------------------------------------------------------------------------
# Rate limit auth/webhooks, logs de auth fallidos, MFA TOTP admin,
# CORS estricto, DEBUG=False en production, FORCE_HTTPS + HSTS,
# webhooks HMAC (/webhooks/inbound), pip-audit + Dependabot.
# Ver docs/SEGURIDAD.md. Migración MFA: d4e5f6a7b8c9
#
# ---------------------------------------------------------------------------
# Paso 12 — Documentación alineada con la realidad del proyecto
# ---------------------------------------------------------------------------
# Se reescribió/amplió la documentación para onboarding sin conocimiento previo:
#   docs/INDICE.md      → mapa de lectura
#   docs/COMO_FUNCIONA.md
#   docs/NEGOCIO.md      → dinero, soft-delete, transferencias, reportes
#   docs/MODELOS.md
#   docs/API.md          → catálogo HTTP completo
#   docs/SEGURIDAD.md
#   docs/REPOSITORIOS.md
#   docs/TESTING.md
#   README.md
#
# ---------------------------------------------------------------------------
# Paso 13 — Contrapartes externas + medio de pago efectivo
# ---------------------------------------------------------------------------
# Contrapartes (`counterparties`): agenda de terceros fuera del sistema.
#   CRUD JWT + soft-delete/reactivate; ownership por user_id.
#   Transaction.contraparte_id opcional en gasto/ingreso.
#
# Medio de pago:
#   medio_pago = cuenta | efectivo
#   efectivo → moneda obligatoria, sin account_id; wallet auto
#   (banco="Efectivo", tipo="efectivo") por usuario+moneda.
#   Banco↔efectivo vía POST /transactions/transfers.
#
# Migración: e5f6a7b8c9d0
# Docs: NEGOCIO, MODELOS, API, este archivo.
#
# ---------------------------------------------------------------------------
# Paso 14 — Hardening contable + seed demo 100 usuarios
# ---------------------------------------------------------------------------
# - transactions.tipo → varchar(30) (f6a7b8c9d0e1): caben transferencia_*
# - Fondos insuficientes → 400 en gasto / transferencia_salida
# - POST /accounts con tipo=efectivo rechazado (wallet solo auto)
# - Seed: scripts/data/demo_100_users.sql + generate_demo_100_users_sql.py
#   saldos no negativos, ingresos tempranos, efectivo acotado
# - Tests: schema length, fondos insuficientes, Postgres column check
#
# ---------------------------------------------------------------------------
# Paso 15 — Prioridad FE: reports v2 + filtros + kit frontend
# ---------------------------------------------------------------------------
# Reports summary ampliado:
#   by_subcategory_*, by_medio_pago, by_counterparty (top 10),
#   period_comparison (ventana actual vs anterior).
# Transactions list: filtros medio_pago, contraparte_id, sub_category_id;
#   orden documentado fecha DESC, id DESC.
# Kit FE: docs/FRONTEND.md + Postman collection + scripts/export_openapi.py
#
# ---------------------------------------------------------------------------
# Paso 16 — Prioridad media: presupuestos, export, CI Postgres
# ---------------------------------------------------------------------------
# Presupuestos (`budgets`): límite mensual por categoría (CRUD + soft-delete).
#   GET /budgets/status + budgets_status en reports/summary (mes calendario).
# Export: GET /transactions/export?format=csv|json (mismos filtros; máx 10k).
# CI: servicio Postgres 16 + migrate + pytest unit/API + marker `postgres`.
# Migración: a7b8c9d0e1f2
#
#
