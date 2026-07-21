# Frontend guide (first day)

HTTP contract to integrate the app without guessing.  
Complements [API.md](API.md) and [BUSINESS.md](BUSINESS.md).

---

## 1. Local startup (backend)

```bash
docker compose up db -d
./scripts/migrate.sh
psql "$DATABASE_URL" -f scripts/data/demo_100_users.sql   # optional but recommended
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

- API: `http://localhost:8000`
- Prefix: `/api/v1`
- OpenAPI/Swagger: `http://localhost:8000/docs` (if `DEBUG=true`)
- Raw spec: `http://localhost:8000/openapi.json`
- Postman collection: [`postman/App_Backend_Frontend.postman_collection.json`](postman/App_Backend_Frontend.postman_collection.json)

Default CORS: `http://localhost:5173` (Vite). Adjust `CORS_ORIGINS` in `.env`.

---

## 2. Demo users

| Field | Value |
|-------|--------|
| Username | `demo001` … `demo100` |
| Email | `demo001@example.com` … |
| Password | `Password123!` |

Each demo comes with accounts (often + a Cash wallet), counterparties, and 2026 transactions.

---

## 3. Auth (minimum viable)

1. `POST /api/v1/auth/login`  
   Body **form-urlencoded** (OAuth2): `username`, `password`  
2. Save `access_token` + `refresh_token`.  
3. All private routes: `Authorization: Bearer <access_token>`.  
4. On `401`: `POST /api/v1/auth/refresh` with `{ "refresh_token": "..." }` and replace both tokens.  
5. `GET /api/v1/auth/me` → profile.

If login responds `mfa_required` (admins): TOTP flow in [SECURITY.md](SECURITY.md). The `demo*` users are regular users without MFA.

**Rate limit:** ~10 login attempts / 60s → `429`. Don't spam logins in loops.

---

## 4. Happy path flow (screens)

```
Login → Me
     → GET /categories + /subcategories
     → GET /accounts
     → GET /counterparties
     → GET /budgets + /budgets/status   ← month's goals
     → GET /reports/summary            ← Home / dashboard
     → GET /transactions?…             ← Feed / statement
     → GET /transactions/export?format=csv  ← download
```

### Dashboard — `GET /reports/summary`

Optional query: `date_from`, `date_to`, `account_id`.

Useful fields for the UI:

| UI block | JSON fields |
|-----------|-------------|
| KPI cards | `total_ingresos`, `total_gastos`, `balance_neto`, `total_transferencias` |
| Category donut / bars | `by_category_gastos`, `by_category_ingresos` |
| Fine detail | `by_subcategory_gastos`, `by_subcategory_ingresos` |
| Cash vs account | `by_medio_pago[]` (`medio_pago`, totals, `count`) |
| Top third parties | `by_counterparty[]` (max 10) |
| Time series | `by_month[]` |
| Pockets | `by_account[]` (current `saldo` + period totals) |
| “Vs previous period” | `period_comparison` |
| Month's budgets | `budgets_status[]` |

`period_comparison`:

- If you send `date_from` + `date_to` → compares that range with the one of **equal duration** just before.
- If you don't send dates → current calendar month (`day 1` → today) vs previous calendar month.
- `*_change_pct` can be `null` if the previous period was 0.

**Transfers do not go inside expenses/income**. Show them separately.

### Feed — `GET /transactions`

**Stable** order: `fecha DESC`, then `id DESC` (most recent first).

Filters:

| Query | Example |
|-------|---------|
| `limit` / `offset` | pagination (`items`, `total`, `limit`, `offset`) |
| `account_id` | one account |
| `category_id` / `sub_category_id` | catalog |
| `contraparte_id` | “transactions with X” |
| `medio_pago` | `cuenta` \| `efectivo` |
| `tipo` | `gasto` \| `ingreso` \| `transferencia_*` |
| `date_from` / `date_to` | period |

Export the same filtered set: `GET /transactions/export?format=csv|json` (max 10k rows).

### Budgets — `/budgets`

- Create: `POST /budgets` with `category_id` + `limite` (period `mensual`).
- Progress: `GET /budgets/status` or the `budgets_status` block of the summary.
- Soft-delete / reactivate like the rest of the entities.

### Create transaction

- Own account: `medio_pago: "cuenta"` + `account_id`.
- Cash: `medio_pago: "efectivo"` + `moneda` (**without** `account_id`).
- `contraparte_id` optional.
- Expense/transfer with amount > balance → **400** `"Fondos insuficientes..."`.
- Don't create accounts with `tipo: "efectivo"` by hand → **400** (automatic wallet).

Transfers: `POST /transactions/transfers` between two of your own accounts (includes bank↔cash).

---

## 5. Errors the FE must handle

| Code | Suggested UI action |
|--------|------------------------|
| 400 | Toast with `detail` (funds, business rules) |
| 401 | Refresh; if it fails → login |
| 403 | No permission / admin MFA |
| 404 | “Not found” (also others' resources) |
| 422 | Form validation (check the body) |
| 429 | Wait / backoff (auth) |

`detail` is usually a string; in a Pydantic 422 it can be a list of errors.

---

## 6. Integration checklist

- [ ] Login + token persistence + refresh  
- [ ] Home with `/reports/summary` (KPI + month + categories + budgets)  
- [ ] Period and account filter  
- [ ] Account list with balance (incl. Cash)  
- [ ] Transaction feed with pagination  
- [ ] CSV/JSON export  
- [ ] Budget CRUD / consumption bar  
- [ ] Add expense account / cash / with counterparty  
- [ ] Transfer between accounts  
- [ ] Handle 400 insufficient funds and 401/429  

OpenAPI is always up to date via FastAPI; if you need a snapshot:

```bash
curl -s http://localhost:8000/openapi.json -o docs/openapi.snapshot.json
```
