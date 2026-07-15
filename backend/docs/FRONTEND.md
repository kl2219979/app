# Guía frontend (primer día)

Contrato HTTP para integrar la app sin adivinar.  
Complementa [API.md](API.md) y [NEGOCIO.md](NEGOCIO.md).

---

## 1. Arranque local (backend)

```bash
docker compose up db -d
./scripts/migrate.sh
psql "$DATABASE_URL" -f scripts/data/demo_100_users.sql   # opcional pero recomendado
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

- API: `http://localhost:8000`
- Prefijo: `/api/v1`
- OpenAPI/Swagger: `http://localhost:8000/docs` (si `DEBUG=true`)
- Spec cruda: `http://localhost:8000/openapi.json`
- Colección Postman: [`postman/App_Backend_Frontend.postman_collection.json`](postman/App_Backend_Frontend.postman_collection.json)

CORS por defecto: `http://localhost:5173` (Vite). Ajusta `CORS_ORIGINS` en `.env`.

---

## 2. Usuarios demo

| Campo | Valor |
|-------|--------|
| Usuario | `demo001` … `demo100` |
| Correo | `demo001@example.com` … |
| Password | `Password123!` |

Cada demo trae cuentas (a menudo + wallet Efectivo), contrapartes y movimientos 2026.

---

## 3. Auth (mínimo viable)

1. `POST /api/v1/auth/login`  
   Body **form-urlencoded** (OAuth2): `username`, `password`  
2. Guardar `access_token` + `refresh_token`.  
3. Todas las rutas privadas: `Authorization: Bearer <access_token>`.  
4. Si `401`: `POST /api/v1/auth/refresh` con `{ "refresh_token": "..." }` y reemplaza ambos tokens.  
5. `GET /api/v1/auth/me` → perfil.

Si el login responde `mfa_required` (admins): flujo TOTP en [SEGURIDAD.md](SEGURIDAD.md). Los `demo*` son usuarios normales sin MFA.

**Rate limit:** ~10 intentos de login / 60s → `429`. No spamear logins en loops.

---

## 4. Flujo happy path (pantallas)

```
Login → Me
     → GET /categories + /subcategories
     → GET /accounts
     → GET /counterparties
     → GET /budgets + /budgets/status   ← metas del mes
     → GET /reports/summary            ← Home / dashboard
     → GET /transactions?…             ← Feed / extracto
     → GET /transactions/export?format=csv  ← descarga
```

### Dashboard — `GET /reports/summary`

Query opcionales: `date_from`, `date_to`, `account_id`.

Campos útiles para UI:

| Bloque UI | Campos JSON |
|-----------|-------------|
| KPI cards | `total_ingresos`, `total_gastos`, `balance_neto`, `total_transferencias` |
| Donut / barras categorías | `by_category_gastos`, `by_category_ingresos` |
| Detalle fino | `by_subcategory_gastos`, `by_subcategory_ingresos` |
| Efectivo vs cuenta | `by_medio_pago[]` (`medio_pago`, totales, `count`) |
| Top terceros | `by_counterparty[]` (máx. 10) |
| Serie temporal | `by_month[]` |
| Bolsillos | `by_account[]` (`saldo` actual + totales del periodo) |
| “Vs periodo anterior” | `period_comparison` |
| Presupuestos del mes | `budgets_status[]` |

`period_comparison`:

- Si mandas `date_from` + `date_to` → compara ese rango con el de **igual duración** justo antes.
- Si no mandas fechas → mes calendario actual (`día 1` → hoy) vs mes calendario anterior.
- `*_change_pct` puede ser `null` si el periodo anterior fue 0.

Las **transferencias no van dentro de gastos/ingresos**. Muéstralas aparte.

### Feed — `GET /transactions`

Orden **estable**: `fecha DESC`, luego `id DESC` (más reciente primero).

Filtros:

| Query | Ejemplo |
|-------|---------|
| `limit` / `offset` | paginación (`items`, `total`, `limit`, `offset`) |
| `account_id` | una cuenta |
| `category_id` / `sub_category_id` | catálogo |
| `contraparte_id` | “movimientos con X” |
| `medio_pago` | `cuenta` \| `efectivo` |
| `tipo` | `gasto` \| `ingreso` \| `transferencia_*` |
| `date_from` / `date_to` | periodo |

Exportar el mismo set filtrado: `GET /transactions/export?format=csv|json` (máx. 10k filas).

### Presupuestos — `/budgets`

- Crear: `POST /budgets` con `category_id` + `limite` (periodo `mensual`).
- Progreso: `GET /budgets/status` o el bloque `budgets_status` del summary.
- Soft-delete / reactivate como el resto de entidades.

### Crear movimiento

- Cuenta propia: `medio_pago: "cuenta"` + `account_id`.
- Efectivo: `medio_pago: "efectivo"` + `moneda` (**sin** `account_id`).
- `contraparte_id` opcional.
- Gasto/transferencia con monto > saldo → **400** `"Fondos insuficientes..."`.
- No crear cuentas con `tipo: "efectivo"` a mano → **400** (wallet automático).

Transferencias: `POST /transactions/transfers` entre dos cuentas propias (incluye banco↔efectivo).

---

## 5. Errores que el FE debe manejar

| Código | Acción sugerida en UI |
|--------|------------------------|
| 400 | Toast con `detail` (fondos, reglas de negocio) |
| 401 | Refresh; si falla → login |
| 403 | Sin permiso / MFA admin |
| 404 | “No encontrado” (también recursos ajenos) |
| 422 | Validación de formulario (revisar body) |
| 429 | Esperar / backoff (auth) |

`detail` suele ser string; en 422 de Pydantic puede ser lista de errores.

---

## 6. Checklist de integración

- [ ] Login + persistencia de tokens + refresh  
- [ ] Home con `/reports/summary` (KPI + mes + categorías + presupuestos)  
- [ ] Filtro de periodo y de cuenta  
- [ ] Lista de cuentas con saldo (incl. Efectivo)  
- [ ] Feed de transacciones con paginación  
- [ ] Export CSV/JSON  
- [ ] CRUD presupuestos / barra de consumo  
- [ ] Alta gasto cuenta / efectivo / con contraparte  
- [ ] Transferencia entre cuentas  
- [ ] Manejo 400 fondos insuficientes y 401/429  

OpenAPI siempre actualizado vía FastAPI; si hace falta un snapshot:

```bash
curl -s http://localhost:8000/openapi.json -o docs/openapi.snapshot.json
```
