# Reglas de negocio (producto financiero)

Este documento explica **cómo se comporta la app para el usuario final**.
No es código: es el “contrato” mental que deben respetar backend, frontend y QA.

Si algo en el código contradice esto, el bug es del código (no de la doc).

---

## 1. Qué problema resuelve la app

Es un **tracker de finanzas personales**:

- Un usuario tiene **cuentas** (banco, billetera, etc.) con dinero (`saldo`).
- Registra **movimientos**: gastos e ingresos.
- Puede **transferir** dinero entre sus propias cuentas.
- Consulta **reportes** para un dashboard (totales, por categoría, por mes, por cuenta).
- Existe un **catálogo global** de categorías/subcategorías (mantenido por admin).

---

## 2. Principio rector: el dinero no se inventa

### 2.1 El saldo de una cuenta

| Momento | Qué pasa con `saldo` |
|---------|----------------------|
| Crear cuenta | Se acepta `saldo_inicial` (apertura / dinero que ya tenía). |
| PUT cuenta | **Prohibido** cambiar el saldo. Solo `banco`, `tipo`, `moneda`. |
| Crear gasto | Resta `monto` del saldo (**requiere fondos suficientes**). |
| Crear ingreso | Suma `monto` al saldo. |
| Transferencia | Resta en origen (**fondos suficientes**), suma en destino. |
| Editar movimiento | Se revierte el efecto viejo y se aplica el nuevo (mismo check de fondos). |
| Desactivar movimiento | Se revierte el efecto; el historial permanece. |

**Nunca** el frontend debe “setear” un saldo arbitrario después de crear la cuenta.
Si el saldo no cuadra, el origen del error está en los movimientos (o en un bug).

Gasto/transferencia con `monto` mayor al saldo → **400** `"Fondos insuficientes en la cuenta"`.
No se permiten sobregiros.

### 2.2 Tipos de movimiento

| `tipo` | Efecto en saldo | ¿Cuenta en reportes de “gastos/ingresos”? |
|--------|-----------------|-------------------------------------------|
| `gasto` | Resta | Sí → `total_gastos` |
| `ingreso` | Suma | Sí → `total_ingresos` |
| `transferencia_salida` | Resta | No (va a `total_transferencias`) |
| `transferencia_entrada` | Suma | No |

Las transferencias **no deben inflar** el gasto del mes: mover $100 de Nequi a Bancolombia no es un gasto de $100.

---

## 3. Soft-delete (desactivar, no borrar)

### 3.1 Por qué

Los usuarios **conviven** con la app años. Borrar en cascada:

- destruye el historial contable,
- hace imposibles auditorías,
- puede dejar saldos inconsistentes si se hace mal.

Por eso casi todo DELETE HTTP significa: `activo = false`.

### 3.2 Comportamiento por entidad

| Entidad | DELETE hace | Historial | Saldo |
|---------|-------------|-----------|-------|
| Usuario | `activo=false` + revoca refresh | Cuentas/txs se conservan | Intactos |
| Cuenta | `activo=false` | Movimientos se conservan | **No se toca** |
| Contraparte | `activo=false` | Txs antiguas conservan el FK | — |
| Categoría | `activo=false` + desactiva subcategorías hijas | Txs antiguas se conservan | — |
| Subcategoría | `activo=false` | Idem | — |
| Transacción | `activo=false` | Fila permanece | **Se revierte** el impacto |
| Transferencia (una pierna) | Desactiva **ambas** piernas del `grupo_transferencia` | Idem | Revierte origen y destino |

### 3.3 Listados

Por defecto los listados muestran solo `activo=true`.

- Cuentas / categorías / subcategorías: query `include_inactive=true` para ver desactivados.
- Cuentas: `POST /accounts/{id}/reactivate` para volver a usarlas.
- Transacciones inactivas: no aparecen en listado ni en reportes; `GET` por id responde 404 “no encontrada o inactiva”.

### 3.4 Qué NO hacemos

- No hay `CASCADE` que borre transacciones al borrar una cuenta.
- No se borra físicamente el ledger por un DELETE de categoría.
- No se permite crear movimientos nuevos sobre cuentas/categorías inactivas.

---

## 4. Ownership (cada usuario ve lo suyo)

| Recurso | Regla |
|---------|-------|
| Accounts | Solo las del `user_id` del JWT |
| Counterparties | Solo las del `user_id` del JWT |
| Transactions | Solo las de cuentas propias |
| Reports | Solo agrega datos del usuario autenticado |
| Users `/{id}` | Solo el propio `id` |
| Categories / Subcategories | Catálogo **global** (lectura cualquier JWT; escritura admin+MFA) |

Intentar operar la cuenta/contraparte de otro → 404 (no revelamos existencia).

---

## 4.1 Contrapartes (terceros fuera del sistema)

Agenda personal de destinatarios/origenes que **no** son cuentas propias:

- Campos: `nombre` (obligatorio), `banco`, `numero_cuenta`, `notas` (opcionales).
- Un gasto/ingreso puede llevar `contraparte_id` para documentar a quién se pagó / de quién se recibió.
- No mueve saldo de nadie más: el dinero entra/sale de **tu** cuenta o wallet de efectivo.
- Soft-delete: no se pueden usar contrapartes inactivas en txs nuevas; el historial conserva el FK.

---

## 4.2 Medio de pago (`cuenta` | `efectivo`)

| `medio_pago` | Qué envía el client | Qué hace el backend |
|--------------|---------------------|---------------------|
| `cuenta` | `account_id` obligatorio | Usa esa cuenta propia activa |
| `efectivo` | `moneda` obligatoria; **sin** `account_id` | Resuelve/crea wallet `tipo=efectivo`, `banco=Efectivo` por usuario+moneda |

El wallet aparece en `GET /accounts` y cuenta para saldos/reportes. **No** se crea con `POST /accounts` (`tipo=efectivo` → 400): solo vía `medio_pago=efectivo` o transferencias hacia el wallet.

Banco↔efectivo se hace con `POST /transactions/transfers` hacia/desde ese wallet.

---

## 5. Transferencias

Requisitos:

1. Ambas cuentas del mismo usuario.
2. Ambas **activas**.
3. Misma `moneda`.
4. Origen ≠ destino.
5. Categoría/subcategoría activas y coherentes (la sub pertenece a la categoría).

Resultado: dos filas enlazadas por `grupo_transferencia` (UUID).

No se edita una pierna por PUT (hay que desactivar el grupo y crear otra transferencia).

---

## 6. Catálogo (categorías)

- Lo mantiene un **admin** con MFA activo.
- Usuarios normales solo leen el catálogo.
- Seed inicial: `python scripts/seed.py` (incluye “Transferencias”, “Ingresos”, etc.).
- Idempotente: se puede correr varias veces.

Promover admin:

```bash
python scripts/promote_admin.py <usuario_o_correo>
# Luego: POST /auth/mfa/setup → app Authenticator → POST /auth/mfa/confirm
```

Sin MFA confirmado, el admin **no puede** mutar el catálogo (403).

---

## 7. Reportes (dashboard)

`GET /reports/summary` (solo movimientos activos):

- `total_ingresos` / `total_gastos` / `balance_neto` (ingresos − gastos)
- `total_transferencias` (suma de salidas)
- `by_category_gastos` / `by_category_ingresos`
- `by_subcategory_gastos` / `by_subcategory_ingresos`
- `by_medio_pago` (cuenta vs efectivo)
- `by_counterparty` (top 10 terceros)
- `by_month` (buckets año-mes)
- `by_account` (saldo actual + totales operativos por cuenta)
- `period_comparison` (periodo actual vs anterior)

Filtros opcionales: `account_id`, `date_from`, `date_to`.

---

## 8. Paginación

Todos los listados principales responden:

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

## 9. Checklist mental para el frontend

1. Tras login, guardar `access_token` y `refresh_token`.
2. Si `mfa_required`, ir a pantalla TOTP → `/auth/mfa/verify`.
3. Crear cuenta con `saldo_inicial`, nunca editar `saldo` después.
4. Gastos/ingresos con `tipo` y `medio_pago` correctos; efectivo usa `moneda` (sin `account_id`).
5. Terceros externos: CRUD `/counterparties` + `contraparte_id` opcional en el movimiento.
6. Transferencias por `/transactions/transfers` (incluye banco↔wallet efectivo).
7. DELETE = “archivar”; ofrecer reactivar cuentas/contrapartes si aplica.
8. Dashboard: usar `/reports/summary`, no recalcular a ciegas sumando transferencias como gastos.
9. Escritura de categorías: solo si el usuario es admin **con MFA**.

Más detalle HTTP: [API.md](API.md).  
Más detalle de tablas: [MODELOS.md](MODELOS.md).
