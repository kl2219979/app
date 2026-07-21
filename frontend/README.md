# LuCash — Frontend

Personal finance management SPA. Consumes the backend REST API at **`/api/v1`**.

**Stack:** Vite 5 · JavaScript ES modules (vanilla) · Tailwind CDN · Chart.js · Lucide Icons

---

## Startup

```bash
npm install
npm run dev      # http://localhost:5173  (strictPort)
npm run build    # output in dist/
npm run preview  # preview build
```

Requirement: backend at `http://127.0.0.1:8000` (Docker Compose in `../backend`).

### Development proxy

[`vite.config.js`](vite.config.js) forwards `/api` → `http://127.0.0.1:8000`.  
The client uses the relative base `API_BASE_URL = '/api/v1'`, so there are **no CORS issues** between `localhost` and `127.0.0.1`.

---

## Structure

```
frontend/
├── index.html              # Shell: auth, MFA, sidebar, modals, viewport
├── vite.config.js          # port 5173 + /api proxy
├── package.json
└── src/
    ├── main.js             # State, auth, handlers, data loading
    ├── style.css           # Glass theme / typography
    ├── services/
    │   └── api.js          # HTTP client (JWT, refresh, pages)
    ├── router/
    │   └── router.js       # SPA routes + Catalog gate (admin+MFA)
    └── views/
        ├── DashboardView.js
        ├── TransactionsView.js
        ├── TransfersView.js
        ├── AccountsView.js
        ├── CounterpartiesView.js
        ├── BudgetsView.js
        ├── CatalogView.js      # admin with MFA only
        └── SettingsView.js
```

View pattern: each module exports `{ render(), init(state, utils) }`. The router injects HTML into `#router-viewport` and calls `init`.

---

## Screens

| Route (`switchTab`) | View | Description |
|--------------------|-------|-------------|
| `dashboard` | Panel | KPIs, period comparison, charts, breakdowns from `/reports/summary` |
| `transactions` | Transactions | **Server-side** filters, CSV/JSON export, expense/income CRUD |
| `transfers` | Transfers | `POST /transactions/transfers` (same currency) |
| `accounts` | Accounts | List with balance; create/edit; deactivate/reactivate |
| `counterparties` | Counterparties | CRUD + soft-delete |
| `budgets` | Budgets | Limits + `/budgets/status`; deactivate/reactivate |
| `catalog` | Catalog | Categories/subcategories (write only **admin + MFA**) |
| `settings` | Settings | Profile, TOTP MFA setup, deactivate own account |

---

## Authentication

1. Registration: `POST /auth/register` (JSON).
2. Login: `POST /auth/login` (**form-urlencoded** `username` / `password`).
3. Tokens in `localStorage`: `ff_access_token`, `ff_refresh_token`.
4. If the response returns `mfa_required`, the MFA screen is shown → `POST /auth/mfa/verify`.
5. On `401` with JWT, the client tries `POST /auth/refresh` once and retries.
6. Logout: `POST /auth/logout` + clears tokens.

Demo users from the backend seed: `demo001` / `Password123!` (see [`../backend/docs/FRONTEND.md`](../backend/docs/FRONTEND.md)).

---

## API client (`src/services/api.js`)

Responsibilities:

- `Authorization: Bearer …` headers
- FastAPI errors (`detail` string or validation list)
- `fetchAllPages` for paginated resources (`limit`/`offset`, max 100)
- Methods aligned with the backend contracts (Spanish field names: `monto`, `tipo`, `fecha`, `limite`, …)

### Covered resources

| Domain | Main operations |
|---------|-------------------------|
| Auth | register, login, mfaVerify/setup/confirm, logout, me, refresh |
| Users | get / update / deactivate |
| Accounts | list, create, update, deactivate, reactivate |
| Counterparties | CRUD + reactivate |
| Categories / Subcategories | list + admin write |
| Transactions | list (filters), CRUD, transfers, export |
| Budgets | list, status, create, update, deactivate, reactivate |
| Reports | `getReportSummary({ account_id, date_from, date_to })` |
| Health | `GET /health` (connection indicator) |

---

## Central state (`main.js`)

```js
state = {
  user, transactions, budgets, budgetStatus,
  categories, subcategories, accounts, counterparties,
  report, txFilters, reportFilters, ui, pendingMfaToken
}
```

On login, `Router.init` runs and then `loadAllData()` in parallel (accounts, catalog, transactions, budgets, counterparties, report, `/auth/me`).

**Important contracts (avoid regressions):**

- Payloads use backend names (`monto`, not `amount`; `tipo: gasto|ingreso`).
- `medio_pago=cuenta` → `account_id` (no `tipo=efectivo` wallets in the selector).
- `medio_pago=efectivo` → `moneda` + `account_id: null`.
- HTTP soft-delete = deactivate; the UI offers reactivation where the API allows it.
- **Net balance** on the panel = `total_ingresos − total_gastos` from the summary (excluding transfers).

---

## UI / UX

- Shell in `index.html`: login/registration, MFA challenge, sidebar, global modals.
- Glass styles in `style.css` + Tailwind utilities (CDN).
- Lucide icons; Chart.js charts on the dashboard.
- API indicator (ping to `/health` every 5 s).

---

## Contribution conventions

1. Do not modify the backend from this client: adapt the frontend to `/api/v1`.
2. Keep port **5173** (`strictPort`) or the proxy stops being the expected environment.
3. New screens: view + route in `router.js` + link in the `index.html` sidebar + handlers in `main.js` if needed.
4. Prefer thin screens (`render`/`init`) and keep API/session logic in `api.js` / `main.js`.

---

## Troubleshooting

| Symptom | What to check |
|---------|-------------|
| Login “fails” without 401 in Network | You are outside `:5173` or without the proxy (avoid alternate ports) |
| 401 after login | Token not saved / backend down / auth rate limit (~10/min) |
| Catalog does not appear | User is not `admin` or MFA is not enabled |
| 422 when creating a transaction | Missing subcategory in the catalog or invalid IDs |
| Transfer rejected | Different accounts, same currency, ≥ 2 active accounts |

More HTTP contract detail: [`../backend/docs/API.md`](../backend/docs/API.md) and [`../backend/docs/FRONTEND.md`](../backend/docs/FRONTEND.md).
