# Guía de testing del backend

Referencia de cómo (y por qué) testamos.
Complementa el patrón AAA con la **pirámide de tests**.

Índice general: [INDICE.md](INDICE.md).

---

## 1. Principio del equipo (pirámide)

```
    ┌─────────────────────────────┐
    │  E2E (pocos)                │  Stack vivo: API + Postgres reales
    ├─────────────────────────────┤
    │  Integration (algunos)      │  TestClient HTTP o Postgres opcional
    ├─────────────────────────────┤
    │  Unit (muchos)              │  Services, repositories, security
    └─────────────────────────────┘
```

Reglas:

- La mayor parte de la cobertura vive en **unitarios**.
- `tests/api` son **smoke** del contrato HTTP, no reescriben toda la lógica.
- Los E2E están **apagados** por defecto (`RUN_E2E=1` para activarlos).

Por qué: unitarios rápidos y estables; demasiados E2E vuelven el CI frágil.

---

## 2. Patrón AAA (Arrange – Act – Assert)

1. **Arrange** — datos, fixtures, payloads  
2. **Act** — una acción (service, repo o un request)  
3. **Assert** — status, valores, excepciones  

Ejemplo:

```python
def test_create_rejects_foreign_account(db_session):
    # Arrange
    owner = make_user(db_session, correo="a@x.com", usuario="owner")
    ...
    # Act / Assert
    with pytest.raises(HTTPException) as exc:
        TransactionService.create(db_session, owner, data)
    assert exc.value.status_code == 404
```

---

## 3. Mapa de carpetas

```
tests/
├── conftest.py              Fixtures (db_session, client, auth, admin+MFA)
├── helpers.py               Factories make_*
├── core/                    UNIT — security
├── services/                UNIT — negocio (+ MFA, transfer, reports, seed)
├── repositories/            UNIT — queries / ownership
├── api/                     INTEGRATION — TestClient + SQLite
├── integration/             INTEGRATION — Postgres opt-in
└── e2e/                     E2E — servidor vivo opt-in
```

Markers (`pyproject.toml`): `unit` | `integration` | `postgres` | `e2e`.

Cada módulo declara `pytestmark = pytest.mark.<capa>`.
Los smoke de Postgres llevan también `pytest.mark.postgres` (`RUN_INTEGRATION=1`).

---

## 4. Fixtures importantes

| Fixture | Qué hace |
|---------|----------|
| `db_session` | SQLite en memoria; tablas create/drop por test |
| `client` | `TestClient` con `get_db` → `db_session` |
| `registered_user` | Usuario vía `POST /auth/register` |
| `auth_headers` | Bearer tras login |
| `admin_headers` | Mismo user promovido a **admin con MFA activo** (requisito de catálogo) |
| `_reset_rate_limiter` | Autouse: limpia el rate limit in-memory entre tests |

Factories en `tests/helpers.py`: `make_user`, `make_account`, `make_category`, `make_sub_category`, `make_transaction`.

Reglas:

- Unitarios de service **no** dependen de endpoints.
- Smokes de API **no** duplican todas las ramas del service.

---

## 5. Qué testear en cada capa

**UNIT — services (prioridad #1)**

- Ownership  
- Coherencia categoría/subcategoría  
- Saldo (create/update/deactivate/transfer)  
- Soft-delete  
- MFA challenge / admin sin MFA bloqueado  
- Reportes (gastos vs transferencias)

**UNIT — repositories**

- Filtros `user_id`, `only_active`, joins Transaction↔Account  

**UNIT — core**

- bcrypt, JWT, (opcional) firma webhook  

**INTEGRATION — api/**

- Status codes del contrato  
- 401 sin Bearer  
- Happy-path corto por recurso  

**INTEGRATION — integration/** (opt-in)

- Postgres real + `alembic_version`  

**E2E** (opt-in)

- Un camino crítico: health → register → login → account → catálogo → tx → report  

---

## 6. Cómo ejecutar

Suite diaria (CI-like):

```bash
source .venv/bin/activate
pytest -q -m "not e2e"
# con coverage (como CI):
pytest -q -m "not e2e" --cov=app --cov-fail-under=70
```

Solo unitarios:

```bash
pytest -m unit -q
```

Postgres real:

```bash
docker compose up db -d
./scripts/migrate.sh
RUN_INTEGRATION=1 \
  TEST_DATABASE_URL="postgresql+psycopg2://postgres:postgres@localhost:5432/app_db" \
  pytest -m postgres -q tests/integration
```

E2E (API ya arriba):

```bash
RUN_E2E=1 E2E_BASE_URL=http://localhost:8000 pytest -m e2e -q
```

Lint:

```bash
ruff check app tests
```

Auditoría de deps:

```bash
pip-audit -r requirements.txt -r requirements-dev.txt
```

---

## 7. Política al agregar código

1. Unitarios del **service** para la regla nueva.  
2. Si el SQL no es trivial → unitario de **repository**.  
3. Como máximo **un smoke** en `tests/api` si el contrato HTTP es nuevo.  
4. No abras E2E nuevos salvo camino crítico acordado con QA.  
5. Actualiza el inventario de abajo y [API.md](API.md) / [NEGOCIO.md](NEGOCIO.md) si cambia comportamiento.

Checklist PR:

- [ ] `pytest -q -m "not e2e"` en verde  
- [ ] Nuevas reglas en `tests/services`  
- [ ] Sin secretos reales en fixtures  
- [ ] Markers correctos  
- [ ] Docs alineadas si cambió el contrato  

---

## 8. Qué NO hacer

- No uses BD de producción.  
- No dependas del orden entre archivos.  
- No tripliques el mismo assert en service + API + E2E.  
- No desactives markers para “hacer pasar” el CI.  
- No olvides limpiar rate limit si agregas tests de auth masivos (ya hay autouse).  

---

## 9. Inventario actual

**Unit**

- `tests/core/test_security.py`
- `tests/services/test_account_service.py`
- `tests/services/test_category_service.py`
- `tests/services/test_sub_category_service.py`
- `tests/services/test_transaction_service.py`
- `tests/services/test_transfer_service.py`
- `tests/services/test_user_service.py`
- `tests/services/test_report_service.py`
- `tests/services/test_seed_catalog.py`
- `tests/services/test_security_controls.py` (MFA, webhooks, admin sin MFA)
- `tests/services/test_counterparty_service.py`
- `tests/services/test_medio_pago_service.py`
- `tests/services/test_schema_constraints.py` (`transactions.tipo` length)
- `tests/repositories/test_*_repository.py`

**Integration**

- `tests/api/test_health.py`
- `tests/api/test_auth.py`
- `tests/api/test_accounts.py`
- `tests/api/test_categories.py`
- `tests/api/test_transactions.py`
- `tests/api/test_counterparties.py`
- `tests/api/test_medio_pago.py`
- `tests/integration/test_postgres_smoke.py` (opt-in; incluye check `tipo` ≥ 21)

**E2E**

- `tests/e2e/test_critical_path.py` (opt-in)

**CI** (`.github/workflows/ci.yml`)

1. Ruff  
2. pip-audit  
3. Pytest `-m "not e2e"` con coverage ≥ 70%  

### Rate limit al testear auth en masa

`RATE_LIMIT_AUTH_MAX` (default 10) / `RATE_LIMIT_AUTH_WINDOW_SECONDS` (60).
Ráfagas de `/auth/login` → **429**. En probes manuales: espaciar requests o esperar la ventana.

### Dataset demo 100 usuarios (Postgres)

```bash
docker compose up db -d
./scripts/migrate.sh
psql "$DATABASE_URL" -f scripts/data/demo_100_users.sql
# regenerar: python scripts/generate_demo_100_users_sql.py
```

Login: `demo001`…`demo100` / `Password123!`  
El seed es idempotente para correos `demo%@example.com` y mantiene saldos ≥ 0.

Actualiza este inventario cuando agregues módulos relevantes.
