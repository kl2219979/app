#!/usr/bin/env python3
"""
Regenerate scripts/data/demo_100_users.sql (100 demo users + related rows).

Uses multi-row INSERT … SELECT FROM (VALUES …) instead of one INSERT per row.
Balances stay non-negative: incomes fund spending; debits are skipped/clamped.

Usage:
  source .venv/bin/activate
  python scripts/generate_demo_100_users_sql.py
"""

from __future__ import annotations

import random
import uuid
from datetime import date, timedelta
from decimal import Decimal
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
if str(ROOT) not in __import__("sys").path:
    __import__("sys").path.insert(0, str(ROOT))

from app.core.security import hash_password  # noqa: E402

random.seed(42)
OUT = ROOT / "scripts" / "data" / "demo_100_users.sql"

PASSWORD = "Password123!"
PWD_HASH = hash_password(PASSWORD)

NOMBRES = [
    "Ana", "Luis", "María", "Carlos", "Laura", "Andrés", "Camila", "Diego",
    "Sofía", "Juan", "Valentina", "Pedro", "Isabella", "Miguel", "Daniela",
    "Santiago", "Natalia", "Julián", "Paula", "Felipe", "Catalina", "Sebastián",
    "Manuela", "David", "Lucía", "Gabriel", "Elena", "Mateo", "Sara", "Nicolás",
]
APELLIDOS = [
    "García", "Rodríguez", "Martínez", "López", "González", "Pérez", "Sánchez",
    "Ramírez", "Torres", "Flores", "Rivera", "Gómez", "Díaz", "Cruz", "Morales",
    "Ortiz", "Reyes", "Ruiz", "Vargas", "Castro", "Jiménez", "Herrera", "Medina",
    "Aguilar", "Rojas", "Mendoza", "Guerrero", "Navarro", "Silva", "Romero",
]
BANCOS = ["Bancolombia", "Nequi", "Davivienda", "BBVA", "Banco de Bogotá", "Daviplata"]
TIPOS_CTA = ["ahorros", "corriente", "digital"]
GENEROS = ["M", "F", "Otro"]
CATALOG = {
    "Alimentación": ["Supermercado", "Restaurante", "Café"],
    "Transporte": ["Combustible", "Transporte público", "Taxi / apps"],
    "Vivienda": ["Arriendo", "Servicios", "Mantenimiento"],
    "Salud": ["Medicamentos", "Consultas"],
    "Ocio": ["Cine", "Suscripciones", "Salidas"],
    "Educación": ["Cursos", "Libros"],
    "Ingresos": ["Salario", "Freelance", "Otros ingresos"],
    "Transferencias": ["Entre mis cuentas"],
}
GASTO_PAIRS = [
    (cat, sub)
    for cat, subs in CATALOG.items()
    if cat not in ("Ingresos", "Transferencias")
    for sub in subs
]
INGRESO_SUBS = CATALOG["Ingresos"]
CP_NAMES = [
    "Supermercado Éxito", "Arrendador Moreno", "Uber", "Netflix", "EPS Sura",
    "Universidad Nacional", "Restaurante Andrés", "Tienda Local", "Claro", "EPM",
]

INGRESO_AMOUNTS = [800_000, 1_200_000, 1_800_000, 2_200_000, 2_800_000, 3_500_000]
GASTO_BANK_AMOUNTS = [5_000, 12_000, 25_000, 45_000, 78_000, 120_000, 180_000, 250_000]
GASTO_CASH_AMOUNTS = [5_000, 10_000, 15_000, 25_000, 40_000, 55_000, 80_000]
CASH_INITIAL = [200_000, 300_000, 400_000, 500_000]
TRANSFER_AMOUNTS = [50_000, 80_000, 100_000, 150_000, 200_000, 300_000]
MIN_LEFTOVER = Decimal("1000")


def sql_str(value: str | None, *, as_text: bool = False) -> str:
    if value is None:
        return "NULL::text" if as_text else "NULL"
    return "'" + value.replace("'", "''") + "'"


def sql_num(value: Decimal | int | float) -> str:
    return f"{Decimal(value):.2f}"


def chunked(items: list, size: int):
    for i in range(0, len(items), size):
        yield items[i : i + size]


def apply_debit(acc: dict, monto: Decimal) -> Decimal | None:
    """Apply debit if possible. Returns effective monto, or None if skipped.

    Never leaves saldo_final < 0. Prefers skipping when leftover would be
    below MIN_LEFTOVER after a partial clamp (tiny leftovers); otherwise clamps.
    """
    available = acc["saldo_final"]
    if available <= 0:
        return None
    if available >= monto:
        acc["saldo_final"] = available - monto
        return monto
    # Not enough for full amount: clamp or skip
    leftover_if_skip_partial = available  # we'd take all
    if leftover_if_skip_partial < MIN_LEFTOVER:
        # Taking all would leave 0; leftover "after debit" of 0 is < 1000 → skip
        # unless available itself is the only spend option and >= MIN_LEFTOVER worth clamping
        # Prefer skip for tiny leftovers (< 1000 available to spend)
        return None
    # Clamp to available (leaves 0, which is >= 0)
    acc["saldo_final"] = Decimal("0.00")
    return available.quantize(Decimal("0.01"))


def apply_credit(acc: dict, monto: Decimal) -> None:
    acc["saldo_final"] += monto


def main() -> None:
    lines: list[str] = []

    def w(s: str = "") -> None:
        lines.append(s)

    w("-- =============================================================================")
    w("-- Demo dataset: 100 users + accounts + counterparties + transactions")
    w("-- Target: PostgreSQL (backend)")
    w("--")
    w("-- Prerequisites: alembic upgrade head")
    w("-- Style: multi-row INSERT … SELECT FROM (VALUES …) batches")
    w("-- Balances: non-negative (ingresos fund gastos; debits skipped/clamped)")
    w("--")
    w("-- Load:")
    w("--   psql \"$DATABASE_URL\" -f scripts/data/demo_100_users.sql")
    w("--   docker compose exec -T db psql -U \"$POSTGRES_USER\" -d \"$POSTGRES_DB\" \\")
    w("--     < scripts/data/demo_100_users.sql")
    w("--")
    w(f"-- Login: password = {PASSWORD}")
    w("--   usuarios: demo001 .. demo100")
    w("--   correos:  demo001@example.com .. demo100@example.com")
    w("-- Regenerar: python scripts/generate_demo_100_users_sql.py")
    w("-- =============================================================================")
    w()
    w("BEGIN;")
    w()
    w("DELETE FROM transactions t")
    w("USING accounts a, users u")
    w("WHERE t.account_id = a.id AND a.user_id = u.id AND u.correo LIKE 'demo%@example.com';")
    w()
    w("DELETE FROM counterparties cp")
    w("USING users u")
    w("WHERE cp.user_id = u.id AND u.correo LIKE 'demo%@example.com';")
    w()
    w("DELETE FROM accounts a")
    w("USING users u")
    w("WHERE a.user_id = u.id AND u.correo LIKE 'demo%@example.com';")
    w()
    w("DELETE FROM refresh_tokens rt")
    w("USING users u")
    w("WHERE rt.user_id = u.id AND u.correo LIKE 'demo%@example.com';")
    w()
    w("DELETE FROM users WHERE correo LIKE 'demo%@example.com';")
    w()

    w("-- Catalog (idempotent)")
    for cat, subs in CATALOG.items():
        w("INSERT INTO categories (nombre, descripcion, activo)")
        w(f"SELECT {sql_str(cat)}, {sql_str(f'Categoría seed: {cat}')}, true")
        w(f"WHERE NOT EXISTS (SELECT 1 FROM categories WHERE nombre = {sql_str(cat)});")
        for sub in subs:
            w("INSERT INTO sub_categories (category_id, nombre, descripcion, activo)")
            w(
                f"SELECT c.id, {sql_str(sub)}, '', true FROM categories c "
                f"WHERE c.nombre = {sql_str(cat)} "
                f"AND NOT EXISTS ("
                f"SELECT 1 FROM sub_categories s "
                f"WHERE s.category_id = c.id AND s.nombre = {sql_str(sub)}"
                f");"
            )
    w()

    base_date = date(2026, 1, 5)
    users_rows: list[tuple] = []
    accounts_rows: list[tuple] = []
    counterparties_rows: list[tuple] = []
    tx_rows: list[tuple] = []
    saldo_updates: list[tuple] = []

    for i in range(1, 101):
        n = f"{i:03d}"
        usuario = f"demo{n}"
        correo = f"demo{n}@example.com"
        nombre = random.choice(NOMBRES)
        apellido = random.choice(APELLIDOS)
        year = random.randint(1975, 2002)
        month = random.randint(1, 12)
        day = random.randint(1, 28)
        genero = random.choice(GENEROS)
        users_rows.append(
            (nombre, apellido, f"{year:04d}-{month:02d}-{day:02d}", genero, correo, usuario)
        )

        num_accounts = random.randint(2, 3)
        banks = random.sample(BANCOS, k=num_accounts)
        account_keys: list[dict] = []
        for banco in banks:
            # Modest opening balance; real funding comes from ingresos
            saldo = Decimal(random.choice([50_000, 100_000, 150_000, 200_000, 350_000]))
            acc = {
                "banco": banco,
                "tipo": random.choice(TIPOS_CTA),
                "moneda": "COP",
                "saldo": saldo,
                "saldo_final": saldo,
            }
            account_keys.append(acc)
            accounts_rows.append((usuario, banco, acc["tipo"], "COP", saldo))

        has_cash = random.random() < 0.7
        cash_acc: dict | None = None
        if has_cash:
            cash_saldo = Decimal(random.choice(CASH_INITIAL))
            cash_acc = {
                "banco": "Efectivo",
                "tipo": "efectivo",
                "moneda": "COP",
                "saldo": cash_saldo,
                "saldo_final": cash_saldo,
            }
            account_keys.append(cash_acc)
            accounts_rows.append(
                (usuario, "Efectivo", "efectivo", "COP", cash_saldo)
            )

        cps = random.sample(CP_NAMES, k=random.randint(1, 3))
        for cp in cps:
            banco_cp = random.choice([*BANCOS, None, None])
            num = str(random.randint(1000000000, 9999999999)) if banco_cp else None
            counterparties_rows.append((usuario, cp, banco_cp, num))

        non_cash = [a for a in account_keys if a["tipo"] != "efectivo"]
        primary_bank = non_cash[0]

        # Chronological event list so ingresos land early and fund spending
        events: list[tuple] = []

        # 1–2 bank ingresos early
        num_ingresos = random.randint(1, 2)
        for j in range(num_ingresos):
            day_offset = random.randint(0, 12) + j * 3
            events.append(("ingreso", day_offset))

        # Occasional extra ingreso mid-period
        if random.random() < 0.35:
            events.append(("ingreso", random.randint(40, 120)))

        # Bank gatos spread after early funding window
        for _ in range(random.randint(6, 14)):
            events.append(("gasto_bank", random.randint(8, 175)))

        # Fund cash via bank→cash transfer, then cash gatos
        if cash_acc is not None:
            if random.random() < 0.55:
                events.append(("cash_fund", random.randint(5, 40)))
            for _ in range(random.randint(1, 4)):
                events.append(("gasto_cash", random.randint(15, 170)))

        # Inter-account transfers for ~50–60% of users
        do_transfer = random.random() < 0.55
        if do_transfer and len(account_keys) >= 2:
            events.append(("transfer", random.randint(25, 160)))

        events.sort(key=lambda e: e[1])

        for kind, day_offset in events:
            day_d = base_date + timedelta(days=day_offset + (i % 7))

            if kind == "ingreso":
                acc = random.choice(non_cash)
                monto = Decimal(random.choice(INGRESO_AMOUNTS))
                sub = random.choice(INGRESO_SUBS)
                desc = random.choice(["Nomina", "Pago cliente", "Ingreso extra"])
                use_cp = random.random() < 0.25
                apply_credit(acc, monto)
                tx_rows.append(
                    (
                        usuario,
                        acc["banco"],
                        acc["tipo"],
                        "Ingresos",
                        sub,
                        use_cp,
                        monto,
                        "ingreso",
                        "cuenta",
                        day_d.isoformat(),
                        desc,
                        None,
                    )
                )

            elif kind == "gasto_bank":
                acc = random.choice(non_cash)
                monto = Decimal(random.choice(GASTO_BANK_AMOUNTS))
                effective = apply_debit(acc, monto)
                if effective is None:
                    continue
                cat, sub = random.choice(GASTO_PAIRS)
                desc = random.choice(["Compra", "Pago", "Consumo", "Servicio"])
                use_cp = random.random() < 0.4
                tx_rows.append(
                    (
                        usuario,
                        acc["banco"],
                        acc["tipo"],
                        cat,
                        sub,
                        use_cp,
                        effective,
                        "gasto",
                        "cuenta",
                        day_d.isoformat(),
                        desc,
                        None,
                    )
                )

            elif kind == "gasto_cash":
                assert cash_acc is not None
                monto = Decimal(random.choice(GASTO_CASH_AMOUNTS))
                effective = apply_debit(cash_acc, monto)
                if effective is None:
                    continue
                cat, sub = random.choice(GASTO_PAIRS)
                desc = random.choice(["Compra", "Pago", "Consumo", "Servicio"])
                use_cp = random.random() < 0.35
                tx_rows.append(
                    (
                        usuario,
                        cash_acc["banco"],
                        cash_acc["tipo"],
                        cat,
                        sub,
                        use_cp,
                        effective,
                        "gasto",
                        "efectivo",
                        day_d.isoformat(),
                        desc,
                        None,
                    )
                )

            elif kind == "cash_fund":
                assert cash_acc is not None
                origen = primary_bank
                monto_t = Decimal(random.choice(TRANSFER_AMOUNTS))
                if origen["saldo_final"] < monto_t:
                    if origen["saldo_final"] < MIN_LEFTOVER:
                        continue
                    monto_t = origen["saldo_final"].quantize(Decimal("0.01"))
                if monto_t <= 0:
                    continue
                effective = apply_debit(origen, monto_t)
                if effective is None:
                    continue
                apply_credit(cash_acc, effective)
                grupo = str(uuid.uuid4())
                for leg_acc, leg_tipo, leg_desc in (
                    (origen, "transferencia_salida", "Retiro a efectivo (salida)"),
                    (cash_acc, "transferencia_entrada", "Retiro a efectivo (entrada)"),
                ):
                    tx_rows.append(
                        (
                            usuario,
                            leg_acc["banco"],
                            leg_acc["tipo"],
                            "Transferencias",
                            "Entre mis cuentas",
                            False,
                            effective,
                            leg_tipo,
                            "cuenta",
                            day_d.isoformat(),
                            leg_desc,
                            grupo,
                        )
                    )

            elif kind == "transfer":
                origen = random.choice(non_cash)
                destinos = [a for a in account_keys if a is not origen]
                if not destinos:
                    continue
                destino = random.choice(destinos)
                monto_t = Decimal(random.choice(TRANSFER_AMOUNTS))
                if origen["saldo_final"] < monto_t:
                    continue  # only transfer when fully funded
                effective = apply_debit(origen, monto_t)
                if effective is None:
                    continue
                apply_credit(destino, effective)
                grupo = str(uuid.uuid4())
                for leg_acc, leg_tipo, leg_desc in (
                    (origen, "transferencia_salida", "Transferencia entre cuentas (salida)"),
                    (destino, "transferencia_entrada", "Transferencia entre cuentas (entrada)"),
                ):
                    tx_rows.append(
                        (
                            usuario,
                            leg_acc["banco"],
                            leg_acc["tipo"],
                            "Transferencias",
                            "Entre mis cuentas",
                            False,
                            effective,
                            leg_tipo,
                            "cuenta",
                            day_d.isoformat(),
                            leg_desc,
                            grupo,
                        )
                    )

        # Safety: balances must never go negative
        for acc in account_keys:
            assert acc["saldo_final"] >= 0, (
                f"{usuario} {acc['banco']} saldo_final={acc['saldo_final']}"
            )
            saldo_updates.append(
                (usuario, acc["banco"], acc["tipo"], acc["saldo_final"])
            )

    # ---- Emit SQL batches ----
    w("-- Users (multi-row)")
    for batch in chunked(users_rows, 25):
        w(
            "INSERT INTO users ("
            "nombres, apellidos, fecha_nacimiento, genero, correo, usuario, "
            "contrasena_hash, rol, activo, mfa_enabled, mfa_secret_encrypted"
            ") VALUES"
        )
        value_lines = []
        for nombre, apellido, fecha, genero, correo, usuario in batch:
            value_lines.append(
                f"  ({sql_str(nombre)}, {sql_str(apellido)}, {sql_str(fecha)}, "
                f"{sql_str(genero)}, {sql_str(correo)}, {sql_str(usuario)}, "
                f"{sql_str(PWD_HASH)}, 'user', true, false, NULL)"
            )
        w(",\n".join(value_lines) + ";")
        w()

    w("-- Accounts (multi-row via VALUES + join users)")
    for batch in chunked(accounts_rows, 50):
        w("INSERT INTO accounts (user_id, banco, tipo, moneda, saldo, activo)")
        w("SELECT u.id, v.banco, v.tipo, v.moneda, v.saldo::numeric, true")
        w("FROM (VALUES")
        value_lines = [
            f"  ({sql_str(usuario)}, {sql_str(banco)}, {sql_str(tipo)}, "
            f"{sql_str(moneda)}, {sql_num(saldo)})"
            for usuario, banco, tipo, moneda, saldo in batch
        ]
        w(",\n".join(value_lines))
        w(") AS v(usuario, banco, tipo, moneda, saldo)")
        w("JOIN users u ON u.usuario = v.usuario;")
        w()

    w("-- Counterparties (multi-row via VALUES + join users)")
    for batch in chunked(counterparties_rows, 50):
        w(
            "INSERT INTO counterparties ("
            "user_id, nombre, banco, numero_cuenta, notas, activo"
            ")"
        )
        w("SELECT u.id, v.nombre, v.banco, v.numero_cuenta, NULL, true")
        w("FROM (VALUES")
        value_lines = [
            f"  ({sql_str(usuario)}, {sql_str(nombre)}, {sql_str(banco, as_text=True)}, "
            f"{sql_str(numero, as_text=True)})"
            for usuario, nombre, banco, numero in batch
        ]
        w(",\n".join(value_lines))
        w(") AS v(usuario, nombre, banco, numero_cuenta)")
        w("JOIN users u ON u.usuario = v.usuario;")
        w()

    w("-- Transactions (multi-row via VALUES + joins)")
    for batch in chunked(tx_rows, 40):
        w(
            "INSERT INTO transactions ("
            "account_id, category_id, sub_category_id, contraparte_id, monto, tipo, "
            "medio_pago, fecha, descripcion, activo, grupo_transferencia"
            ")"
        )
        w(
            "SELECT a.id, c.id, s.id, "
            "CASE WHEN v.use_cp THEN cp.id ELSE NULL END, "
            "v.monto::numeric, v.tipo, v.medio_pago, v.fecha::date, v.descripcion, true, "
            "NULLIF(v.grupo, '')"
        )
        w("FROM (VALUES")
        value_lines = []
        for (
            usuario,
            banco,
            tipo_cta,
            cat,
            sub,
            use_cp,
            monto,
            tipo,
            medio,
            fecha,
            desc,
            grupo,
        ) in batch:
            value_lines.append(
                f"  ({sql_str(usuario)}, {sql_str(banco)}, {sql_str(tipo_cta)}, "
                f"{sql_str(cat)}, {sql_str(sub)}, {str(use_cp).lower()}, "
                f"{sql_num(monto)}, {sql_str(tipo)}, {sql_str(medio)}, "
                f"{sql_str(fecha)}, {sql_str(desc)}, {sql_str(grupo or '')})"
            )
        w(",\n".join(value_lines))
        w(
            ") AS v(usuario, banco, tipo_cta, cat, sub, use_cp, monto, tipo, "
            "medio_pago, fecha, descripcion, grupo)"
        )
        w("JOIN users u ON u.usuario = v.usuario")
        w(
            "JOIN accounts a ON a.user_id = u.id AND a.banco = v.banco "
            "AND a.tipo = v.tipo_cta"
        )
        w("JOIN categories c ON c.nombre = v.cat")
        w("JOIN sub_categories s ON s.category_id = c.id AND s.nombre = v.sub")
        w("LEFT JOIN LATERAL (")
        w("  SELECT id FROM counterparties WHERE user_id = u.id ORDER BY id LIMIT 1")
        w(") cp ON v.use_cp;")
        w()

    w("-- Reconcile account balances (multi-row)")
    for batch in chunked(saldo_updates, 50):
        w("UPDATE accounts a SET")
        w("  saldo = v.saldo::numeric,")
        w("  actualizado_en = now()")
        w("FROM (VALUES")
        value_lines = [
            f"  ({sql_str(usuario)}, {sql_str(banco)}, {sql_str(tipo)}, {sql_num(saldo)})"
            for usuario, banco, tipo, saldo in batch
        ]
        w(",\n".join(value_lines))
        w(") AS v(usuario, banco, tipo, saldo)")
        w("JOIN users u ON u.usuario = v.usuario")
        w(
            "WHERE a.user_id = u.id AND a.banco = v.banco AND a.tipo = v.tipo;"
        )
        w()

    for table in (
        "users",
        "accounts",
        "counterparties",
        "transactions",
        "categories",
        "sub_categories",
    ):
        w(
            f"SELECT setval(pg_get_serial_sequence('{table}', 'id'), "
            f"COALESCE((SELECT MAX(id) FROM {table}), 1));"
        )
    w()
    w("COMMIT;")
    w()
    w("-- Verification:")
    w("-- SELECT COUNT(*) FROM users WHERE correo LIKE 'demo%@example.com';")
    w(
        "-- SELECT COUNT(*) FROM accounts a JOIN users u ON u.id = a.user_id "
        "WHERE u.correo LIKE 'demo%@example.com';"
    )
    w(
        "-- SELECT COUNT(*) FROM transactions t "
        "JOIN accounts a ON a.id = t.account_id "
        "JOIN users u ON u.id = a.user_id "
        "WHERE u.correo LIKE 'demo%@example.com';"
    )

    text = "\n".join(lines) + "\n"
    OUT.parent.mkdir(parents=True, exist_ok=True)
    OUT.write_text(text, encoding="utf-8")

    # Stats for console
    neg = sum(1 for *_, s in saldo_updates if s < 0)
    min_saldo = min(s for *_, s in saldo_updates)
    n_ing = sum(1 for r in tx_rows if r[7] == "ingreso")
    n_gasto = sum(1 for r in tx_rows if r[7] == "gasto")
    n_xfer = sum(1 for r in tx_rows if r[7] == "transferencia_salida")
    print(
        f"[ok] wrote {OUT} ({OUT.stat().st_size} bytes, {len(lines)} lines)\n"
        f"     txs={len(tx_rows)} (ingreso={n_ing}, gasto={n_gasto}, "
        f"xfer_pairs={n_xfer}), accounts={len(saldo_updates)}, "
        f"min_saldo={min_saldo}, neg_balances={neg}"
    )


if __name__ == "__main__":
    main()
