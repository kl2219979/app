# Security (full guide)

This backend is designed to meet an **OWASP Top 10**-style checklist.
Key code:

| Piece | Path |
|-------|------|
| Config / prod guards | `app/core/config.py` |
| Passwords + JWT | `app/core/security.py` |
| MFA TOTP | `app/core/mfa.py` |
| Rate limit | `app/core/rate_limit.py` |
| HMAC webhooks | `app/core/webhooks.py` |
| Logging | `app/core/logging_config.py` |
| Headers / HTTPS | `app/main.py` |
| JWT/admin dependencies | `app/api/deps.py` |
| Auth service | `app/services/auth.py` |

---

## 1. Broken Access Control

- Almost all resources require JWT (`get_current_user`).
- Ownership in services: accounts, txs, reports, and profile only for the owner.
- Catalog mutations: `get_current_admin` → requires `rol=admin` **and** `mfa_enabled`.
- Logout: you can only revoke **your own** refresh tokens (not another user's).
- Public on purpose: `/health`, register/login/refresh/mfa-verify, signed webhooks.

---

## 2. Cryptographic Failures

| Data | Protection |
|------|------------|
| Password | bcrypt (`hash_password` / `verify_password`) |
| Access token | JWT HS256 signed with `SECRET_KEY`, `exp` claim |
| Refresh token | Opaque; only SHA-256 in the DB |
| TOTP secret | Fernet encryption derived from `SECRET_KEY` |
| Webhooks | HMAC-SHA256 |

### HTTPS in production

The API does **not** terminate TLS itself (it does not embed certificates).

In production you must:

1. Put a reverse proxy (Nginx, Caddy, Traefik, ALB…) with HTTPS.
2. `FORCE_HTTPS=true` and `APP_ENV=production`.
3. The proxy sends `X-Forwarded-Proto: https`.
4. If HTTP arrives, the API responds **400** “HTTPS required”.
5. An **HSTS** header is added.

---

## 3. Injection

- Input validated with **Pydantic** (`app/schemas/`).
- Persistence with **SQLAlchemy ORM** (bound parameters).
- There is no raw SQL built with user input in the API path.

---

## 4. Insecure Design

- Per-IP rate limiting on `/auth/*` and `/webhooks/*` (in-memory sliding window).
- Length/format validations in schemas.
- Least privilege: user vs admin+MFA.
- Soft-delete so financial history is never destroyed.

Variables:

- `RATE_LIMIT_AUTH_MAX` (default 10)
- `RATE_LIMIT_AUTH_WINDOW_SECONDS` (default 60)

Note: the in-memory limiter is per process. Across multiple replicas, use a shared store (Redis) in the future; today it works for a single node / development.

---

## 5. Security Misconfiguration

With `APP_ENV=production`, `Settings` **forces**:

| Rule | Detail |
|-------|---------|
| `DEBUG=False` | Even if the `.env` says `true` |
| `SECRET_KEY` | ≥ 32 chars, no `change-me…` placeholders |
| `WEBHOOK_SECRET` | Required, ≥ 32 chars |
| `FORCE_HTTPS=true` | Required |
| CORS | `*` is not allowed in origins |

Strict CORS:

- Origins from `CORS_ORIGINS` (list)
- Methods from `CORS_ALLOW_METHODS`
- Headers from `CORS_ALLOW_HEADERS`

Swagger/ReDoc only if `DEBUG=true`.

Security headers on all responses:

- `X-Content-Type-Options: nosniff`
- `X-Frame-Options: DENY`
- `Referrer-Policy: no-referrer`
- `Permissions-Policy: …`
- `Strict-Transport-Security` if prod / FORCE_HTTPS

---

## 6. Vulnerable Components

- CI: `pip-audit -r requirements.txt -r requirements-dev.txt`
- Dependabot: `.github/dependabot.yml` (pip + GitHub Actions, weekly)

Update deps when Dependabot opens PRs; don't ignore audits in red.

---

## 7. Auth Failures (JWT + MFA)

### Tokens

| Token | Typical lifetime | Use |
|-------|-------------|-----|
| Access JWT | `ACCESS_TOKEN_EXPIRE_MINUTES` (30) | Bearer header |
| Opaque refresh | `REFRESH_TOKEN_EXPIRE_DAYS` (14) | `/auth/refresh` |
| MFA challenge | `MFA_CHALLENGE_EXPIRE_MINUTES` (5) | Only for `/auth/mfa/verify` |

Refresh **rotates**: the used one is revoked and a new one is issued.

### Admin MFA flow

```
1) python scripts/promote_admin.py ana95
2) Normal login → tokens (still without MFA)
3) POST /auth/mfa/setup → secret + otpauth_uri
4) Authenticator app scans QR / URI
5) POST /auth/mfa/confirm { "code": "......" }
6) Next logins:
      password OK → { mfa_required: true, mfa_token }
      POST /auth/mfa/verify → access + refresh
7) Without MFA, POST/PUT/DELETE of categories → 403
```

Regular users do **not** need MFA to use the financial app.

---

## 8. Data Integrity Failures

- API JSON validated by Pydantic schemas.
- Inbound webhooks:
  - Mandatory HMAC signature
  - `WebhookEvent` payload validated
  - Anti-replay timestamp (~5 min)

Endpoint: `POST /api/v1/webhooks/inbound`  
Detail: [API.md](API.md#webhooks).

---

## 9. Logging Failures

The `app.auth` logger records (without passwords or MFA codes):

- failed login (truncated username + IP)
- inactive user
- MFA challenge issued
- wrong MFA code
- invalid refresh
- logout attempt with someone else's refresh

Level: INFO/WARNING via `setup_logging` at startup.

---

## 10. SSRF

- The API does not download URLs sent by the client.
- The webhook receiver does **not** make outgoing requests using `data.url` or similar.

---

## Environment variables (security)

Copy from `.env.example`:

```bash
SECRET_KEY=...                 # JWT + Fernet MFA
ACCESS_TOKEN_EXPIRE_MINUTES=30
REFRESH_TOKEN_EXPIRE_DAYS=14
MFA_CHALLENGE_EXPIRE_MINUTES=5
WEBHOOK_SECRET=...             # HMAC webhooks
FORCE_HTTPS=false              # true in production
RATE_LIMIT_AUTH_MAX=10
RATE_LIMIT_AUTH_WINDOW_SECONDS=60
CORS_ORIGINS=http://localhost:5173
CORS_ALLOW_METHODS=GET,POST,PUT,PATCH,DELETE,OPTIONS
CORS_ALLOW_HEADERS=Authorization,Content-Type,X-Webhook-Signature
APP_ENV=development            # production enables guards
DEBUG=true                     # forced to false in production
```

### Production checklist

```bash
APP_ENV=production
FORCE_HTTPS=true
SECRET_KEY=<random ≥32>
WEBHOOK_SECRET=<random ≥32>
CORS_ORIGINS=https://your-frontend.com
DEBUG=false   # redundant: forced automatically
```

---

## Roles and permissions (quick table)

| Action | user | admin without MFA | admin with MFA |
|--------|------|---------------|---------------|
| CRUD own accounts/txs | Yes | Yes | Yes |
| Read categories | Yes | Yes | Yes |
| Write categories | No | No (403 MFA) | Yes |
| Own reports | Yes | Yes | Yes |
| Inbound webhook | N/A (signature) | N/A | N/A |

---

## Security tests

See `tests/services/test_security_controls.py` and `tests/core/test_security.py`.

More testing context: [TESTING.md](TESTING.md).
