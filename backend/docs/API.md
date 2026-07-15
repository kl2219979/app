# API HTTP — catálogo completo

Prefijo: **`/api/v1`**

Autenticación:

| Etiqueta | Significado |
|----------|-------------|
| **público** | Sin Bearer |
| **JWT** | Header `Authorization: Bearer <access_token>` |
| **JWT+admin+MFA** | JWT de usuario con `rol=admin` y `mfa_enabled=true` |

Formato de listados paginados:

```json
{ "items": [ ... ], "total": 42, "limit": 20, "offset": 0 }
```

Base local: `http://localhost:8000`  
Swagger (solo si `DEBUG=true`): `http://localhost:8000/docs`

Reglas de producto: [NEGOCIO.md](NEGOCIO.md).  
Auth detallada: [SEGURIDAD.md](SEGURIDAD.md).

---

## health

### `GET /health`

- **Auth:** público  
- **Qué hace:** comprueba que el proceso responde (no consulta BD).  
- **Respuesta típica:** `{ "status": "ok" }` (ver implementación actual).

---

## auth

### `POST /auth/register`

- **Auth:** público (rate limit)
- **Body JSON:**
  - `nombres`, `apellidos`, `fecha_nacimiento`, `genero`
  - `correo`, `usuario`, `contrasena` (mín. 8)
- **201:** usuario público (sin hash de contraseña)
- **409:** correo o usuario ya existen

### `POST /auth/login`

- **Auth:** público (rate limit)
- **Body:** form OAuth2 (`application/x-www-form-urlencoded`)
  - `username` = correo **o** nombre de usuario
  - `password`
- **200 — usuario normal / admin sin MFA aún:**
  ```json
  {
    "access_token": "...",
    "refresh_token": "...",
    "token_type": "bearer",
    "mfa_required": false,
    "mfa_token": null
  }
  ```
- **200 — admin con MFA activo:**
  ```json
  {
    "access_token": null,
    "refresh_token": null,
    "token_type": "bearer",
    "mfa_required": true,
    "mfa_token": "<challenge JWT corto>"
  }
  ```
- **401:** credenciales inválidas (se registra en log **sin** password)
- **403:** usuario desactivado

### `POST /auth/mfa/verify`

- **Auth:** público (rate limit); usa el `mfa_token` del login
- **Body:** `{ "mfa_token": "...", "code": "123456" }`
- **200:** `access_token` + `refresh_token`

### `POST /auth/mfa/setup`

- **Auth:** JWT
- **Qué hace:** genera secreto TOTP (aún no activa MFA)
- **200:** `{ "secret", "otpauth_uri", "mfa_enabled": false }`
- Escanea `otpauth_uri` con Google Authenticator / Authy / etc.

### `POST /auth/mfa/confirm`

- **Auth:** JWT
- **Body:** `{ "code": "123456" }`
- **200:** usuario con `mfa_enabled: true`

### `POST /auth/refresh`

- **Auth:** público (rate limit)
- **Body:** `{ "refresh_token": "..." }`
- **200:** nuevo par access+refresh (el anterior queda **revocado**)
- **403:** admin sin MFA no puede refrescar

### `POST /auth/logout`

- **Auth:** JWT
- **Body opcional:** `{ "refresh_token": "..." }`
  - Con token: revoca ese refresh **solo si es del usuario autenticado**
  - Sin token: revoca **todos** los refresh del usuario
- **204**

### `GET /auth/me`

- **Auth:** JWT
- **200:** perfil (`id`, nombres, correo, usuario, `rol`, `activo`, `mfa_enabled`, …)

---

## users

### `GET /users/{user_id}`

- **Auth:** JWT  
- Solo el propio `user_id` (si no → 403).

### `PUT /users/{user_id}`

- **Auth:** JWT (self)  
- Body parcial: nombres, apellidos, fecha_nacimiento, genero, correo, usuario, contrasena.

### `DELETE /users/{user_id}`

- **Auth:** JWT (self)  
- Soft-delete: `activo=false` + revoca refresh. **No borra** cuentas ni movimientos.  
- **204**

---

## accounts

### `GET /accounts`

- **Auth:** JWT  
- Query: `limit`, `offset`, `include_inactive` (bool, default false)

### `GET /accounts/{account_id}`

- **Auth:** JWT (propia; incluye inactivas si conoces el id)

### `POST /accounts`

- **Auth:** JWT  
- Body:
  - `banco`, `tipo`, `moneda`
  - `saldo_inicial` (Decimal ≥ 0) ← **solo aquí**
- Respuesta incluye `saldo` (igual al inicial) y `activo: true`

### `PUT /accounts/{account_id}`

- **Auth:** JWT  
- Body permitido: `banco`, `tipo`, `moneda`  
- Enviar `saldo` → **422** (`extra=forbid`)  
- Cuenta inactiva → 400

### `DELETE /accounts/{account_id}`

- Soft-delete `activo=false`. Historial intacto. Saldo **no** se altera.  
- **204**

### `POST /accounts/{account_id}/reactivate`

- Vuelve `activo=true`.  
- **200** con la cuenta

---

## counterparties

Agenda de terceros fuera del sistema (JWT, ownership propio).

### `GET /counterparties`

Query: `limit`, `offset`, `include_inactive`

### `GET /counterparties/{counterparty_id}`

### `POST /counterparties`

Body: `nombre` (requerido), `banco`, `numero_cuenta`, `notas` (opcionales)

### `PUT /counterparties/{counterparty_id}`

Inactiva → 400 (reactivar primero).

### `DELETE /counterparties/{counterparty_id}`

Soft-delete. **204**

### `POST /counterparties/{counterparty_id}/reactivate`

---

## categories

Lectura: cualquier JWT. Escritura: **JWT+admin+MFA**.

### `GET /categories`

Query: `limit`, `offset`, `include_inactive`

### `GET /categories/{category_id}`

### `POST /categories`

Body: `nombre`, `descripcion`  
**409** si el nombre ya existe

### `PUT /categories/{category_id}`

### `DELETE /categories/{category_id}`

Desactiva categoría **y** subcategorías hijas. Historial de txs se conserva.  
**204**

---

## subcategories

### `GET /subcategories`

Query: `category_id` (opcional), `limit`, `offset`, `include_inactive`

### `GET /subcategories/{subcategory_id}`

### `POST /subcategories` — admin+MFA

Body: `category_id`, `nombre`, `descripcion`  
La categoría debe existir y estar activa.

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
- Solo movimientos **activos** del usuario  
- **Orden estable:** `fecha DESC`, `id DESC` (más recientes primero)
- Página: `{ items, total, limit, offset }`

### `GET /transactions/export`

- **Auth:** JWT  
- Query: mismos filtros que el listado + `format=csv|json` (default `csv`)  
- Descarga hasta **10_000** movimientos activos  
- CSV: `Content-Disposition` attachment; JSON: lista de objetos

### `POST /transactions`

Body (pago con cuenta propia):

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

Body (pago en efectivo — sin `account_id`):

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

Reglas:

- `tipo` solo `gasto` \| `ingreso` en create.
- `medio_pago` default `cuenta`. Con `cuenta` → `account_id` obligatorio. Con `efectivo` → `moneda` obligatoria y **no** enviar `account_id` (422).
- `contraparte_id` opcional; debe ser propia y activa (404 si no).
- Efectivo resuelve/crea wallet `tipo=efectivo` y actualiza su saldo.
- Gasto (y transferencias) con monto > saldo → **400** fondos insuficientes.
- Respuesta incluye `medio_pago`, `contraparte_id`, `account_id` (siempre el id contable).

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

Respuesta: `{ "grupo_transferencia", "salida", "entrada" }`  
Misma moneda obligatoria. Sirve también para banco↔wallet efectivo (el wallet aparece en `GET /accounts`).
Sin `contraparte_id`.

### `GET /transactions/{transaction_id}`

### `PUT /transactions/{transaction_id}`

Solo movimientos operativos (`gasto`/`ingreso`) **sin** `grupo_transferencia`.  
Puede cambiar `medio_pago` / `account_id` / `moneda` / `contraparte_id` con las mismas reglas de create.  
Recalcula saldos (revierte viejo, aplica nuevo).

### `DELETE /transactions/{transaction_id}`

Soft-delete + **revierte saldo**.  
Si es transferencia, desactiva ambas piernas.  
**204**

---

## budgets

Presupuesto mensual por categoría (`(user_id, category_id)` único).

### `GET /budgets`

- **Auth:** JWT — página `{ items, total, limit, offset }` (activos)

### `GET /budgets/status`

- **Auth:** JWT  
- Lista de presupuestos activos con `gastado`, `restante`, `pct_usado`, `excedido` (mes calendario actual)

### `GET /budgets/{budget_id}` / `GET /budgets/{budget_id}/status`

### `POST /budgets`

Body: `{ "category_id": 2, "limite": "500000.00", "moneda": "COP", "periodo": "mensual" }`  
Si ya existía uno inactivo para esa categoría, lo reactiva y actualiza el límite.

### `PUT /budgets/{budget_id}`

### `DELETE /budgets/{budget_id}`

Soft-delete → **204**

### `POST /budgets/{budget_id}/reactivate`

---

## reports

### `GET /reports/summary`

- **Auth:** JWT  
- Query: `account_id`, `date_from`, `date_to`

Respuesta (campos):

| Campo | Significado |
|-------|-------------|
| `total_ingresos` | Suma de `tipo=ingreso` activos |
| `total_gastos` | Suma de `tipo=gasto` activos |
| `balance_neto` | ingresos − gastos |
| `total_transferencias` | Suma de `transferencia_salida` |
| `by_category_gastos` / `by_category_ingresos` | Breakdown por categoría |
| `by_subcategory_gastos` / `by_subcategory_ingresos` | Breakdown por subcategoría |
| `by_medio_pago` | Totales `cuenta` vs `efectivo` |
| `by_counterparty` | Top 10 terceros (gastos+ingresos con `contraparte_id`) |
| `by_month` | Totales por año/mes |
| `by_account` | Saldo actual + totales por cuenta |
| `budgets_status` | Presupuestos activos vs gasto del mes calendario |
| `period_comparison` | Periodo actual vs anterior (mismas longitudes o mes calendario) |
| `date_from`, `date_to`, `account_id` | Eco de filtros |

`period_comparison`: con ambos filtros de fecha → ventana previa de igual duración; sin fechas → mes actual (día 1→hoy) vs mes calendario anterior. `*_change_pct` es `null` si el anterior fue 0.

Guía FE: [FRONTEND.md](FRONTEND.md).

---

## webhooks

### `POST /webhooks/inbound`

- **Auth:** firma HMAC (no JWT)
- **Header obligatorio:** `X-Webhook-Signature: t=<unix>,v1=<hex>`
- **Body JSON:** `{ "event": "nombre", "data": { ... } }`
- **Qué hace:** valida firma + schema; **no** hace HTTP saliente a URLs del payload (anti-SSRF)
- **202:** `{ "received": true, "event": "..." }`
- Rate limit propio (más holgado que auth)

Cómo se firma (mismo algoritmo que el servidor):

1. `signed = f"{timestamp}.".encode() + raw_body`
2. `v1 = HMAC_SHA256(WEBHOOK_SECRET, signed).hexdigest()`
3. Header = `t={timestamp},v1={v1}`
4. Ventana máxima: 300 segundos

Utilidad Python: `app.core.webhooks.sign_payload` / `verify_signature`.

---

## Errores HTTP frecuentes

| Código | Cuándo |
|--------|--------|
| 400 | Regla de negocio (fondos insuficientes, cuenta inactiva, monedas distintas, editar transferencia, crear `tipo=efectivo`…) |
| 401 | Sin token / token inválido / login fallido / firma webhook mala |
| 403 | No eres el dueño / no eres admin / admin sin MFA / HTTPS requerido en prod |
| 404 | Recurso inexistente o no tuyo (a menudo indistinguible a propósito) |
| 409 | Conflicto (correo duplicado, nombre de categoría) |
| 422 | Validación Pydantic (campos inválidos / `saldo` en PUT cuenta) |
| 429 | Rate limit (auth / webhooks) — ver `docs/TESTING.md` si pruebas en masa |
| 503 | Webhook sin `WEBHOOK_SECRET` configurado |

---

## Mini flujo feliz (frontend)

1. `POST /auth/register`  
2. `POST /auth/login` → guardar tokens  
3. `POST /accounts` con `saldo_inicial`  
4. `GET /categories` + `GET /subcategories?category_id=`  
5. `POST /transactions` (gasto/ingreso)  
6. `GET /reports/summary`  
7. Cuando expire el access: `POST /auth/refresh`  
8. Al cerrar sesión: `POST /auth/logout`
