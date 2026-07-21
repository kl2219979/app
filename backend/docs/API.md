# HTTP API — full catalog

Prefix: **`/api/v1`**

Authentication:

| Label | Meaning |
|----------|-------------|
| **public** | No Bearer |
| **JWT** | `Authorization: Bearer <access_token>` header |
| **JWT+admin+MFA** | User JWT with `rol=admin` and `mfa_enabled=true` |

Paginated listing format:

```json
{ "items": [ ... ], "total": 42, "limit": 20, "offset": 0 }
```

Local base: `http://localhost:8000`  
Swagger (only if `DEBUG=true`): `http://localhost:8000/docs`

Product rules: [BUSINESS.md](BUSINESS.md).  
Detailed auth: [SECURITY.md](SECURITY.md).

---

## health

### `GET /health`

- **Auth:** public  
- **What it does:** checks that the process responds (does not query the DB).  
- **Typical response:** `{ "status": "ok" }` (see current implementation).

---

## auth

### `POST /auth/register`

- **Auth:** public (rate limit)
- **JSON body:**
  - `nombres`, `apellidos`, `fecha_nacimiento`, `genero`
  - `correo`, `usuario`, `contrasena` (min. 8)
- **201:** public user (without password hash)
- **409:** email or username already exist

### `POST /auth/login`

- **Auth:** public (rate limit)
- **Body:** OAuth2 form (`application/x-www-form-urlencoded`)
  - `username` = email **or** username
  - `password`
- **200 — regular user / admin without MFA yet:**
  ```json
  {
    "access_token": "...",
    "refresh_token": "...",
    "token_type": "bearer",
    "mfa_required": false,
    "mfa_token": null
  }
  ```
- **200 — admin with active MFA:**
  ```json
  {
    "access_token": null,
    "refresh_token": null,
    "token_type": "bearer",
    "mfa_required": true,
    "mfa_token": "<short challenge JWT>"
  }
  ```
- **401:** invalid credentials (logged **without** password)
- **403:** deactivated user

### `POST /auth/mfa/verify`

- **Auth:** public (rate limit); uses the `mfa_token` from login
- **Body:** `{ "mfa_token": "...", "code": "123456" }`
- **200:** `access_token` + `refresh_token`

### `POST /auth/mfa/setup`

- **Auth:** JWT
- **What it does:** generates a TOTP secret (does not enable MFA yet)
- **200:** `{ "secret", "otpauth_uri", "mfa_enabled": false }`
- Scan `otpauth_uri` with Google Authenticator / Authy / etc.

### `POST /auth/mfa/confirm`

- **Auth:** JWT
- **Body:** `{ "code": "123456" }`
- **200:** user with `mfa_enabled: true`

### `POST /auth/refresh`

- **Auth:** public (rate limit)
- **Body:** `{ "refresh_token": "..." }`
- **200:** new access+refresh pair (the previous one is **revoked**)
- **403:** admin without MFA cannot refresh

### `POST /auth/logout`

- **Auth:** JWT
- **Optional body:** `{ "refresh_token": "..." }`
  - With token: revokes that refresh **only if it belongs to the authenticated user**
  - Without token: revokes **all** of the user's refresh tokens
- **204**

### `GET /auth/me`

- **Auth:** JWT
- **200:** profile (`id`, nombres, correo, usuario, `rol`, `activo`, `mfa_enabled`, …)

---

## users

### `GET /users/{user_id}`

- **Auth:** JWT  
- Only your own `user_id` (otherwise → 403).

### `PUT /users/{user_id}`

- **Auth:** JWT (self)  
- Partial body: nombres, apellidos, fecha_nacimiento, genero, correo, usuario, contrasena.

### `DELETE /users/{user_id}`

- **Auth:** JWT (self)  
- Soft-delete: `activo=false` + revokes refresh. **Does not delete** accounts or transactions.  
- **204**

---

## accounts

### `GET /accounts`

- **Auth:** JWT  
- Query: `limit`, `offset`, `include_inactive` (bool, default false)

### `GET /accounts/{account_id}`

- **Auth:** JWT (own; includes inactive ones if you know the id)

### `POST /accounts`

- **Auth:** JWT  
- Body:
  - `banco`, `tipo`, `moneda`
  - `saldo_inicial` (Decimal ≥ 0) ← **only here**
- The response includes `saldo` (equal to the initial one) and `activo: true`

### `PUT /accounts/{account_id}`

- **Auth:** JWT  
- Allowed body: `banco`, `tipo`, `moneda`  
- Sending `saldo` → **422** (`extra=forbid`)  
- Inactive account → 400

### `DELETE /accounts/{account_id}`

- Soft-delete `activo=false`. History intact. Balance is **not** altered.  
- **204**

### `POST /accounts/{account_id}/reactivate`

- Sets `activo=true` again.  
- **200** with the account

---

## counterparties

Address book of third parties outside the system (JWT, own ownership).

### `GET /counterparties`

Query: `limit`, `offset`, `include_inactive`

### `GET /counterparties/{counterparty_id}`

### `POST /counterparties`

Body: `nombre` (required), `banco`, `numero_cuenta`, `notas` (optional)

### `PUT /counterparties/{counterparty_id}`

Inactive → 400 (reactivate first).

### `DELETE /counterparties/{counterparty_id}`

Soft-delete. **204**

### `POST /counterparties/{counterparty_id}/reactivate`

---

## categories

Read: any JWT. Write: **JWT+admin+MFA**.

### `GET /categories`

Query: `limit`, `offset`, `include_inactive`

### `GET /categories/{category_id}`

### `POST /categories`

Body: `nombre`, `descripcion`  
**409** if the name already exists

### `PUT /categories/{category_id}`

### `DELETE /categories/{category_id}`

Deactivates the category **and** child subcategories. Transaction history is preserved.  
**204**

---

## subcategories

### `GET /subcategories`

Query: `category_id` (optional), `limit`, `offset`, `include_inactive`

### `GET /subcategories/{subcategory_id}`

### `POST /subcategories` — admin+MFA

Body: `category_id`, `nombre`, `descripcion`  
The category must exist and be active.

### `PUT /subcategories/{subcategory_id}` — admin+MFA

### `DELETE /subcategories/{subcategory_id}` — admin+MFA

Soft-delete. **204**

---

## transactions

### `GET /transactions`

- **Auth:** JWT  
- Query:
  - `limit`, `offset`
  - `account_id`, `category_id`, `sub_category_id`, `contraparte_id`
  - `medio_pago`: `cuenta` \| `efectivo`
  - `tipo`: `gasto` \| `ingreso` \| `transferencia_salida` \| `transferencia_entrada`
  - `date_from`, `date_to` (YYYY-MM-DD)
- Only the user's **active** transactions  
- **Stable order:** `fecha DESC`, `id DESC` (most recent first)
- Page: `{ items, total, limit, offset }`

### `GET /transactions/export`

- **Auth:** JWT  
- Query: same filters as the listing + `format=csv|json` (default `csv`)  
- Downloads up to **10_000** active transactions  
- CSV: `Content-Disposition` attachment; JSON: list of objects

### `POST /transactions`

Body (payment with own account):

```json
{
  "account_id": 1,
  "category_id": 2,
  "sub_category_id": 3,
  "monto": "15.50",
  "tipo": "gasto",
  "medio_pago": "cuenta",
  "contraparte_id": 10,
  "fecha": "2026-07-12",
  "descripcion": "Almuerzo"
}
```

Body (cash payment — without `account_id`):

```json
{
  "category_id": 2,
  "sub_category_id": 3,
  "monto": "15.50",
  "tipo": "gasto",
  "medio_pago": "efectivo",
  "moneda": "COP",
  "contraparte_id": 10,
  "fecha": "2026-07-12",
  "descripcion": "Taxi"
}
```

Rules:

- `tipo` only `gasto` \| `ingreso` on create.
- `medio_pago` default `cuenta`. With `cuenta` → `account_id` required. With `efectivo` → `moneda` required and **do not** send `account_id` (422).
- `contraparte_id` optional; must be your own and active (404 if not).
- Cash resolves/creates a `tipo=efectivo` wallet and updates its balance.
- Expense (and transfers) with amount > balance → **400** insufficient funds.
- The response includes `medio_pago`, `contraparte_id`, `account_id` (always the accounting id).

### `POST /transactions/transfers`

Body:

```json
{
  "from_account_id": 1,
  "to_account_id": 2,
  "monto": "100.00",
  "fecha": "2026-07-12",
  "descripcion": "Ahorro",
  "category_id": 8,
  "sub_category_id": 20
}
```

Response: `{ "grupo_transferencia", "salida", "entrada" }`  
Same currency required. Also works for bank↔cash wallet (the wallet appears in `GET /accounts`).
No `contraparte_id`.

### `GET /transactions/{transaction_id}`

### `PUT /transactions/{transaction_id}`

Only operational transactions (`gasto`/`ingreso`) **without** `grupo_transferencia`.  
Can change `medio_pago` / `account_id` / `moneda` / `contraparte_id` with the same create rules.  
Recomputes balances (reverts old, applies new).

### `DELETE /transactions/{transaction_id}`

Soft-delete + **reverts balance**.  
If it is a transfer, deactivates both legs.  
**204**

---

## budgets

Monthly budget per category (`(user_id, category_id)` unique).

### `GET /budgets`

- **Auth:** JWT — page `{ items, total, limit, offset }` (active)

### `GET /budgets/status`

- **Auth:** JWT  
- List of active budgets with `gastado`, `restante`, `pct_usado`, `excedido` (current calendar month)

### `GET /budgets/{budget_id}` / `GET /budgets/{budget_id}/status`

### `POST /budgets`

Body: `{ "category_id": 2, "limite": "500000.00", "moneda": "COP", "periodo": "mensual" }`  
If an inactive one already existed for that category, it reactivates it and updates the limit.

### `PUT /budgets/{budget_id}`

### `DELETE /budgets/{budget_id}`

Soft-delete → **204**

### `POST /budgets/{budget_id}/reactivate`

---

## reports

### `GET /reports/summary`

- **Auth:** JWT  
- Query: `account_id`, `date_from`, `date_to`

Response (fields):

| Field | Meaning |
|-------|-------------|
| `total_ingresos` | Sum of active `tipo=ingreso` |
| `total_gastos` | Sum of active `tipo=gasto` |
| `balance_neto` | income − expenses |
| `total_transferencias` | Sum of `transferencia_salida` |
| `by_category_gastos` / `by_category_ingresos` | Breakdown by category |
| `by_subcategory_gastos` / `by_subcategory_ingresos` | Breakdown by subcategory |
| `by_medio_pago` | `cuenta` vs `efectivo` totals |
| `by_counterparty` | Top 10 third parties (expenses+income with `contraparte_id`) |
| `by_month` | Totals by year/month |
| `by_account` | Current balance + totals per account |
| `budgets_status` | Active budgets vs the calendar month's spending |
| `period_comparison` | Current vs previous period (same lengths or calendar month) |
| `date_from`, `date_to`, `account_id` | Echo of filters |

`period_comparison`: with both date filters → previous window of equal duration; without dates → current month (day 1→today) vs previous calendar month. `*_change_pct` is `null` if the previous one was 0.

FE guide: [FRONTEND.md](FRONTEND.md).

---

## webhooks

### `POST /webhooks/inbound`

- **Auth:** HMAC signature (not JWT)
- **Required header:** `X-Webhook-Signature: t=<unix>,v1=<hex>`
- **JSON body:** `{ "event": "name", "data": { ... } }`
- **What it does:** validates signature + schema; does **not** make outgoing HTTP to payload URLs (anti-SSRF)
- **202:** `{ "received": true, "event": "..." }`
- Its own rate limit (more lenient than auth)

How it is signed (same algorithm as the server):

1. `signed = f"{timestamp}.".encode() + raw_body`
2. `v1 = HMAC_SHA256(WEBHOOK_SECRET, signed).hexdigest()`
3. Header = `t={timestamp},v1={v1}`
4. Max window: 300 seconds

Python utility: `app.core.webhooks.sign_payload` / `verify_signature`.

---

## Common HTTP errors

| Code | When |
|--------|--------|
| 400 | Business rule (insufficient funds, inactive account, different currencies, editing a transfer, creating `tipo=efectivo`…) |
| 401 | No token / invalid token / failed login / bad webhook signature |
| 403 | You are not the owner / not admin / admin without MFA / HTTPS required in prod |
| 404 | Nonexistent resource or not yours (often indistinguishable on purpose) |
| 409 | Conflict (duplicate email, category name) |
| 422 | Pydantic validation (invalid fields / `saldo` in account PUT) |
| 429 | Rate limit (auth / webhooks) — see `docs/TESTING.md` if testing in bulk |
| 503 | Webhook without `WEBHOOK_SECRET` configured |

---

## Mini happy path (frontend)

1. `POST /auth/register`  
2. `POST /auth/login` → save tokens  
3. `POST /accounts` with `saldo_inicial`  
4. `GET /categories` + `GET /subcategories?category_id=`  
5. `POST /transactions` (expense/income)  
6. `GET /reports/summary`  
7. When the access expires: `POST /auth/refresh`  
8. On logout: `POST /auth/logout`
