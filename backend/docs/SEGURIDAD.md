# Seguridad (guía completa)

Este backend está pensado para cumplir una checklist tipo **OWASP Top 10**.
Código clave:

| Pieza | Ruta |
|-------|------|
| Config / prod guards | `app/core/config.py` |
| Passwords + JWT | `app/core/security.py` |
| MFA TOTP | `app/core/mfa.py` |
| Rate limit | `app/core/rate_limit.py` |
| Webhooks HMAC | `app/core/webhooks.py` |
| Logging | `app/core/logging_config.py` |
| Cabeceras / HTTPS | `app/main.py` |
| Dependencias JWT/admin | `app/api/deps.py` |
| Auth service | `app/services/auth.py` |

---

## 1. Broken Access Control

- Casi todos los recursos exigen JWT (`get_current_user`).
- Ownership en services: cuentas, txs, reportes y perfil solo del dueño.
- Mutaciones de catálogo: `get_current_admin` → exige `rol=admin` **y** `mfa_enabled`.
- Logout: solo puedes revocar refresh tokens **tuyos** (no los de otro usuario).
- Públicos a propósito: `/health`, registro/login/refresh/mfa-verify, webhooks firmados.

---

## 2. Cryptographic Failures

| Dato | Protección |
|------|------------|
| Contraseña | bcrypt (`hash_password` / `verify_password`) |
| Access token | JWT HS256 firmado con `SECRET_KEY`, claim `exp` |
| Refresh token | Opaco; en BD solo SHA-256 |
| Secreto TOTP | Cifrado Fernet derivado de `SECRET_KEY` |
| Webhooks | HMAC-SHA256 |

### HTTPS en producción

La API **no** termina TLS ella misma (no embebe certificados).

En producción debes:

1. Poner un reverse proxy (Nginx, Caddy, Traefik, ALB…) con HTTPS.
2. `FORCE_HTTPS=true` y `APP_ENV=production`.
3. El proxy envía `X-Forwarded-Proto: https`.
4. Si llega HTTP, la API responde **400** “HTTPS required”.
5. Se añade cabecera **HSTS**.

---

## 3. Injection

- Entrada validada con **Pydantic** (`app/schemas/`).
- Persistencia con **SQLAlchemy ORM** (parámetros enlazados).
- No hay SQL crudo construido con input de usuario en el camino de la API.

---

## 4. Insecure Design

- Rate limiting por IP en `/auth/*` y `/webhooks/*` (ventana deslizante in-memory).
- Validaciones de longitud/formato en schemas.
- Mínimo privilegio: user vs admin+MFA.
- Soft-delete para no destruir historial financiero.

Variables:

- `RATE_LIMIT_AUTH_MAX` (default 10)
- `RATE_LIMIT_AUTH_WINDOW_SECONDS` (default 60)

Nota: el limiter in-memory es por proceso. En varias réplicas usa un store compartido (Redis) en el futuro; hoy sirve para un nodo / desarrollo.

---

## 5. Security Misconfiguration

Con `APP_ENV=production`, `Settings` **fuerza**:

| Regla | Detalle |
|-------|---------|
| `DEBUG=False` | Aunque el `.env` diga `true` |
| `SECRET_KEY` | ≥ 32 chars, no placeholders `change-me…` |
| `WEBHOOK_SECRET` | Obligatorio, ≥ 32 chars |
| `FORCE_HTTPS=true` | Obligatorio |
| CORS | No se permite `*` en origins |

CORS estricto:

- Origins desde `CORS_ORIGINS` (lista)
- Methods desde `CORS_ALLOW_METHODS`
- Headers desde `CORS_ALLOW_HEADERS`

Swagger/ReDoc solo si `DEBUG=true`.

Cabeceras de seguridad en todas las respuestas:

- `X-Content-Type-Options: nosniff`
- `X-Frame-Options: DENY`
- `Referrer-Policy: no-referrer`
- `Permissions-Policy: …`
- `Strict-Transport-Security` si prod / FORCE_HTTPS

---

## 6. Vulnerable Components

- CI: `pip-audit -r requirements.txt -r requirements-dev.txt`
- Dependabot: `.github/dependabot.yml` (pip + GitHub Actions, semanal)

Actualiza deps cuando Dependabot abra PRs; no ignores auditorías en rojo.

---

## 7. Auth Failures (JWT + MFA)

### Tokens

| Token | Vida típica | Uso |
|-------|-------------|-----|
| Access JWT | `ACCESS_TOKEN_EXPIRE_MINUTES` (30) | Header Bearer |
| Refresh opaco | `REFRESH_TOKEN_EXPIRE_DAYS` (14) | `/auth/refresh` |
| MFA challenge | `MFA_CHALLENGE_EXPIRE_MINUTES` (5) | Solo para `/auth/mfa/verify` |

Refresh **rota**: el usado se revoca y se emite uno nuevo.

### Flujo MFA admin

```
1) python scripts/promote_admin.py ana95
2) Login normal → tokens (aún sin MFA)
3) POST /auth/mfa/setup → secret + otpauth_uri
4) App authenticator escanea QR / URI
5) POST /auth/mfa/confirm { "code": "......" }
6) Próximos logins:
      password OK → { mfa_required: true, mfa_token }
      POST /auth/mfa/verify → access + refresh
7) Sin MFA, POST/PUT/DELETE de categorías → 403
```

Usuarios normales **no** necesitan MFA para usar la app financiera.

---

## 8. Data Integrity Failures

- JSON de API validado por schemas Pydantic.
- Webhooks entrantes:
  - Firma HMAC obligatoria
  - Payload `WebhookEvent` validado
  - Timestamp anti-replay (~5 min)

Endpoint: `POST /api/v1/webhooks/inbound`  
Detalle: [API.md](API.md#webhooks).

---

## 9. Logging Failures

Logger `app.auth` registra (sin passwords ni códigos MFA):

- login fallido (username recortado + IP)
- usuario inactivo
- challenge MFA emitido
- MFA código incorrecto
- refresh inválido
- intento de logout con refresh ajeno

Nivel: INFO/WARNING vía `setup_logging` al arrancar.

---

## 10. SSRF

- La API no descarga URLs enviadas por el cliente.
- El receptor de webhooks **no** hace requests salientes usando `data.url` ni similares.

---

## Variables de entorno (seguridad)

Copia de `.env.example`:

```bash
SECRET_KEY=...                 # JWT + Fernet MFA
ACCESS_TOKEN_EXPIRE_MINUTES=30
REFRESH_TOKEN_EXPIRE_DAYS=14
MFA_CHALLENGE_EXPIRE_MINUTES=5
WEBHOOK_SECRET=...             # HMAC webhooks
FORCE_HTTPS=false              # true en production
RATE_LIMIT_AUTH_MAX=10
RATE_LIMIT_AUTH_WINDOW_SECONDS=60
CORS_ORIGINS=http://localhost:5173
CORS_ALLOW_METHODS=GET,POST,PUT,PATCH,DELETE,OPTIONS
CORS_ALLOW_HEADERS=Authorization,Content-Type,X-Webhook-Signature
APP_ENV=development            # production activa guards
DEBUG=true                     # forzado a false en production
```

### Checklist producción

```bash
APP_ENV=production
FORCE_HTTPS=true
SECRET_KEY=<random ≥32>
WEBHOOK_SECRET=<random ≥32>
CORS_ORIGINS=https://tu-frontend.com
DEBUG=false   # redundante: se fuerza solo
```

---

## Roles y permisos (tabla rápida)

| Acción | user | admin sin MFA | admin con MFA |
|--------|------|---------------|---------------|
| CRUD propias cuentas/txs | Sí | Sí | Sí |
| Leer categorías | Sí | Sí | Sí |
| Escribir categorías | No | No (403 MFA) | Sí |
| Reports propios | Sí | Sí | Sí |
| Webhook inbound | N/A (firma) | N/A | N/A |

---

## Pruebas de seguridad

Ver `tests/services/test_security_controls.py` y `tests/core/test_security.py`.

Más contexto de testing: [TESTING.md](TESTING.md).
