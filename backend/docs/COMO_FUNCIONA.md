# Cómo funciona este backend (guía paso a paso)

Esta guía explica **qué es cada cosa** y **por qué existe**.
Léela en orden la primera vez. Índice de toda la documentación: [INDICE.md](INDICE.md).

---

## 1. La idea general

Imagina tres piezas separadas:

```
[ Frontend (Vite/React/…) ]  --HTTPS/HTTP-->  [ API FastAPI ]  --SQL-->  [ PostgreSQL ]
        pantallas                              lógica + auth              datos persistentes
```

- El **frontend** solo habla con la API (nunca con la base de datos).
- La **API** decide qué se puede hacer y aplica reglas de dinero/seguridad.
- **PostgreSQL** solo guarda y entrega filas. No sabe de JWT ni de “gasto vs ingreso”.

La base está **desacoplada**: vive en su contenedor Docker; el esquema lo versiona **Alembic** junto al código.

Producto (finanzas personales): [NEGOCIO.md](NEGOCIO.md).

---

## 2. ¿Qué problema resuelve cada herramienta?

| Herramienta | Pregunta que responde | Analogía |
|-------------|----------------------|----------|
| **Docker / Postgres** | ¿Dónde corre la base? | Nevera: guarda, no cocina |
| **Alembic** | ¿Cómo cambian las tablas? | Planos de la cocina |
| **SQLAlchemy models** | ¿Cómo se ve una tabla en Python? | Etiquetas de cada estante |
| **Repositories** | ¿Cómo leo/escribo filas? | Abrir la nevera |
| **Services** | ¿Está permitido? | El cocinero / la receta |
| **Endpoints** | ¿Qué URL llama el front? | Ventanilla |
| **Schemas (Pydantic)** | ¿El JSON es válido? | Revisar el pedido |
| **core/security, mfa…** | ¿Cómo autenticamos y firmamos? | Llaves y candados |

Regla mental:

- **Alembic** = estructura  
- **Services** = lógica de negocio  
- **Repositories** = acceso técnico  

---

## 3. Capas dentro de `app/`

```
Request HTTP
    ↓
endpoints/     → reciben la petición, casi sin lógica
    ↓
schemas/       → validan el JSON de entrada/salida
    ↓
services/      → deciden SI se puede y QUÉ hacer
    ↓
repositories/  → ejecutan el ORM
    ↓
PostgreSQL
```

| Capa | Decide | No debería |
|------|--------|------------|
| Endpoint | Ruta, status, Depends | Reglas de negocio largas |
| Service | Permisos, saldos, soft-delete | Detalles crudos de SQL |
| Repository | Queries, flush | “¿Es admin?” |
| Model | Columnas y relaciones | Respuestas HTTP |
| Schema | Forma del JSON | Hablar con la BD |

### Mapa de carpetas reales

```
app/
├── main.py                 # Crea FastAPI, CORS, cabeceras, router
├── api/
│   ├── deps.py             # get_db, get_current_user, get_current_admin
│   └── v1/
│       ├── router.py       # Monta todos los endpoints
│       └── endpoints/      # auth, accounts, transactions, …
├── core/
│   ├── config.py           # settings desde .env
│   ├── security.py         # bcrypt + JWT
│   ├── mfa.py              # TOTP admin
│   ├── rate_limit.py
│   ├── webhooks.py         # HMAC
│   └── logging_config.py
├── db/                     # Base + SessionLocal
├── models/                 # Tablas SQLAlchemy
├── schemas/                # DTOs Pydantic
├── services/               # Negocio (+ seed)
└── repositories/           # Acceso a datos
```

---

## 4. El flujo cuando enciendes todo

### Opción A — Desarrollo (recomendada)

```bash
chmod +x scripts/*.sh
./scripts/setup.sh              # 1) venv + deps + .env
source .venv/bin/activate
docker compose up db -d         # 2) Solo Postgres
./scripts/migrate.sh            # 3) Tablas (Alembic)
python scripts/seed.py          # 4) Catálogo de categorías (opcional)
uvicorn app.main:app --reload   # 5) API
```

| Paso | Qué / por qué |
|------|----------------|
| `setup.sh` | Crea `.venv`, instala `requirements-dev.txt`, copia `.env.example` → `.env` |
| `docker compose up db -d` | Postgres vacío (solo motor + DB `app_db`) |
| `migrate.sh` | Espera BD + `alembic upgrade head` |
| `seed.py` | Categorías base idempotentes |
| `uvicorn` | Sirve HTTP en `:8000` |

API: http://localhost:8000  
Docs interactivas (si `DEBUG=true`): http://localhost:8000/docs

### Opción B — Todo Docker

```bash
cp .env.example .env
docker compose up --build
```

El `entrypoint.sh` del servicio `api`:

1. Espera Postgres  
2. Migra  
3. Arranca Uvicorn  

Dentro de Docker, `POSTGRES_HOST=db` (nombre del servicio), no `localhost`.

---

## 5. Archivos de infraestructura (qué / por qué)

| Archivo | Rol |
|---------|-----|
| `docker-compose.yml` | Servicios `db` y `api` |
| `Dockerfile` | Imagen Python de la API |
| `scripts/setup.sh` | Onboarding local |
| `scripts/wait_for_db.py` | Evita carrera al arrancar Postgres |
| `scripts/migrate.sh` | Migrar en local |
| `scripts/entrypoint.sh` | Migrar + exec uvicorn en contenedor |
| `scripts/seed.py` | Catálogo inicial |
| `scripts/promote_admin.py` | Promueve rol admin (luego MFA) |
| `.env` / `.env.example` | Secretos y config (`.env` no va a Git) |
| `alembic/` | Historial de esquema |
| `.github/workflows/ci.yml` | Ruff + pip-audit + pytest |
| `.github/dependabot.yml` | PRs de dependencias |

---

## 6. Request autenticado (ejemplo mental)

1. Cliente envía `Authorization: Bearer <access_jwt>`.
2. `get_current_user` valida firma/exp y carga el `User` activo.
3. El endpoint llama al service con `current_user` + body ya validado por Pydantic.
4. El service comprueba ownership / reglas de saldo / activo.
5. El repository persiste; el service hace `commit`.
6. Se responde con un schema `*Response`.

Si es escritura de categoría:

- `get_current_admin` exige admin **y** MFA.

Detalle: [SEGURIDAD.md](SEGURIDAD.md), [API.md](API.md).

---

## 7. Dinero en una frase

> El saldo de una cuenta solo cambia por movimientos (y por `saldo_inicial` al crearla).  
> DELETE no borra historia: desactiva.  
> Las transferencias son dos piernas enlazadas y no cuentan como gasto del mes.

Ampliar: [NEGOCIO.md](NEGOCIO.md).

---

## 8. Mapa mental rápido

```
¿Encender solo la BD?              → docker compose up db -d
¿Crear/actualizar tablas?          → ./scripts/migrate.sh
¿API local?                        → uvicorn app.main:app --reload
¿Catálogo base?                    → python scripts/seed.py
¿Hacer admin?                      → promote_admin + MFA setup/confirm
¿Dónde va una regla de negocio?    → app/services/
¿Dónde va un SELECT?               → app/repositories/
¿Dónde va una URL nueva?           → app/api/v1/endpoints/
¿Contrato JSON?                    → app/schemas/
¿Tabla nueva?                      → app/models/ + Alembic
¿Probar?                           → pytest -q   (ver TESTING.md)
```

---

## 9. Si algo falla

| Síntoma | Causa probable | Qué hacer |
|---------|----------------|-----------|
| `Connection refused` a Postgres | BD apagada | `docker compose up db -d` |
| API sin tablas | No migraste | `./scripts/migrate.sh` |
| Autogenerate no ve el modelo | Falta import | `app/models/__init__.py` |
| Front no llama a la API | CORS | `CORS_ORIGINS` en `.env` |
| API en Docker no ve la BD | Usaste `localhost` | Host debe ser `db` |
| 429 en login durante tests | Rate limit global | Ya se limpia en conftest; reinicia suite |
| 403 en categorías | No eres admin o sin MFA | `promote_admin` + `/auth/mfa/*` |
| 422 al editar saldo de cuenta | Diseño intencional | Usa transacciones |
| App no arranca en `production` | Falta SECRET/WEBHOOK/HTTPS | Ver checklist en SEGURIDAD |

---

## 10. Siguiente lectura

1. [NEGOCIO.md](NEGOCIO.md) — comportamiento del producto  
2. [API.md](API.md) — endpoints uno a uno  
3. [MODELOS.md](MODELOS.md) — tablas  
4. [SEGURIDAD.md](SEGURIDAD.md) — auth y OWASP  
5. [TESTING.md](TESTING.md) — cómo no romper nada  
