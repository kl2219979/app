# Business rules (financial product)

This document explains **how the app behaves for the end user**.
It is not code: it is the mental “contract” that backend, frontend, and QA must respect.

If something in the code contradicts this, the bug is in the code (not in the doc).

---

## 1. What problem the app solves

It is a **personal finance tracker**:

- A user has **accounts** (bank, wallet, etc.) with money (`saldo`).
- They record **transactions**: expenses and income.
- They can **transfer** money between their own accounts.
- They query **reports** for a dashboard (totals, by category, by month, by account).
- There is a **global catalog** of categories/subcategories (maintained by admin).

---

## 2. Guiding principle: money is not invented

### 2.1 An account's balance

| Moment | What happens to `saldo` |
|---------|----------------------|
| Create account | `saldo_inicial` is accepted (opening / money already held). |
| PUT account | **Forbidden** to change the balance. Only `banco`, `tipo`, `moneda`. |
| Create expense | Subtracts `monto` from the balance (**requires sufficient funds**). |
| Create income | Adds `monto` to the balance. |
| Transfer | Subtracts from source (**sufficient funds**), adds to destination. |
| Edit transaction | The old effect is reverted and the new one applied (same funds check). |
| Deactivate transaction | The effect is reverted; the history remains. |

The frontend must **never** “set” an arbitrary balance after creating the account.
If the balance doesn't add up, the source of the error is in the transactions (or a bug).

Expense/transfer with `monto` greater than the balance → **400** `"Fondos insuficientes en la cuenta"`.
Overdrafts are not allowed.

### 2.2 Transaction types

| `tipo` | Effect on balance | Counts in “expense/income” reports? |
|--------|-----------------|-------------------------------------------|
| `gasto` | Subtracts | Yes → `total_gastos` |
| `ingreso` | Adds | Yes → `total_ingresos` |
| `transferencia_salida` | Subtracts | No (goes to `total_transferencias`) |
| `transferencia_entrada` | Adds | No |

Transfers must **not inflate** the month's expense: moving $100 from Nequi to Bancolombia is not a $100 expense.

---

## 3. Soft-delete (deactivate, don't delete)

### 3.1 Why

Users **live with** the app for years. Cascade deletion:

- destroys the accounting history,
- makes audits impossible,
- can leave inconsistent balances if done wrong.

That's why almost every HTTP DELETE means: `activo = false`.

### 3.2 Behavior per entity

| Entity | DELETE does | History | Balance |
|---------|-------------|-----------|-------|
| User | `activo=false` + revokes refresh | Accounts/txs are preserved | Intact |
| Account | `activo=false` | Transactions are preserved | **Not touched** |
| Counterparty | `activo=false` | Old txs keep the FK | — |
| Category | `activo=false` + deactivates child subcategories | Old txs are preserved | — |
| Subcategory | `activo=false` | Same | — |
| Transaction | `activo=false` | Row remains | Impact is **reverted** |
| Transfer (one leg) | Deactivates **both** legs of the `grupo_transferencia` | Same | Reverts source and destination |

### 3.3 Listings

By default, listings show only `activo=true`.

- Accounts / categories / subcategories: `include_inactive=true` query to see deactivated ones.
- Accounts: `POST /accounts/{id}/reactivate` to use them again.
- Inactive transactions: do not appear in listings or reports; `GET` by id returns 404 “not found or inactive”.

### 3.4 What we do NOT do

- There is no `CASCADE` that deletes transactions when deleting an account.
- The ledger is not physically deleted by a category DELETE.
- Creating new transactions on inactive accounts/categories is not allowed.

---

## 4. Ownership (each user sees their own)

| Resource | Rule |
|---------|-------|
| Accounts | Only those of the JWT's `user_id` |
| Counterparties | Only those of the JWT's `user_id` |
| Transactions | Only those of the user's own accounts |
| Reports | Only aggregates the authenticated user's data |
| Users `/{id}` | Only your own `id` |
| Categories / Subcategories | **Global** catalog (read with any JWT; write admin+MFA) |

Trying to operate on someone else's account/counterparty → 404 (we don't reveal existence).

---

## 4.1 Counterparties (third parties outside the system)

Personal address book of recipients/senders that are **not** your own accounts:

- Fields: `nombre` (required), `banco`, `numero_cuenta`, `notas` (optional).
- An expense/income can carry `contraparte_id` to document who was paid / who it was received from.
- It does not move anyone else's balance: money enters/leaves **your** account or cash wallet.
- Soft-delete: inactive counterparties cannot be used in new txs; the history keeps the FK.

---

## 4.2 Payment method (`cuenta` | `efectivo`)

| `medio_pago` | What the client sends | What the backend does |
|--------------|---------------------|---------------------|
| `cuenta` | `account_id` required | Uses that active own account |
| `efectivo` | `moneda` required; **no** `account_id` | Resolves/creates a `tipo=efectivo`, `banco=Efectivo` wallet per user+currency |

The wallet appears in `GET /accounts` and counts toward balances/reports. It is **not** created with `POST /accounts` (`tipo=efectivo` → 400): only via `medio_pago=efectivo` or transfers toward the wallet.

Bank↔cash is done with `POST /transactions/transfers` to/from that wallet.

---

## 5. Transfers

Requirements:

1. Both accounts belong to the same user.
2. Both **active**.
3. Same `moneda`.
4. Source ≠ destination.
5. Active and consistent category/subcategory (the sub belongs to the category).

Result: two rows linked by `grupo_transferencia` (UUID).

A leg is not edited via PUT (you must deactivate the group and create another transfer).

---

## 6. Catalog (categories)

- It is maintained by an **admin** with active MFA.
- Regular users only read the catalog.
- Initial seed: `python scripts/seed.py` (includes “Transferencias”, “Ingresos”, etc.).
- Idempotent: it can be run multiple times.

Promote admin:

```bash
python scripts/promote_admin.py <user_or_email>
# Then: POST /auth/mfa/setup → Authenticator app → POST /auth/mfa/confirm
```

Without confirmed MFA, the admin **cannot** mutate the catalog (403).

---

## 7. Reports (dashboard)

`GET /reports/summary` (active transactions only):

- `total_ingresos` / `total_gastos` / `balance_neto` (income − expenses)
- `total_transferencias` (sum of outflows)
- `by_category_gastos` / `by_category_ingresos`
- `by_subcategory_gastos` / `by_subcategory_ingresos`
- `by_medio_pago` (account vs cash)
- `by_counterparty` (top 10 third parties)
- `by_month` (year-month buckets)
- `by_account` (current balance + operational totals per account)
- `period_comparison` (current vs previous period)

Optional filters: `account_id`, `date_from`, `date_to`.

---

## 8. Pagination

All main listings respond with:

```json
{
  "items": [ ... ],
  "total": 42,
  "limit": 20,
  "offset": 0
}
```

Query: `limit` (1–100, default 20), `offset` (default 0).

---

## 9. Mental checklist for the frontend

1. After login, save `access_token` and `refresh_token`.
2. If `mfa_required`, go to the TOTP screen → `/auth/mfa/verify`.
3. Create the account with `saldo_inicial`, never edit `saldo` afterwards.
4. Expenses/income with correct `tipo` and `medio_pago`; cash uses `moneda` (no `account_id`).
5. External third parties: CRUD `/counterparties` + optional `contraparte_id` on the transaction.
6. Transfers via `/transactions/transfers` (includes bank↔cash wallet).
7. DELETE = “archive”; offer to reactivate accounts/counterparties where applicable.
8. Dashboard: use `/reports/summary`, do not blindly recalculate by summing transfers as expenses.
9. Category write: only if the user is admin **with MFA**.

More HTTP detail: [API.md](API.md).  
More table detail: [MODELS.md](MODELS.md).
