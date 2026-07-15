# Modelo de datos (SQLAlchemy → PostgreSQL)

Código: `app/models/`.  
Esquema versionado: `alembic/versions/`.  
Reglas de producto: [NEGOCIO.md](NEGOCIO.md).

---

## 1. Convenciones

| Concepto | Convención |
|----------|------------|
| Archivo / clase Python | Singular: `user.py` → `User` |
| Tabla Postgres | Plural: `users` |
| Dinero | `Numeric(14, 2)` ↔ `Decimal` (nunca `Float`) |
| Soft-delete | Columna booleana `activo` (default `true`) |
| Auditoría | `creado_en` / `actualizado_en` con timezone |
| FK | Índices en columnas FK usadas en filtros |

---

## 2. Diagrama de relaciones

```
users 1 ──────────── N accounts 1 ──────────── N transactions
  │                      │                          │    │    │
  │                      │ (incluye wallet          │    │    │
  │                      │  tipo=efectivo)          │    │    │
  │                      │                          │    │    │
  ├──── N counterparties ───────────────────────────┘    │    │
  ├──── N budgets ───────────────────────────────────────│────┘ (por category)
  │                                                      │
  └──── N refresh_tokens                                 │
                                                         │
categories 1 ──── N sub_categories ──────────────────────┘
     │
     └──────────────── N transactions / budgets
```

Una `Transaction` apunta siempre a:

- 1 `Account` (de quién es el dinero; si `medio_pago=efectivo`, es el wallet auto-gestionado),
- 1 `Category` + 1 `SubCategory` (clasificación; el service valida coherencia),
- 0..1 `Counterparty` (tercero opcional fuera del sistema).

Un `Budget` es límite mensual único por `(user_id, category_id)`.

---

## 3. Tablas al detalle

### 3.1 `users`

Persona que inicia sesión.

| Columna | Tipo | Notas |
|---------|------|-------|
| `id` | int PK | Autoincrement |
| `nombres`, `apellidos` | varchar | |
| `fecha_nacimiento` | date | |
| `genero` | varchar(30) | |
| `correo` | varchar unique indexed | Login alternativo |
| `usuario` | varchar(50) unique indexed | Login principal |
| `contrasena_hash` | varchar | bcrypt; **nunca** texto plano |
| `rol` | varchar(20) | `"user"` (default) \| `"admin"` |
| `activo` | bool | Soft-delete de acceso |
| `mfa_enabled` | bool | TOTP activo |
| `mfa_secret_encrypted` | text nullable | Secreto TOTP cifrado (Fernet) |
| `creado_en` | timestamptz | |

Relaciones:

- `accounts` (sin cascade delete-orphan: desactivar usuario ≠ borrar cuentas).
- `refresh_tokens` (sí con cascade: al borrar usuario hard, limpia tokens; en práctica usamos soft-delete).

Propiedad Python: `user.is_admin` → `rol == "admin"`.

### 3.2 `refresh_tokens`

Sesiones de largo plazo.

| Columna | Tipo | Notas |
|---------|------|-------|
| `id` | int PK | |
| `user_id` | FK → users | |
| `token_hash` | varchar unique | SHA-256 del token opaco |
| `expires_at` | timestamptz | |
| `creado_en` | timestamptz | |
| `revoked_at` | timestamptz nullable | Si no es null, está revocado |

El cliente guarda el refresh en claro; la BD **solo** el hash.

### 3.3 `accounts`

Cuenta financiera del usuario.

| Columna | Tipo | Notas |
|---------|------|-------|
| `id` | int PK | |
| `user_id` | FK → users | Dueño |
| `banco` | varchar(100) | Nombre visible |
| `tipo` | varchar(100) | ahorros, corriente, digital, **efectivo** (wallet auto)… |
| `moneda` | varchar(10) | COP, USD… |
| `saldo` | Numeric(14,2) | Solo cambia por movimientos (+ saldo_inicial al crear) |
| `activo` | bool | Soft-delete |
| `creado_en`, `actualizado_en` | timestamptz | |

Wallet de efectivo: el service lo crea con `banco="Efectivo"`, `tipo="efectivo"`, uno por usuario+moneda (`AccountRepository.get_or_create_cash_wallet`).

**Importante:** la relación `transactions` **no** usa `delete-orphan`. Desactivar la cuenta no borra el historial.

### 3.4 `counterparties`

Agenda de terceros (cuentas/personas **fuera** del sistema).

| Columna | Tipo | Notas |
|---------|------|-------|
| `id` | int PK | |
| `user_id` | FK → users | Dueño |
| `nombre` | varchar(150) | Obligatorio |
| `banco` | varchar(100) nullable | Banco ajeno (opcional) |
| `numero_cuenta` | varchar(100) nullable | Cuenta no registrada (opcional) |
| `notas` | text nullable | |
| `activo` | bool | Soft-delete |
| `creado_en`, `actualizado_en` | timestamptz | |

### 3.5 `categories`

Catálogo global (compartido entre usuarios).

| Columna | Tipo | Notas |
|---------|------|-------|
| `id` | int PK | |
| `nombre` | varchar unique | |
| `descripcion` | varchar | |
| `activo` | bool | Soft-delete |
| `creado_en`, `actualizado_en` | timestamptz | |

Al desactivar: el service también desactiva subcategorías hijas.

### 3.6 `sub_categories`

| Columna | Tipo | Notas |
|---------|------|-------|
| `id` | int PK | |
| `category_id` | FK → categories | |
| `nombre`, `descripcion` | varchar | |
| `activo` | bool | |
| `creado_en`, `actualizado_en` | timestamptz | |

### 3.7 `transactions`

Movimiento de dinero (ledger).

| Columna | Tipo | Notas |
|---------|------|-------|
| `id` | int PK | |
| `account_id` | FK → accounts | Siempre presente (wallet si efectivo) |
| `category_id` | FK → categories | |
| `sub_category_id` | FK → sub_categories | Debe pertenecer a `category_id` |
| `contraparte_id` | FK → counterparties nullable | Tercero opcional |
| `monto` | Numeric(14,2) | Siempre > 0 en API |
| `tipo` | varchar(30) | ver abajo |
| `medio_pago` | varchar(20) | `cuenta` \| `efectivo` |
| `fecha` | date | Fecha contable |
| `descripcion` | varchar | |
| `activo` | bool | Soft-delete |
| `grupo_transferencia` | varchar(36) nullable | UUID que une las 2 piernas |
| `creado_en`, `actualizado_en` | timestamptz | |

Valores de `tipo`:

- `gasto`
- `ingreso`
- `transferencia_salida`
- `transferencia_entrada`

Valores de `medio_pago`:

- `cuenta` — requiere `account_id` en la API
- `efectivo` — requiere `moneda` en la API; el service asigna el wallet

### 3.8 `budgets`

Límite mensual de gasto por categoría (un registro activo por usuario+categoría).

| Columna | Tipo | Notas |
|---------|------|-------|
| `id` | int PK | |
| `user_id` | FK → users | Ownership |
| `category_id` | FK → categories | Único con `user_id` |
| `limite` | Numeric(14,2) | Meta/tope del periodo |
| `moneda` | varchar(10) | Default COP |
| `periodo` | varchar(20) | Solo `mensual` por ahora |
| `activo` | bool | Soft-delete |
| `creado_en`, `actualizado_en` | timestamptz | |

El consumo del mes se calcula sumando `gasto` activos de esa categoría en el mes calendario.

---

## 4. Contabilidad (resumen técnico)

En `TransactionService._delta`:

- crédito (`ingreso`, `transferencia_entrada`) → `+monto`
- débito (`gasto`, `transferencia_salida`) → `-monto`

Desactivar:

- movimiento simple → aplica `-delta` al saldo y `activo=false`
- con `grupo_transferencia` → lo mismo para **todas** las piernas del grupo

Reportes solo suman filas con `activo=true`.

---

## 5. Migraciones (historial Alembic)

Head actual: `a7b8c9d0e1f2`.

| Revisión | Qué aporta |
|----------|------------|
| `72b0c849201b` | Esquema inicial |
| `a1b2c3d4e5f6` | `transactions.tipo` |
| `b2c3d4e5f6a7` | `users.rol` + tabla `refresh_tokens` |
| `c3d4e5f6a7b8` | `activo` en entidades + `grupo_transferencia` |
| `d4e5f6a7b8c9` | `mfa_enabled` + `mfa_secret_encrypted` |
| `e5f6a7b8c9d0` | `counterparties` + `medio_pago` / `contraparte_id` en txs |
| `f6a7b8c9d0e1` | `transactions.tipo` ampliado a varchar(30) (cabén transferencias) |
| `a7b8c9d0e1f2` | tabla `budgets` (límite mensual por categoría) |

Aplicar:

```bash
./scripts/migrate.sh
# o: alembic upgrade head
```

Agregar modelo nuevo:

1. Crear `app/models/foo.py` heredando `Base`
2. Importarlo en `app/models/__init__.py`
3. `alembic revision --autogenerate -m "add foo"`
4. Revisar el archivo generado
5. `./scripts/migrate.sh`

---

## 6. Seeds

```bash
python scripts/seed.py
```

Catálogo en `app/services/seed.py` (idempotente), incluye entre otras:

- Alimentación, Transporte, Vivienda, Salud, Ocio, Educación
- Ingresos
- Transferencias → “Entre mis cuentas”

---

## 7. Archivos

```
app/models/user.py
app/models/refresh_token.py
app/models/account.py
app/models/counterparty.py
app/models/category.py
app/models/sub_category.py
app/models/transaction.py
app/models/__init__.py   ← importa todos (Alembic los detecta)
```
