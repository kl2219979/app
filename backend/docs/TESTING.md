# Backend testing guide

Reference for how (and why) we test.
Complements the AAA pattern with the **test pyramid**.

General index: [INDEX.md](INDEX.md).

---

## 1. Team principle (pyramid)

```
    ┌─────────────────────────────┐
    │  E2E (few)                  │  Live stack: real API + Postgres
    ├─────────────────────────────┤
    │  Integration (some)         │  HTTP TestClient or optional Postgres
    ├─────────────────────────────┤
    │  Unit (many)                │  Services, repositories, security
    └─────────────────────────────┘
```

Rules:

- Most of the coverage lives in **unit tests**.
- `tests/api` are HTTP contract **smoke** tests, they don't rewrite all the logic.
- E2E are **off** by default (`RUN_E2E=1` to enable them).

Why: unit tests are fast and stable; too many E2E make CI fragile.

---

## 2. AAA pattern (Arrange – Act – Assert)

1. **Arrange** — data, fixtures, payloads  
2. **Act** — one action (service, repo, or a request)  
3. **Assert** — status, values, exceptions  

Example:

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

## 3. Folder map

```
tests/
├── conftest.py              Fixtures (db_session, client, auth, admin+MFA)
├── helpers.py               make_* factories
├── core/                    UNIT — security
├── services/                UNIT — business (+ MFA, transfer, reports, seed)
├── repositories/            UNIT — queries / ownership
├── api/                     INTEGRATION — TestClient + SQLite
├── integration/             INTEGRATION — Postgres opt-in
└── e2e/                     E2E — live server opt-in
```

Markers (`pyproject.toml`): `unit` | `integration` | `postgres` | `e2e`.

Each module declares `pytestmark = pytest.mark.<layer>`.
The Postgres smoke tests also carry `pytest.mark.postgres` (`RUN_INTEGRATION=1`).

---

## 4. Important fixtures

| Fixture | What it does |
|---------|----------|
| `db_session` | In-memory SQLite; tables create/drop per test |
| `client` | `TestClient` with `get_db` → `db_session` |
| `registered_user` | User via `POST /auth/register` |
| `auth_headers` | Bearer after login |
| `admin_headers` | Same user promoted to **admin with active MFA** (catalog requirement) |
| `_reset_rate_limiter` | Autouse: clears the in-memory rate limit between tests |

Factories in `tests/helpers.py`: `make_user`, `make_account`, `make_category`, `make_sub_category`, `make_transaction`.

Rules:

- Service unit tests do **not** depend on endpoints.
- API smokes do **not** duplicate all the service branches.

---

## 5. What to test in each layer

**UNIT — services (priority #1)**

- Ownership  
- Category/subcategory consistency  
- Balance (create/update/deactivate/transfer)  
- Soft-delete  
- MFA challenge / admin without MFA blocked  
- Reports (expenses vs transfers)

**UNIT — repositories**

- `user_id`, `only_active` filters, Transaction↔Account joins  

**UNIT — core**

- bcrypt, JWT, (optional) webhook signature  

**INTEGRATION — api/**

- Contract status codes  
- 401 without Bearer  
- Short happy-path per resource  

**INTEGRATION — integration/** (opt-in)

- Real Postgres + `alembic_version`  

**E2E** (opt-in)

- One critical path: health → register → login → account → catalog → tx → report  

---

## 6. How to run

Daily suite (CI-like):

```bash
source .venv/bin/activate
pytest -q -m "not e2e"
# with coverage (like CI):
pytest -q -m "not e2e" --cov=app --cov-fail-under=70
```

Unit only:

```bash
pytest -m unit -q
```

Real Postgres:

```bash
docker compose up db -d
./scripts/migrate.sh
RUN_INTEGRATION=1 \
  TEST_DATABASE_URL="postgresql+psycopg2://postgres:postgres@localhost:5432/app_db" \
  pytest -m postgres -q tests/integration
```

E2E (API already up):

```bash
RUN_E2E=1 E2E_BASE_URL=http://localhost:8000 pytest -m e2e -q
```

Lint:

```bash
ruff check app tests
```

Dependency audit:

```bash
pip-audit -r requirements.txt -r requirements-dev.txt
```

---

## 7. Policy when adding code

1. **Service** unit tests for the new rule.  
2. If the SQL is not trivial → **repository** unit test.  
3. At most **one smoke** in `tests/api` if the HTTP contract is new.  
4. Don't open new E2E unless it's a critical path agreed with QA.  
5. Update the inventory below and [API.md](API.md) / [BUSINESS.md](BUSINESS.md) if behavior changes.

PR checklist:

- [ ] `pytest -q -m "not e2e"` green  
- [ ] New rules in `tests/services`  
- [ ] No real secrets in fixtures  
- [ ] Correct markers  
- [ ] Docs aligned if the contract changed  

---

## 8. What NOT to do

- Don't use a production DB.  
- Don't depend on the order between files.  
- Don't triplicate the same assert in service + API + E2E.  
- Don't disable markers to “make CI pass”.  
- Don't forget to clear the rate limit if you add bulk auth tests (there's already an autouse).  

---

## 9. Current inventory

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
- `tests/services/test_security_controls.py` (MFA, webhooks, admin without MFA)
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
- `tests/integration/test_postgres_smoke.py` (opt-in; includes `tipo` ≥ 21 check)

**E2E**

- `tests/e2e/test_critical_path.py` (opt-in)

**CI** (`.github/workflows/ci.yml`)

1. Ruff  
2. pip-audit  
3. Pytest `-m "not e2e"` with coverage ≥ 70%  

### Rate limit when testing auth in bulk

`RATE_LIMIT_AUTH_MAX` (default 10) / `RATE_LIMIT_AUTH_WINDOW_SECONDS` (60).
Bursts of `/auth/login` → **429**. In manual probes: space out requests or wait for the window.

### Demo dataset 100 users (Postgres)

```bash
docker compose up db -d
./scripts/migrate.sh
psql "$DATABASE_URL" -f scripts/data/demo_100_users.sql
# regenerate: python scripts/generate_demo_100_users_sql.py
```

Login: `demo001`…`demo100` / `Password123!`  
The seed is idempotent for `demo%@example.com` emails and keeps balances ≥ 0.

Update this inventory when you add relevant modules.
