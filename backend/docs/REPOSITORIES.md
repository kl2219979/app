# Repositories (data access)

Each file in `app/repositories/` encapsulates the ORM of **one** entity.
They don't know about Pydantic or HTTP: only `Session` + models.

```
Endpoint → Service → Repository → PostgreSQL
```

---

## Transaction convention

| Who | What it does |
|-------|----------|
| Repository | `db.add` / changes + `flush()` (to get the `id`) |
| Service | Orchestrates rules and calls `db.commit()` / `db.refresh()` |

If the repository did the `commit`, it would be impossible to combine several atomic changes (e.g. tx + balance) into a single commit.

---

## Soft-delete and filters

“Product” listings filter `activo=True` by default (`only_active=True`).

There are no physical `delete()` methods in accounts/categories/transactions:
the service sets `activo=False` and calls `update`.

---

## Methods per entity

### `UserRepository` — `app/repositories/user.py`

| Method | Use |
|--------|-----|
| `get_by_id` | Load by PK |
| `get_by_correo` / `get_by_usuario` | Uniqueness / login |
| `get_by_correo_or_usuario` | Login (accepts both) |
| `exists_correo_or_usuario` | Registration (409) |
| `create` / `update` | Persistence |
| `delete` | Hard delete (rare; the product uses soft-delete in the service) |

### `RefreshTokenRepository` — `app/repositories/refresh_token.py`

| Method | Use |
|--------|-----|
| `create` | Stores the refresh hash |
| `get_active_by_hash` | Not revoked and not expired |
| `revoke` | Marks `revoked_at` |
| `revoke_all_for_user` | Global logout / deactivate user |

### `AccountRepository` — `app/repositories/account.py`

| Method | Use |
|--------|-----|
| `get_by_id` | PK |
| `get_by_id_for_user` | Ownership (+ optional `only_active`) |
| `get_cash_wallet` / `get_or_create_cash_wallet` | `tipo=efectivo` wallet per user+currency |
| `list_by_user` | Active shortcut |
| `list_filtered` | Pagination `(items, total)` + `only_active` |
| `create` / `update` | Persistence |

### `CounterpartyRepository` — `app/repositories/counterparty.py`

| Method | Use |
|--------|-----|
| `get_by_id` | PK |
| `get_by_id_for_user` | Ownership (+ optional `only_active`) |
| `list_filtered` | Pagination + `only_active` |
| `create` / `update` | Persistence |

### `CategoryRepository` — `app/repositories/category.py`

| Method | Use |
|--------|-----|
| `get_by_id` / `get_by_nombre` | Lookups |
| `list_all` / `list_filtered` | Paginated catalog |
| `create` / `update` | Persistence |

### `SubCategoryRepository` — `app/repositories/sub_category.py`

| Method | Use |
|--------|-----|
| `get_by_id` | PK |
| `list_by_category` | Shortcut |
| `list_filtered` | `category_id` filter + active + page |
| `create` / `update` | Persistence |
| `deactivate_by_category` | Logical cascade soft-delete when deactivating a category |

### `TransactionRepository` — `app/repositories/transaction.py`

| Method | Use |
|--------|-----|
| `get_by_id` | PK |
| `get_by_id_for_user` | Join with `Account` + ownership |
| `list_by_account` / `list_by_user` | Active shortcuts |
| `list_by_transfer_group` | Both legs of a transfer |
| `list_filtered` | Filters (account, category, tipo, dates, active) + page |
| `create` / `update` | Persistence |

---

## Rules for whoever writes new code

1. If the query is “for user X”, the ownership filter goes in the repository or in the service **before** mutating.
2. Don't import FastAPI/`HTTPException` in repositories.
3. Prefer `list_filtered` for paginated APIs.
4. Document new methods here when you add them.

See also: [MODELS.md](MODELS.md), [BUSINESS.md](BUSINESS.md).
