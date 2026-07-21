# Data model (SQLAlchemy → PostgreSQL)

Code: `app/models/`.  
Versioned schema: `alembic/versions/`.  
Product rules: [BUSINESS.md](BUSINESS.md).

---

## 1. Conventions

| Concept | Convention |
|----------|------------|
| Python file / class | Singular: `user.py` → `User` |
| Postgres table | Plural: `users` |
| Money | `Numeric(14, 2)` ↔ `Decimal` (never `Float`) |
| Soft-delete | Boolean column `activo` (default `true`) |
| Auditing | `creado_en` / `actualizado_en` with timezone |
| FK | Indexes on FK columns used in filters |

---

## 2. Relationship diagram

```
users 1 ──────────── N accounts 1 ──────────── N transactions
  │                      │                          │    │    │
  │                      │ (includes wallet         │    │    │
  │                      │  tipo=efectivo)          │    │    │
  │                      │                          │    │    │
  ├──── N counterparties ───────────────────────────┘    │    │
  ├──── N budgets ───────────────────────────────────────│────┘ (per category)
  │                                                      │
  └──── N refresh_tokens                                 │
                                                         │
categories 1 ──── N sub_categories ──────────────────────┘
     │
     └──────────────── N transactions / budgets
```

A `Transaction` always points to:

- 1 `Account` (whose money it is; if `medio_pago=efectivo`, it is the self-managed wallet),
- 1 `Category` + 1 `SubCategory` (classification; the service validates consistency),
- 0..1 `Counterparty` (optional third party outside the system).

A `Budget` is a single monthly limit per `(user_id, category_id)`.

---

## 3. Tables in detail

### 3.1 `users`

The person who logs in.

| Column | Type | Notes |
|---------|------|-------|
| `id` | int PK | Autoincrement |
| `nombres`, `apellidos` | varchar | |
| `fecha_nacimiento` | date | |
| `genero` | varchar(30) | |
| `correo` | varchar unique indexed | Alternate login |
| `usuario` | varchar(50) unique indexed | Primary login |
| `contrasena_hash` | varchar | bcrypt; **never** plain text |
| `rol` | varchar(20) | `"user"` (default) \| `"admin"` |
| `activo` | bool | Access soft-delete |
| `mfa_enabled` | bool | TOTP active |
| `mfa_secret_encrypted` | text nullable | Encrypted TOTP secret (Fernet) |
| `creado_en` | timestamptz | |

Relationships:

- `accounts` (no cascade delete-orphan: deactivating a user ≠ deleting accounts).
- `refresh_tokens` (yes, with cascade: hard-deleting a user clears tokens; in practice we use soft-delete).

Python property: `user.is_admin` → `rol == "admin"`.

### 3.2 `refresh_tokens`

Long-lived sessions.

| Column | Type | Notes |
|---------|------|-------|
| `id` | int PK | |
| `user_id` | FK → users | |
| `token_hash` | varchar unique | SHA-256 of the opaque token |
| `expires_at` | timestamptz | |
| `creado_en` | timestamptz | |
| `revoked_at` | timestamptz nullable | If not null, it is revoked |

The client stores the refresh in clear text; the DB stores **only** the hash.

### 3.3 `accounts`

The user's financial account.

| Column | Type | Notes |
|---------|------|-------|
| `id` | int PK | |
| `user_id` | FK → users | Owner |
| `banco` | varchar(100) | Visible name |
| `tipo` | varchar(100) | savings, checking, digital, **efectivo** (auto wallet)… |
| `moneda` | varchar(10) | COP, USD… |
| `saldo` | Numeric(14,2) | Only changes through transactions (+ saldo_inicial at creation) |
| `activo` | bool | Soft-delete |
| `creado_en`, `actualizado_en` | timestamptz | |

Cash wallet: the service creates it with `banco="Efectivo"`, `tipo="efectivo"`, one per user+currency (`AccountRepository.get_or_create_cash_wallet`).

**Important:** the `transactions` relationship does **not** use `delete-orphan`. Deactivating the account does not delete the history.

### 3.4 `counterparties`

Address book of third parties (accounts/people **outside** the system).

| Column | Type | Notes |
|---------|------|-------|
| `id` | int PK | |
| `user_id` | FK → users | Owner |
| `nombre` | varchar(150) | Required |
| `banco` | varchar(100) nullable | External bank (optional) |
| `numero_cuenta` | varchar(100) nullable | Unregistered account (optional) |
| `notas` | text nullable | |
| `activo` | bool | Soft-delete |
| `creado_en`, `actualizado_en` | timestamptz | |

### 3.5 `categories`

Global catalog (shared across users).

| Column | Type | Notes |
|---------|------|-------|
| `id` | int PK | |
| `nombre` | varchar unique | |
| `descripcion` | varchar | |
| `activo` | bool | Soft-delete |
| `creado_en`, `actualizado_en` | timestamptz | |

On deactivation: the service also deactivates child subcategories.

### 3.6 `sub_categories`

| Column | Type | Notes |
|---------|------|-------|
| `id` | int PK | |
| `category_id` | FK → categories | |
| `nombre`, `descripcion` | varchar | |
| `activo` | bool | |
| `creado_en`, `actualizado_en` | timestamptz | |

### 3.7 `transactions`

Money movement (ledger).

| Column | Type | Notes |
|---------|------|-------|
| `id` | int PK | |
| `account_id` | FK → accounts | Always present (wallet if cash) |
| `category_id` | FK → categories | |
| `sub_category_id` | FK → sub_categories | Must belong to `category_id` |
| `contraparte_id` | FK → counterparties nullable | Optional third party |
| `monto` | Numeric(14,2) | Always > 0 in the API |
| `tipo` | varchar(30) | see below |
| `medio_pago` | varchar(20) | `cuenta` \| `efectivo` |
| `fecha` | date | Accounting date |
| `descripcion` | varchar | |
| `activo` | bool | Soft-delete |
| `grupo_transferencia` | varchar(36) nullable | UUID linking the 2 legs |
| `creado_en`, `actualizado_en` | timestamptz | |

`tipo` values:

- `gasto`
- `ingreso`
- `transferencia_salida`
- `transferencia_entrada`

`medio_pago` values:

- `cuenta` — requires `account_id` in the API
- `efectivo` — requires `moneda` in the API; the service assigns the wallet

### 3.8 `budgets`

Monthly spending limit per category (one active record per user+category).

| Column | Type | Notes |
|---------|------|-------|
| `id` | int PK | |
| `user_id` | FK → users | Ownership |
| `category_id` | FK → categories | Unique with `user_id` |
| `limite` | Numeric(14,2) | Period goal/cap |
| `moneda` | varchar(10) | Default COP |
| `periodo` | varchar(20) | Only `mensual` for now |
| `activo` | bool | Soft-delete |
| `creado_en`, `actualizado_en` | timestamptz | |

The month's consumption is computed by summing active `gasto` records of that category in the calendar month.

---

## 4. Accounting (technical summary)

In `TransactionService._delta`:

- credit (`ingreso`, `transferencia_entrada`) → `+monto`
- debit (`gasto`, `transferencia_salida`) → `-monto`

Deactivation:

- simple transaction → applies `-delta` to the balance and `activo=false`
- with `grupo_transferencia` → the same for **all** legs of the group

Reports only sum rows with `activo=true`.

---

## 5. Migrations (Alembic history)

Current head: `a7b8c9d0e1f2`.

| Revision | What it adds |
|----------|------------|
| `72b0c849201b` | Initial schema |
| `a1b2c3d4e5f6` | `transactions.tipo` |
| `b2c3d4e5f6a7` | `users.rol` + `refresh_tokens` table |
| `c3d4e5f6a7b8` | `activo` on entities + `grupo_transferencia` |
| `d4e5f6a7b8c9` | `mfa_enabled` + `mfa_secret_encrypted` |
| `e5f6a7b8c9d0` | `counterparties` + `medio_pago` / `contraparte_id` on txs |
| `f6a7b8c9d0e1` | `transactions.tipo` widened to varchar(30) (fits transfers) |
| `a7b8c9d0e1f2` | `budgets` table (monthly limit per category) |

Apply:

```bash
./scripts/migrate.sh
# or: alembic upgrade head
```

Add a new model:

1. Create `app/models/foo.py` inheriting from `Base`
2. Import it in `app/models/__init__.py`
3. `alembic revision --autogenerate -m "add foo"`
4. Review the generated file
5. `./scripts/migrate.sh`

---

## 6. Seeds

```bash
python scripts/seed.py
```

Catalog in `app/services/seed.py` (idempotent), includes among others:

- Alimentación, Transporte, Vivienda, Salud, Ocio, Educación
- Ingresos
- Transferencias → “Entre mis cuentas”

---

## 7. Files

```
app/models/user.py
app/models/refresh_token.py
app/models/account.py
app/models/counterparty.py
app/models/category.py
app/models/sub_category.py
app/models/transaction.py
app/models/__init__.py   ← imports all (Alembic detects them)
```
