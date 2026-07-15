# Repositories (acceso a datos)

Cada archivo en `app/repositories/` encapsula el ORM de **una** entidad.
No conocen Pydantic ni HTTP: solo `Session` + models.

```
Endpoint → Service → Repository → PostgreSQL
```

---

## Convención de transacciones

| Quién | Qué hace |
|-------|----------|
| Repository | `db.add` / cambios + `flush()` (para obtener `id`) |
| Service | Orquesta reglas y llama `db.commit()` / `db.refresh()` |

Si el repository hiciera `commit`, sería imposible combinar varios cambios atómicos (ej. tx + saldo) en un solo commit.

---

## Soft-delete y filtros

Los listados “de producto” filtran `activo=True` por defecto (`only_active=True`).

No hay métodos `delete()` físicos en accounts/categories/transactions:
el service pone `activo=False` y llama `update`.

---

## Métodos por entidad

### `UserRepository` — `app/repositories/user.py`

| Método | Uso |
|--------|-----|
| `get_by_id` | Carga por PK |
| `get_by_correo` / `get_by_usuario` | Unicidad / login |
| `get_by_correo_or_usuario` | Login (acepta ambos) |
| `exists_correo_or_usuario` | Registro (409) |
| `create` / `update` | Persistencia |
| `delete` | Hard delete (raro; el producto usa soft-delete en service) |

### `RefreshTokenRepository` — `app/repositories/refresh_token.py`

| Método | Uso |
|--------|-----|
| `create` | Guarda hash del refresh |
| `get_active_by_hash` | No revocado y no expirado |
| `revoke` | Marca `revoked_at` |
| `revoke_all_for_user` | Logout global / desactivar usuario |

### `AccountRepository` — `app/repositories/account.py`

| Método | Uso |
|--------|-----|
| `get_by_id` | PK |
| `get_by_id_for_user` | Ownership (+ opcional `only_active`) |
| `get_cash_wallet` / `get_or_create_cash_wallet` | Wallet `tipo=efectivo` por usuario+moneda |
| `list_by_user` | Atajo activos |
| `list_filtered` | Paginación `(items, total)` + `only_active` |
| `create` / `update` | Persistencia |

### `CounterpartyRepository` — `app/repositories/counterparty.py`

| Método | Uso |
|--------|-----|
| `get_by_id` | PK |
| `get_by_id_for_user` | Ownership (+ opcional `only_active`) |
| `list_filtered` | Paginación + `only_active` |
| `create` / `update` | Persistencia |

### `CategoryRepository` — `app/repositories/category.py`

| Método | Uso |
|--------|-----|
| `get_by_id` / `get_by_nombre` | Lookups |
| `list_all` / `list_filtered` | Catálogo paginado |
| `create` / `update` | Persistencia |

### `SubCategoryRepository` — `app/repositories/sub_category.py`

| Método | Uso |
|--------|-----|
| `get_by_id` | PK |
| `list_by_category` | Atajo |
| `list_filtered` | Filtro `category_id` + activos + página |
| `create` / `update` | Persistencia |
| `deactivate_by_category` | Soft-delete en cascada lógica al desactivar categoría |

### `TransactionRepository` — `app/repositories/transaction.py`

| Método | Uso |
|--------|-----|
| `get_by_id` | PK |
| `get_by_id_for_user` | Join con `Account` + ownership |
| `list_by_account` / `list_by_user` | Atajos activos |
| `list_by_transfer_group` | Ambas piernas de una transferencia |
| `list_filtered` | Filtros (cuenta, categoría, tipo, fechas, activos) + página |
| `create` / `update` | Persistencia |

---

## Reglas para quien escribe código nuevo

1. Si la query es “del usuario X”, el filtro de ownership va en el repository o en el service **antes** de mutar.
2. No importes FastAPI/`HTTPException` en repositories.
3. Prefiere `list_filtered` para APIs paginadas.
4. Documenta métodos nuevos aquí cuando los agregues.

Ver también: [MODELOS.md](MODELOS.md), [NEGOCIO.md](NEGOCIO.md).
