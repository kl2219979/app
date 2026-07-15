-- =============================================================================
-- Demo dataset: 100 users + accounts + counterparties + transactions
-- Target: PostgreSQL (backend)
--
-- Prerequisites: alembic upgrade head
-- Style: multi-row INSERT … SELECT FROM (VALUES …) batches
-- Balances: non-negative (ingresos fund gastos; debits skipped/clamped)
--
-- Load:
--   psql "$DATABASE_URL" -f scripts/data/demo_100_users.sql
--   docker compose exec -T db psql -U "$POSTGRES_USER" -d "$POSTGRES_DB" \
--     < scripts/data/demo_100_users.sql
--
-- Login: password = Password123!
--   usuarios: demo001 .. demo100
--   correos:  demo001@example.com .. demo100@example.com
-- Regenerar: python scripts/generate_demo_100_users_sql.py
-- =============================================================================

BEGIN;

DELETE FROM transactions t
USING accounts a, users u
WHERE t.account_id = a.id AND a.user_id = u.id AND u.correo LIKE 'demo%@example.com';

DELETE FROM counterparties cp
USING users u
WHERE cp.user_id = u.id AND u.correo LIKE 'demo%@example.com';

DELETE FROM accounts a
USING users u
WHERE a.user_id = u.id AND u.correo LIKE 'demo%@example.com';

DELETE FROM refresh_tokens rt
USING users u
WHERE rt.user_id = u.id AND u.correo LIKE 'demo%@example.com';

DELETE FROM users WHERE correo LIKE 'demo%@example.com';

-- Catalog (idempotent)
INSERT INTO categories (nombre, descripcion, activo)
SELECT 'Alimentación', 'Categoría seed: Alimentación', true
WHERE NOT EXISTS (SELECT 1 FROM categories WHERE nombre = 'Alimentación');
INSERT INTO sub_categories (category_id, nombre, descripcion, activo)
SELECT c.id, 'Supermercado', '', true FROM categories c WHERE c.nombre = 'Alimentación' AND NOT EXISTS (SELECT 1 FROM sub_categories s WHERE s.category_id = c.id AND s.nombre = 'Supermercado');
INSERT INTO sub_categories (category_id, nombre, descripcion, activo)
SELECT c.id, 'Restaurante', '', true FROM categories c WHERE c.nombre = 'Alimentación' AND NOT EXISTS (SELECT 1 FROM sub_categories s WHERE s.category_id = c.id AND s.nombre = 'Restaurante');
INSERT INTO sub_categories (category_id, nombre, descripcion, activo)
SELECT c.id, 'Café', '', true FROM categories c WHERE c.nombre = 'Alimentación' AND NOT EXISTS (SELECT 1 FROM sub_categories s WHERE s.category_id = c.id AND s.nombre = 'Café');
INSERT INTO categories (nombre, descripcion, activo)
SELECT 'Transporte', 'Categoría seed: Transporte', true
WHERE NOT EXISTS (SELECT 1 FROM categories WHERE nombre = 'Transporte');
INSERT INTO sub_categories (category_id, nombre, descripcion, activo)
SELECT c.id, 'Combustible', '', true FROM categories c WHERE c.nombre = 'Transporte' AND NOT EXISTS (SELECT 1 FROM sub_categories s WHERE s.category_id = c.id AND s.nombre = 'Combustible');
INSERT INTO sub_categories (category_id, nombre, descripcion, activo)
SELECT c.id, 'Transporte público', '', true FROM categories c WHERE c.nombre = 'Transporte' AND NOT EXISTS (SELECT 1 FROM sub_categories s WHERE s.category_id = c.id AND s.nombre = 'Transporte público');
INSERT INTO sub_categories (category_id, nombre, descripcion, activo)
SELECT c.id, 'Taxi / apps', '', true FROM categories c WHERE c.nombre = 'Transporte' AND NOT EXISTS (SELECT 1 FROM sub_categories s WHERE s.category_id = c.id AND s.nombre = 'Taxi / apps');
INSERT INTO categories (nombre, descripcion, activo)
SELECT 'Vivienda', 'Categoría seed: Vivienda', true
WHERE NOT EXISTS (SELECT 1 FROM categories WHERE nombre = 'Vivienda');
INSERT INTO sub_categories (category_id, nombre, descripcion, activo)
SELECT c.id, 'Arriendo', '', true FROM categories c WHERE c.nombre = 'Vivienda' AND NOT EXISTS (SELECT 1 FROM sub_categories s WHERE s.category_id = c.id AND s.nombre = 'Arriendo');
INSERT INTO sub_categories (category_id, nombre, descripcion, activo)
SELECT c.id, 'Servicios', '', true FROM categories c WHERE c.nombre = 'Vivienda' AND NOT EXISTS (SELECT 1 FROM sub_categories s WHERE s.category_id = c.id AND s.nombre = 'Servicios');
INSERT INTO sub_categories (category_id, nombre, descripcion, activo)
SELECT c.id, 'Mantenimiento', '', true FROM categories c WHERE c.nombre = 'Vivienda' AND NOT EXISTS (SELECT 1 FROM sub_categories s WHERE s.category_id = c.id AND s.nombre = 'Mantenimiento');
INSERT INTO categories (nombre, descripcion, activo)
SELECT 'Salud', 'Categoría seed: Salud', true
WHERE NOT EXISTS (SELECT 1 FROM categories WHERE nombre = 'Salud');
INSERT INTO sub_categories (category_id, nombre, descripcion, activo)
SELECT c.id, 'Medicamentos', '', true FROM categories c WHERE c.nombre = 'Salud' AND NOT EXISTS (SELECT 1 FROM sub_categories s WHERE s.category_id = c.id AND s.nombre = 'Medicamentos');
INSERT INTO sub_categories (category_id, nombre, descripcion, activo)
SELECT c.id, 'Consultas', '', true FROM categories c WHERE c.nombre = 'Salud' AND NOT EXISTS (SELECT 1 FROM sub_categories s WHERE s.category_id = c.id AND s.nombre = 'Consultas');
INSERT INTO categories (nombre, descripcion, activo)
SELECT 'Ocio', 'Categoría seed: Ocio', true
WHERE NOT EXISTS (SELECT 1 FROM categories WHERE nombre = 'Ocio');
INSERT INTO sub_categories (category_id, nombre, descripcion, activo)
SELECT c.id, 'Cine', '', true FROM categories c WHERE c.nombre = 'Ocio' AND NOT EXISTS (SELECT 1 FROM sub_categories s WHERE s.category_id = c.id AND s.nombre = 'Cine');
INSERT INTO sub_categories (category_id, nombre, descripcion, activo)
SELECT c.id, 'Suscripciones', '', true FROM categories c WHERE c.nombre = 'Ocio' AND NOT EXISTS (SELECT 1 FROM sub_categories s WHERE s.category_id = c.id AND s.nombre = 'Suscripciones');
INSERT INTO sub_categories (category_id, nombre, descripcion, activo)
SELECT c.id, 'Salidas', '', true FROM categories c WHERE c.nombre = 'Ocio' AND NOT EXISTS (SELECT 1 FROM sub_categories s WHERE s.category_id = c.id AND s.nombre = 'Salidas');
INSERT INTO categories (nombre, descripcion, activo)
SELECT 'Educación', 'Categoría seed: Educación', true
WHERE NOT EXISTS (SELECT 1 FROM categories WHERE nombre = 'Educación');
INSERT INTO sub_categories (category_id, nombre, descripcion, activo)
SELECT c.id, 'Cursos', '', true FROM categories c WHERE c.nombre = 'Educación' AND NOT EXISTS (SELECT 1 FROM sub_categories s WHERE s.category_id = c.id AND s.nombre = 'Cursos');
INSERT INTO sub_categories (category_id, nombre, descripcion, activo)
SELECT c.id, 'Libros', '', true FROM categories c WHERE c.nombre = 'Educación' AND NOT EXISTS (SELECT 1 FROM sub_categories s WHERE s.category_id = c.id AND s.nombre = 'Libros');
INSERT INTO categories (nombre, descripcion, activo)
SELECT 'Ingresos', 'Categoría seed: Ingresos', true
WHERE NOT EXISTS (SELECT 1 FROM categories WHERE nombre = 'Ingresos');
INSERT INTO sub_categories (category_id, nombre, descripcion, activo)
SELECT c.id, 'Salario', '', true FROM categories c WHERE c.nombre = 'Ingresos' AND NOT EXISTS (SELECT 1 FROM sub_categories s WHERE s.category_id = c.id AND s.nombre = 'Salario');
INSERT INTO sub_categories (category_id, nombre, descripcion, activo)
SELECT c.id, 'Freelance', '', true FROM categories c WHERE c.nombre = 'Ingresos' AND NOT EXISTS (SELECT 1 FROM sub_categories s WHERE s.category_id = c.id AND s.nombre = 'Freelance');
INSERT INTO sub_categories (category_id, nombre, descripcion, activo)
SELECT c.id, 'Otros ingresos', '', true FROM categories c WHERE c.nombre = 'Ingresos' AND NOT EXISTS (SELECT 1 FROM sub_categories s WHERE s.category_id = c.id AND s.nombre = 'Otros ingresos');
INSERT INTO categories (nombre, descripcion, activo)
SELECT 'Transferencias', 'Categoría seed: Transferencias', true
WHERE NOT EXISTS (SELECT 1 FROM categories WHERE nombre = 'Transferencias');
INSERT INTO sub_categories (category_id, nombre, descripcion, activo)
SELECT c.id, 'Entre mis cuentas', '', true FROM categories c WHERE c.nombre = 'Transferencias' AND NOT EXISTS (SELECT 1 FROM sub_categories s WHERE s.category_id = c.id AND s.nombre = 'Entre mis cuentas');

-- Users (multi-row)
INSERT INTO users (nombres, apellidos, fecha_nacimiento, genero, correo, usuario, contrasena_hash, rol, activo, mfa_enabled, mfa_secret_encrypted) VALUES
  ('Catalina', 'López', '1975-12-09', 'M', 'demo001@example.com', 'demo001', '$2b$12$VBUZ1Eexmj/JSanTBLXJeeInE0uvVb5hKVKGQMU/7NSCOhFUQvhbS', 'user', true, false, NULL),
  ('Julián', 'Ruiz', '1983-12-19', 'F', 'demo002@example.com', 'demo002', '$2b$12$VBUZ1Eexmj/JSanTBLXJeeInE0uvVb5hKVKGQMU/7NSCOhFUQvhbS', 'user', true, false, NULL),
  ('Sebastián', 'Jiménez', '1995-02-02', 'F', 'demo003@example.com', 'demo003', '$2b$12$VBUZ1Eexmj/JSanTBLXJeeInE0uvVb5hKVKGQMU/7NSCOhFUQvhbS', 'user', true, false, NULL),
  ('Laura', 'Romero', '1986-02-08', 'F', 'demo004@example.com', 'demo004', '$2b$12$VBUZ1Eexmj/JSanTBLXJeeInE0uvVb5hKVKGQMU/7NSCOhFUQvhbS', 'user', true, false, NULL),
  ('Sofía', 'Navarro', '1977-05-12', 'Otro', 'demo005@example.com', 'demo005', '$2b$12$VBUZ1Eexmj/JSanTBLXJeeInE0uvVb5hKVKGQMU/7NSCOhFUQvhbS', 'user', true, false, NULL),
  ('Sara', 'Pérez', '1998-08-15', 'F', 'demo006@example.com', 'demo006', '$2b$12$VBUZ1Eexmj/JSanTBLXJeeInE0uvVb5hKVKGQMU/7NSCOhFUQvhbS', 'user', true, false, NULL),
  ('Manuela', 'Guerrero', '1995-04-04', 'Otro', 'demo007@example.com', 'demo007', '$2b$12$VBUZ1Eexmj/JSanTBLXJeeInE0uvVb5hKVKGQMU/7NSCOhFUQvhbS', 'user', true, false, NULL),
  ('Lucía', 'Reyes', '1994-05-04', 'M', 'demo008@example.com', 'demo008', '$2b$12$VBUZ1Eexmj/JSanTBLXJeeInE0uvVb5hKVKGQMU/7NSCOhFUQvhbS', 'user', true, false, NULL),
  ('Andrés', 'Mendoza', '1984-10-24', 'Otro', 'demo009@example.com', 'demo009', '$2b$12$VBUZ1Eexmj/JSanTBLXJeeInE0uvVb5hKVKGQMU/7NSCOhFUQvhbS', 'user', true, false, NULL),
  ('Lucía', 'Cruz', '1976-06-24', 'F', 'demo010@example.com', 'demo010', '$2b$12$VBUZ1Eexmj/JSanTBLXJeeInE0uvVb5hKVKGQMU/7NSCOhFUQvhbS', 'user', true, false, NULL),
  ('Diego', 'Castro', '2000-06-08', 'Otro', 'demo011@example.com', 'demo011', '$2b$12$VBUZ1Eexmj/JSanTBLXJeeInE0uvVb5hKVKGQMU/7NSCOhFUQvhbS', 'user', true, false, NULL),
  ('Sofía', 'Rodríguez', '1979-12-14', 'Otro', 'demo012@example.com', 'demo012', '$2b$12$VBUZ1Eexmj/JSanTBLXJeeInE0uvVb5hKVKGQMU/7NSCOhFUQvhbS', 'user', true, false, NULL),
  ('Catalina', 'García', '1977-12-17', 'M', 'demo013@example.com', 'demo013', '$2b$12$VBUZ1Eexmj/JSanTBLXJeeInE0uvVb5hKVKGQMU/7NSCOhFUQvhbS', 'user', true, false, NULL),
  ('Mateo', 'Jiménez', '1985-03-15', 'M', 'demo014@example.com', 'demo014', '$2b$12$VBUZ1Eexmj/JSanTBLXJeeInE0uvVb5hKVKGQMU/7NSCOhFUQvhbS', 'user', true, false, NULL),
  ('Lucía', 'Aguilar', '2000-08-08', 'Otro', 'demo015@example.com', 'demo015', '$2b$12$VBUZ1Eexmj/JSanTBLXJeeInE0uvVb5hKVKGQMU/7NSCOhFUQvhbS', 'user', true, false, NULL),
  ('Natalia', 'Gómez', '1977-09-18', 'Otro', 'demo016@example.com', 'demo016', '$2b$12$VBUZ1Eexmj/JSanTBLXJeeInE0uvVb5hKVKGQMU/7NSCOhFUQvhbS', 'user', true, false, NULL),
  ('Catalina', 'Gómez', '1986-07-19', 'M', 'demo017@example.com', 'demo017', '$2b$12$VBUZ1Eexmj/JSanTBLXJeeInE0uvVb5hKVKGQMU/7NSCOhFUQvhbS', 'user', true, false, NULL),
  ('Valentina', 'Romero', '1997-04-12', 'Otro', 'demo018@example.com', 'demo018', '$2b$12$VBUZ1Eexmj/JSanTBLXJeeInE0uvVb5hKVKGQMU/7NSCOhFUQvhbS', 'user', true, false, NULL),
  ('David', 'Guerrero', '1984-10-11', 'Otro', 'demo019@example.com', 'demo019', '$2b$12$VBUZ1Eexmj/JSanTBLXJeeInE0uvVb5hKVKGQMU/7NSCOhFUQvhbS', 'user', true, false, NULL),
  ('Andrés', 'Romero', '1998-05-02', 'M', 'demo020@example.com', 'demo020', '$2b$12$VBUZ1Eexmj/JSanTBLXJeeInE0uvVb5hKVKGQMU/7NSCOhFUQvhbS', 'user', true, false, NULL),
  ('Sebastián', 'Mendoza', '1984-12-01', 'F', 'demo021@example.com', 'demo021', '$2b$12$VBUZ1Eexmj/JSanTBLXJeeInE0uvVb5hKVKGQMU/7NSCOhFUQvhbS', 'user', true, false, NULL),
  ('Sofía', 'Rodríguez', '1992-10-24', 'M', 'demo022@example.com', 'demo022', '$2b$12$VBUZ1Eexmj/JSanTBLXJeeInE0uvVb5hKVKGQMU/7NSCOhFUQvhbS', 'user', true, false, NULL),
  ('Miguel', 'Rodríguez', '1993-04-24', 'M', 'demo023@example.com', 'demo023', '$2b$12$VBUZ1Eexmj/JSanTBLXJeeInE0uvVb5hKVKGQMU/7NSCOhFUQvhbS', 'user', true, false, NULL),
  ('Diego', 'Guerrero', '1977-06-20', 'Otro', 'demo024@example.com', 'demo024', '$2b$12$VBUZ1Eexmj/JSanTBLXJeeInE0uvVb5hKVKGQMU/7NSCOhFUQvhbS', 'user', true, false, NULL),
  ('Valentina', 'Pérez', '1987-06-10', 'Otro', 'demo025@example.com', 'demo025', '$2b$12$VBUZ1Eexmj/JSanTBLXJeeInE0uvVb5hKVKGQMU/7NSCOhFUQvhbS', 'user', true, false, NULL);

INSERT INTO users (nombres, apellidos, fecha_nacimiento, genero, correo, usuario, contrasena_hash, rol, activo, mfa_enabled, mfa_secret_encrypted) VALUES
  ('David', 'Medina', '1989-06-03', 'F', 'demo026@example.com', 'demo026', '$2b$12$VBUZ1Eexmj/JSanTBLXJeeInE0uvVb5hKVKGQMU/7NSCOhFUQvhbS', 'user', true, false, NULL),
  ('Miguel', 'Herrera', '1990-07-23', 'F', 'demo027@example.com', 'demo027', '$2b$12$VBUZ1Eexmj/JSanTBLXJeeInE0uvVb5hKVKGQMU/7NSCOhFUQvhbS', 'user', true, false, NULL),
  ('Santiago', 'Torres', '1985-05-11', 'Otro', 'demo028@example.com', 'demo028', '$2b$12$VBUZ1Eexmj/JSanTBLXJeeInE0uvVb5hKVKGQMU/7NSCOhFUQvhbS', 'user', true, false, NULL),
  ('Natalia', 'Castro', '1991-04-24', 'F', 'demo029@example.com', 'demo029', '$2b$12$VBUZ1Eexmj/JSanTBLXJeeInE0uvVb5hKVKGQMU/7NSCOhFUQvhbS', 'user', true, false, NULL),
  ('Luis', 'Ortiz', '2002-10-06', 'F', 'demo030@example.com', 'demo030', '$2b$12$VBUZ1Eexmj/JSanTBLXJeeInE0uvVb5hKVKGQMU/7NSCOhFUQvhbS', 'user', true, false, NULL),
  ('Diego', 'Silva', '2002-09-14', 'Otro', 'demo031@example.com', 'demo031', '$2b$12$VBUZ1Eexmj/JSanTBLXJeeInE0uvVb5hKVKGQMU/7NSCOhFUQvhbS', 'user', true, false, NULL),
  ('Luis', 'Castro', '1994-10-08', 'Otro', 'demo032@example.com', 'demo032', '$2b$12$VBUZ1Eexmj/JSanTBLXJeeInE0uvVb5hKVKGQMU/7NSCOhFUQvhbS', 'user', true, false, NULL),
  ('Sebastián', 'Díaz', '1993-02-11', 'F', 'demo033@example.com', 'demo033', '$2b$12$VBUZ1Eexmj/JSanTBLXJeeInE0uvVb5hKVKGQMU/7NSCOhFUQvhbS', 'user', true, false, NULL),
  ('Carlos', 'Rodríguez', '1987-10-18', 'F', 'demo034@example.com', 'demo034', '$2b$12$VBUZ1Eexmj/JSanTBLXJeeInE0uvVb5hKVKGQMU/7NSCOhFUQvhbS', 'user', true, false, NULL),
  ('Paula', 'Castro', '1990-01-06', 'F', 'demo035@example.com', 'demo035', '$2b$12$VBUZ1Eexmj/JSanTBLXJeeInE0uvVb5hKVKGQMU/7NSCOhFUQvhbS', 'user', true, false, NULL),
  ('Juan', 'Medina', '1997-11-09', 'F', 'demo036@example.com', 'demo036', '$2b$12$VBUZ1Eexmj/JSanTBLXJeeInE0uvVb5hKVKGQMU/7NSCOhFUQvhbS', 'user', true, false, NULL),
  ('Catalina', 'Rodríguez', '1975-08-09', 'M', 'demo037@example.com', 'demo037', '$2b$12$VBUZ1Eexmj/JSanTBLXJeeInE0uvVb5hKVKGQMU/7NSCOhFUQvhbS', 'user', true, false, NULL),
  ('Carlos', 'Ruiz', '1983-08-23', 'M', 'demo038@example.com', 'demo038', '$2b$12$VBUZ1Eexmj/JSanTBLXJeeInE0uvVb5hKVKGQMU/7NSCOhFUQvhbS', 'user', true, false, NULL),
  ('Mateo', 'Pérez', '1978-07-19', 'F', 'demo039@example.com', 'demo039', '$2b$12$VBUZ1Eexmj/JSanTBLXJeeInE0uvVb5hKVKGQMU/7NSCOhFUQvhbS', 'user', true, false, NULL),
  ('Julián', 'Ruiz', '1975-02-26', 'Otro', 'demo040@example.com', 'demo040', '$2b$12$VBUZ1Eexmj/JSanTBLXJeeInE0uvVb5hKVKGQMU/7NSCOhFUQvhbS', 'user', true, false, NULL),
  ('Natalia', 'López', '1975-07-05', 'M', 'demo041@example.com', 'demo041', '$2b$12$VBUZ1Eexmj/JSanTBLXJeeInE0uvVb5hKVKGQMU/7NSCOhFUQvhbS', 'user', true, false, NULL),
  ('Lucía', 'Castro', '1991-08-18', 'Otro', 'demo042@example.com', 'demo042', '$2b$12$VBUZ1Eexmj/JSanTBLXJeeInE0uvVb5hKVKGQMU/7NSCOhFUQvhbS', 'user', true, false, NULL),
  ('Sofía', 'López', '1981-12-19', 'F', 'demo043@example.com', 'demo043', '$2b$12$VBUZ1Eexmj/JSanTBLXJeeInE0uvVb5hKVKGQMU/7NSCOhFUQvhbS', 'user', true, false, NULL),
  ('Paula', 'Pérez', '1995-07-01', 'M', 'demo044@example.com', 'demo044', '$2b$12$VBUZ1Eexmj/JSanTBLXJeeInE0uvVb5hKVKGQMU/7NSCOhFUQvhbS', 'user', true, false, NULL),
  ('Lucía', 'Sánchez', '1988-09-26', 'Otro', 'demo045@example.com', 'demo045', '$2b$12$VBUZ1Eexmj/JSanTBLXJeeInE0uvVb5hKVKGQMU/7NSCOhFUQvhbS', 'user', true, false, NULL),
  ('Manuela', 'Guerrero', '1983-04-10', 'M', 'demo046@example.com', 'demo046', '$2b$12$VBUZ1Eexmj/JSanTBLXJeeInE0uvVb5hKVKGQMU/7NSCOhFUQvhbS', 'user', true, false, NULL),
  ('Laura', 'Vargas', '1996-04-27', 'M', 'demo047@example.com', 'demo047', '$2b$12$VBUZ1Eexmj/JSanTBLXJeeInE0uvVb5hKVKGQMU/7NSCOhFUQvhbS', 'user', true, false, NULL),
  ('David', 'Medina', '1998-02-07', 'M', 'demo048@example.com', 'demo048', '$2b$12$VBUZ1Eexmj/JSanTBLXJeeInE0uvVb5hKVKGQMU/7NSCOhFUQvhbS', 'user', true, false, NULL),
  ('Diego', 'Reyes', '1999-10-26', 'Otro', 'demo049@example.com', 'demo049', '$2b$12$VBUZ1Eexmj/JSanTBLXJeeInE0uvVb5hKVKGQMU/7NSCOhFUQvhbS', 'user', true, false, NULL),
  ('María', 'Ramírez', '1980-08-03', 'Otro', 'demo050@example.com', 'demo050', '$2b$12$VBUZ1Eexmj/JSanTBLXJeeInE0uvVb5hKVKGQMU/7NSCOhFUQvhbS', 'user', true, false, NULL);

INSERT INTO users (nombres, apellidos, fecha_nacimiento, genero, correo, usuario, contrasena_hash, rol, activo, mfa_enabled, mfa_secret_encrypted) VALUES
  ('Sara', 'Rivera', '1992-06-28', 'F', 'demo051@example.com', 'demo051', '$2b$12$VBUZ1Eexmj/JSanTBLXJeeInE0uvVb5hKVKGQMU/7NSCOhFUQvhbS', 'user', true, false, NULL),
  ('Laura', 'Rivera', '1977-08-19', 'Otro', 'demo052@example.com', 'demo052', '$2b$12$VBUZ1Eexmj/JSanTBLXJeeInE0uvVb5hKVKGQMU/7NSCOhFUQvhbS', 'user', true, false, NULL),
  ('María', 'Aguilar', '1987-09-22', 'Otro', 'demo053@example.com', 'demo053', '$2b$12$VBUZ1Eexmj/JSanTBLXJeeInE0uvVb5hKVKGQMU/7NSCOhFUQvhbS', 'user', true, false, NULL),
  ('Miguel', 'Díaz', '1999-01-20', 'Otro', 'demo054@example.com', 'demo054', '$2b$12$VBUZ1Eexmj/JSanTBLXJeeInE0uvVb5hKVKGQMU/7NSCOhFUQvhbS', 'user', true, false, NULL),
  ('Paula', 'Herrera', '1990-08-14', 'F', 'demo055@example.com', 'demo055', '$2b$12$VBUZ1Eexmj/JSanTBLXJeeInE0uvVb5hKVKGQMU/7NSCOhFUQvhbS', 'user', true, false, NULL),
  ('Nicolás', 'Herrera', '1990-08-26', 'M', 'demo056@example.com', 'demo056', '$2b$12$VBUZ1Eexmj/JSanTBLXJeeInE0uvVb5hKVKGQMU/7NSCOhFUQvhbS', 'user', true, false, NULL),
  ('Juan', 'Castro', '1985-09-15', 'M', 'demo057@example.com', 'demo057', '$2b$12$VBUZ1Eexmj/JSanTBLXJeeInE0uvVb5hKVKGQMU/7NSCOhFUQvhbS', 'user', true, false, NULL),
  ('Julián', 'Sánchez', '1996-03-16', 'M', 'demo058@example.com', 'demo058', '$2b$12$VBUZ1Eexmj/JSanTBLXJeeInE0uvVb5hKVKGQMU/7NSCOhFUQvhbS', 'user', true, false, NULL),
  ('Sofía', 'Torres', '1979-10-09', 'F', 'demo059@example.com', 'demo059', '$2b$12$VBUZ1Eexmj/JSanTBLXJeeInE0uvVb5hKVKGQMU/7NSCOhFUQvhbS', 'user', true, false, NULL),
  ('Andrés', 'Rivera', '1992-01-22', 'M', 'demo060@example.com', 'demo060', '$2b$12$VBUZ1Eexmj/JSanTBLXJeeInE0uvVb5hKVKGQMU/7NSCOhFUQvhbS', 'user', true, false, NULL),
  ('Isabella', 'Herrera', '1981-05-23', 'F', 'demo061@example.com', 'demo061', '$2b$12$VBUZ1Eexmj/JSanTBLXJeeInE0uvVb5hKVKGQMU/7NSCOhFUQvhbS', 'user', true, false, NULL),
  ('Felipe', 'Martínez', '1995-05-12', 'F', 'demo062@example.com', 'demo062', '$2b$12$VBUZ1Eexmj/JSanTBLXJeeInE0uvVb5hKVKGQMU/7NSCOhFUQvhbS', 'user', true, false, NULL),
  ('Luis', 'Medina', '1993-01-09', 'M', 'demo063@example.com', 'demo063', '$2b$12$VBUZ1Eexmj/JSanTBLXJeeInE0uvVb5hKVKGQMU/7NSCOhFUQvhbS', 'user', true, false, NULL),
  ('Carlos', 'Díaz', '1986-08-20', 'M', 'demo064@example.com', 'demo064', '$2b$12$VBUZ1Eexmj/JSanTBLXJeeInE0uvVb5hKVKGQMU/7NSCOhFUQvhbS', 'user', true, false, NULL),
  ('David', 'Ortiz', '1976-03-22', 'Otro', 'demo065@example.com', 'demo065', '$2b$12$VBUZ1Eexmj/JSanTBLXJeeInE0uvVb5hKVKGQMU/7NSCOhFUQvhbS', 'user', true, false, NULL),
  ('Manuela', 'Medina', '1986-02-18', 'Otro', 'demo066@example.com', 'demo066', '$2b$12$VBUZ1Eexmj/JSanTBLXJeeInE0uvVb5hKVKGQMU/7NSCOhFUQvhbS', 'user', true, false, NULL),
  ('Ana', 'Martínez', '1979-12-09', 'Otro', 'demo067@example.com', 'demo067', '$2b$12$VBUZ1Eexmj/JSanTBLXJeeInE0uvVb5hKVKGQMU/7NSCOhFUQvhbS', 'user', true, false, NULL),
  ('Gabriel', 'Navarro', '1992-09-01', 'M', 'demo068@example.com', 'demo068', '$2b$12$VBUZ1Eexmj/JSanTBLXJeeInE0uvVb5hKVKGQMU/7NSCOhFUQvhbS', 'user', true, false, NULL),
  ('Diego', 'González', '1998-11-25', 'F', 'demo069@example.com', 'demo069', '$2b$12$VBUZ1Eexmj/JSanTBLXJeeInE0uvVb5hKVKGQMU/7NSCOhFUQvhbS', 'user', true, false, NULL),
  ('Manuela', 'Gómez', '2001-05-01', 'Otro', 'demo070@example.com', 'demo070', '$2b$12$VBUZ1Eexmj/JSanTBLXJeeInE0uvVb5hKVKGQMU/7NSCOhFUQvhbS', 'user', true, false, NULL),
  ('Santiago', 'López', '1982-12-07', 'M', 'demo071@example.com', 'demo071', '$2b$12$VBUZ1Eexmj/JSanTBLXJeeInE0uvVb5hKVKGQMU/7NSCOhFUQvhbS', 'user', true, false, NULL),
  ('Andrés', 'Rivera', '1998-08-25', 'M', 'demo072@example.com', 'demo072', '$2b$12$VBUZ1Eexmj/JSanTBLXJeeInE0uvVb5hKVKGQMU/7NSCOhFUQvhbS', 'user', true, false, NULL),
  ('Catalina', 'González', '1978-05-16', 'F', 'demo073@example.com', 'demo073', '$2b$12$VBUZ1Eexmj/JSanTBLXJeeInE0uvVb5hKVKGQMU/7NSCOhFUQvhbS', 'user', true, false, NULL),
  ('Ana', 'López', '1980-03-24', 'Otro', 'demo074@example.com', 'demo074', '$2b$12$VBUZ1Eexmj/JSanTBLXJeeInE0uvVb5hKVKGQMU/7NSCOhFUQvhbS', 'user', true, false, NULL),
  ('Pedro', 'Rivera', '2001-03-04', 'M', 'demo075@example.com', 'demo075', '$2b$12$VBUZ1Eexmj/JSanTBLXJeeInE0uvVb5hKVKGQMU/7NSCOhFUQvhbS', 'user', true, false, NULL);

INSERT INTO users (nombres, apellidos, fecha_nacimiento, genero, correo, usuario, contrasena_hash, rol, activo, mfa_enabled, mfa_secret_encrypted) VALUES
  ('Diego', 'Mendoza', '1998-10-19', 'Otro', 'demo076@example.com', 'demo076', '$2b$12$VBUZ1Eexmj/JSanTBLXJeeInE0uvVb5hKVKGQMU/7NSCOhFUQvhbS', 'user', true, false, NULL),
  ('Julián', 'Pérez', '1975-05-26', 'M', 'demo077@example.com', 'demo077', '$2b$12$VBUZ1Eexmj/JSanTBLXJeeInE0uvVb5hKVKGQMU/7NSCOhFUQvhbS', 'user', true, false, NULL),
  ('Daniela', 'García', '1982-12-01', 'F', 'demo078@example.com', 'demo078', '$2b$12$VBUZ1Eexmj/JSanTBLXJeeInE0uvVb5hKVKGQMU/7NSCOhFUQvhbS', 'user', true, false, NULL),
  ('Sebastián', 'Rodríguez', '1992-01-10', 'F', 'demo079@example.com', 'demo079', '$2b$12$VBUZ1Eexmj/JSanTBLXJeeInE0uvVb5hKVKGQMU/7NSCOhFUQvhbS', 'user', true, false, NULL),
  ('Sofía', 'Romero', '1978-01-27', 'Otro', 'demo080@example.com', 'demo080', '$2b$12$VBUZ1Eexmj/JSanTBLXJeeInE0uvVb5hKVKGQMU/7NSCOhFUQvhbS', 'user', true, false, NULL),
  ('Daniela', 'Morales', '1988-07-12', 'F', 'demo081@example.com', 'demo081', '$2b$12$VBUZ1Eexmj/JSanTBLXJeeInE0uvVb5hKVKGQMU/7NSCOhFUQvhbS', 'user', true, false, NULL),
  ('Camila', 'Ortiz', '1978-06-19', 'F', 'demo082@example.com', 'demo082', '$2b$12$VBUZ1Eexmj/JSanTBLXJeeInE0uvVb5hKVKGQMU/7NSCOhFUQvhbS', 'user', true, false, NULL),
  ('Sebastián', 'Ramírez', '1997-08-05', 'F', 'demo083@example.com', 'demo083', '$2b$12$VBUZ1Eexmj/JSanTBLXJeeInE0uvVb5hKVKGQMU/7NSCOhFUQvhbS', 'user', true, false, NULL),
  ('Miguel', 'Flores', '1999-10-16', 'M', 'demo084@example.com', 'demo084', '$2b$12$VBUZ1Eexmj/JSanTBLXJeeInE0uvVb5hKVKGQMU/7NSCOhFUQvhbS', 'user', true, false, NULL),
  ('Manuela', 'Ortiz', '1981-03-07', 'M', 'demo085@example.com', 'demo085', '$2b$12$VBUZ1Eexmj/JSanTBLXJeeInE0uvVb5hKVKGQMU/7NSCOhFUQvhbS', 'user', true, false, NULL),
  ('Ana', 'López', '1977-12-14', 'Otro', 'demo086@example.com', 'demo086', '$2b$12$VBUZ1Eexmj/JSanTBLXJeeInE0uvVb5hKVKGQMU/7NSCOhFUQvhbS', 'user', true, false, NULL),
  ('Catalina', 'Guerrero', '1985-01-21', 'F', 'demo087@example.com', 'demo087', '$2b$12$VBUZ1Eexmj/JSanTBLXJeeInE0uvVb5hKVKGQMU/7NSCOhFUQvhbS', 'user', true, false, NULL),
  ('Manuela', 'Díaz', '1976-06-05', 'Otro', 'demo088@example.com', 'demo088', '$2b$12$VBUZ1Eexmj/JSanTBLXJeeInE0uvVb5hKVKGQMU/7NSCOhFUQvhbS', 'user', true, false, NULL),
  ('Paula', 'Sánchez', '1995-03-03', 'Otro', 'demo089@example.com', 'demo089', '$2b$12$VBUZ1Eexmj/JSanTBLXJeeInE0uvVb5hKVKGQMU/7NSCOhFUQvhbS', 'user', true, false, NULL),
  ('Sebastián', 'González', '1979-07-19', 'Otro', 'demo090@example.com', 'demo090', '$2b$12$VBUZ1Eexmj/JSanTBLXJeeInE0uvVb5hKVKGQMU/7NSCOhFUQvhbS', 'user', true, false, NULL),
  ('Sara', 'Castro', '2002-08-02', 'F', 'demo091@example.com', 'demo091', '$2b$12$VBUZ1Eexmj/JSanTBLXJeeInE0uvVb5hKVKGQMU/7NSCOhFUQvhbS', 'user', true, false, NULL),
  ('David', 'García', '1988-08-10', 'F', 'demo092@example.com', 'demo092', '$2b$12$VBUZ1Eexmj/JSanTBLXJeeInE0uvVb5hKVKGQMU/7NSCOhFUQvhbS', 'user', true, false, NULL),
  ('Camila', 'Ruiz', '1998-03-02', 'M', 'demo093@example.com', 'demo093', '$2b$12$VBUZ1Eexmj/JSanTBLXJeeInE0uvVb5hKVKGQMU/7NSCOhFUQvhbS', 'user', true, false, NULL),
  ('Miguel', 'Ramírez', '1989-11-13', 'M', 'demo094@example.com', 'demo094', '$2b$12$VBUZ1Eexmj/JSanTBLXJeeInE0uvVb5hKVKGQMU/7NSCOhFUQvhbS', 'user', true, false, NULL),
  ('María', 'Vargas', '1997-07-17', 'Otro', 'demo095@example.com', 'demo095', '$2b$12$VBUZ1Eexmj/JSanTBLXJeeInE0uvVb5hKVKGQMU/7NSCOhFUQvhbS', 'user', true, false, NULL),
  ('Santiago', 'Rivera', '1995-11-13', 'F', 'demo096@example.com', 'demo096', '$2b$12$VBUZ1Eexmj/JSanTBLXJeeInE0uvVb5hKVKGQMU/7NSCOhFUQvhbS', 'user', true, false, NULL),
  ('Laura', 'Rojas', '2002-05-18', 'M', 'demo097@example.com', 'demo097', '$2b$12$VBUZ1Eexmj/JSanTBLXJeeInE0uvVb5hKVKGQMU/7NSCOhFUQvhbS', 'user', true, false, NULL),
  ('Isabella', 'Martínez', '1984-12-15', 'F', 'demo098@example.com', 'demo098', '$2b$12$VBUZ1Eexmj/JSanTBLXJeeInE0uvVb5hKVKGQMU/7NSCOhFUQvhbS', 'user', true, false, NULL),
  ('Manuela', 'Castro', '2002-02-03', 'M', 'demo099@example.com', 'demo099', '$2b$12$VBUZ1Eexmj/JSanTBLXJeeInE0uvVb5hKVKGQMU/7NSCOhFUQvhbS', 'user', true, false, NULL),
  ('Julián', 'Guerrero', '1982-12-25', 'F', 'demo100@example.com', 'demo100', '$2b$12$VBUZ1Eexmj/JSanTBLXJeeInE0uvVb5hKVKGQMU/7NSCOhFUQvhbS', 'user', true, false, NULL);

-- Accounts (multi-row via VALUES + join users)
INSERT INTO accounts (user_id, banco, tipo, moneda, saldo, activo)
SELECT u.id, v.banco, v.tipo, v.moneda, v.saldo::numeric, true
FROM (VALUES
  ('demo001', 'Nequi', 'ahorros', 'COP', 350000.00),
  ('demo001', 'Bancolombia', 'corriente', 'COP', 350000.00),
  ('demo001', 'Efectivo', 'efectivo', 'COP', 200000.00),
  ('demo002', 'Davivienda', 'corriente', 'COP', 350000.00),
  ('demo002', 'Nequi', 'ahorros', 'COP', 50000.00),
  ('demo002', 'Banco de Bogotá', 'ahorros', 'COP', 50000.00),
  ('demo002', 'Efectivo', 'efectivo', 'COP', 500000.00),
  ('demo003', 'Bancolombia', 'digital', 'COP', 100000.00),
  ('demo003', 'Nequi', 'ahorros', 'COP', 200000.00),
  ('demo003', 'Banco de Bogotá', 'ahorros', 'COP', 200000.00),
  ('demo003', 'Efectivo', 'efectivo', 'COP', 300000.00),
  ('demo004', 'Nequi', 'digital', 'COP', 350000.00),
  ('demo004', 'BBVA', 'ahorros', 'COP', 350000.00),
  ('demo004', 'Davivienda', 'corriente', 'COP', 350000.00),
  ('demo005', 'Daviplata', 'ahorros', 'COP', 50000.00),
  ('demo005', 'Banco de Bogotá', 'ahorros', 'COP', 150000.00),
  ('demo005', 'Davivienda', 'corriente', 'COP', 350000.00),
  ('demo005', 'Efectivo', 'efectivo', 'COP', 500000.00),
  ('demo006', 'Daviplata', 'corriente', 'COP', 350000.00),
  ('demo006', 'Davivienda', 'corriente', 'COP', 100000.00),
  ('demo006', 'Efectivo', 'efectivo', 'COP', 400000.00),
  ('demo007', 'Daviplata', 'ahorros', 'COP', 350000.00),
  ('demo007', 'Banco de Bogotá', 'digital', 'COP', 150000.00),
  ('demo007', 'Bancolombia', 'digital', 'COP', 200000.00),
  ('demo007', 'Efectivo', 'efectivo', 'COP', 400000.00),
  ('demo008', 'Nequi', 'ahorros', 'COP', 150000.00),
  ('demo008', 'Davivienda', 'ahorros', 'COP', 350000.00),
  ('demo008', 'Daviplata', 'ahorros', 'COP', 150000.00),
  ('demo009', 'BBVA', 'digital', 'COP', 150000.00),
  ('demo009', 'Bancolombia', 'corriente', 'COP', 200000.00),
  ('demo009', 'Daviplata', 'digital', 'COP', 350000.00),
  ('demo009', 'Efectivo', 'efectivo', 'COP', 200000.00),
  ('demo010', 'BBVA', 'ahorros', 'COP', 50000.00),
  ('demo010', 'Nequi', 'digital', 'COP', 350000.00),
  ('demo010', 'Daviplata', 'ahorros', 'COP', 150000.00),
  ('demo011', 'Banco de Bogotá', 'digital', 'COP', 100000.00),
  ('demo011', 'Davivienda', 'digital', 'COP', 50000.00),
  ('demo011', 'Efectivo', 'efectivo', 'COP', 400000.00),
  ('demo012', 'Daviplata', 'corriente', 'COP', 200000.00),
  ('demo012', 'Bancolombia', 'digital', 'COP', 150000.00),
  ('demo012', 'Efectivo', 'efectivo', 'COP', 500000.00),
  ('demo013', 'BBVA', 'corriente', 'COP', 100000.00),
  ('demo013', 'Daviplata', 'digital', 'COP', 150000.00),
  ('demo013', 'Davivienda', 'digital', 'COP', 150000.00),
  ('demo013', 'Efectivo', 'efectivo', 'COP', 200000.00),
  ('demo014', 'BBVA', 'ahorros', 'COP', 350000.00),
  ('demo014', 'Davivienda', 'digital', 'COP', 150000.00),
  ('demo014', 'Banco de Bogotá', 'corriente', 'COP', 50000.00),
  ('demo014', 'Efectivo', 'efectivo', 'COP', 200000.00),
  ('demo015', 'Davivienda', 'corriente', 'COP', 100000.00)
) AS v(usuario, banco, tipo, moneda, saldo)
JOIN users u ON u.usuario = v.usuario;

INSERT INTO accounts (user_id, banco, tipo, moneda, saldo, activo)
SELECT u.id, v.banco, v.tipo, v.moneda, v.saldo::numeric, true
FROM (VALUES
  ('demo015', 'BBVA', 'corriente', 'COP', 350000.00),
  ('demo015', 'Efectivo', 'efectivo', 'COP', 400000.00),
  ('demo016', 'BBVA', 'digital', 'COP', 50000.00),
  ('demo016', 'Daviplata', 'corriente', 'COP', 200000.00),
  ('demo016', 'Efectivo', 'efectivo', 'COP', 200000.00),
  ('demo017', 'Daviplata', 'corriente', 'COP', 150000.00),
  ('demo017', 'BBVA', 'ahorros', 'COP', 200000.00),
  ('demo017', 'Efectivo', 'efectivo', 'COP', 400000.00),
  ('demo018', 'Bancolombia', 'corriente', 'COP', 350000.00),
  ('demo018', 'Davivienda', 'digital', 'COP', 100000.00),
  ('demo018', 'Nequi', 'digital', 'COP', 150000.00),
  ('demo018', 'Efectivo', 'efectivo', 'COP', 300000.00),
  ('demo019', 'Daviplata', 'ahorros', 'COP', 200000.00),
  ('demo019', 'Banco de Bogotá', 'corriente', 'COP', 150000.00),
  ('demo019', 'Davivienda', 'corriente', 'COP', 50000.00),
  ('demo019', 'Efectivo', 'efectivo', 'COP', 200000.00),
  ('demo020', 'Banco de Bogotá', 'corriente', 'COP', 150000.00),
  ('demo020', 'Daviplata', 'digital', 'COP', 200000.00),
  ('demo020', 'Bancolombia', 'digital', 'COP', 350000.00),
  ('demo020', 'Efectivo', 'efectivo', 'COP', 300000.00),
  ('demo021', 'Bancolombia', 'corriente', 'COP', 50000.00),
  ('demo021', 'Nequi', 'digital', 'COP', 150000.00),
  ('demo021', 'Daviplata', 'digital', 'COP', 50000.00),
  ('demo022', 'Banco de Bogotá', 'digital', 'COP', 150000.00),
  ('demo022', 'BBVA', 'digital', 'COP', 200000.00),
  ('demo022', 'Bancolombia', 'digital', 'COP', 150000.00),
  ('demo022', 'Efectivo', 'efectivo', 'COP', 300000.00),
  ('demo023', 'Davivienda', 'digital', 'COP', 350000.00),
  ('demo023', 'Banco de Bogotá', 'corriente', 'COP', 200000.00),
  ('demo023', 'Efectivo', 'efectivo', 'COP', 400000.00),
  ('demo024', 'Davivienda', 'corriente', 'COP', 200000.00),
  ('demo024', 'Bancolombia', 'corriente', 'COP', 100000.00),
  ('demo024', 'Daviplata', 'corriente', 'COP', 350000.00),
  ('demo024', 'Efectivo', 'efectivo', 'COP', 500000.00),
  ('demo025', 'Banco de Bogotá', 'corriente', 'COP', 200000.00),
  ('demo025', 'Nequi', 'corriente', 'COP', 200000.00),
  ('demo025', 'Davivienda', 'digital', 'COP', 50000.00),
  ('demo025', 'Efectivo', 'efectivo', 'COP', 300000.00),
  ('demo026', 'Daviplata', 'corriente', 'COP', 50000.00),
  ('demo026', 'Bancolombia', 'digital', 'COP', 50000.00),
  ('demo027', 'Nequi', 'corriente', 'COP', 100000.00),
  ('demo027', 'Bancolombia', 'corriente', 'COP', 50000.00),
  ('demo027', 'Banco de Bogotá', 'digital', 'COP', 100000.00),
  ('demo027', 'Efectivo', 'efectivo', 'COP', 500000.00),
  ('demo028', 'Banco de Bogotá', 'digital', 'COP', 150000.00),
  ('demo028', 'BBVA', 'ahorros', 'COP', 50000.00),
  ('demo028', 'Efectivo', 'efectivo', 'COP', 500000.00),
  ('demo029', 'Daviplata', 'corriente', 'COP', 200000.00),
  ('demo029', 'Bancolombia', 'ahorros', 'COP', 50000.00),
  ('demo029', 'Nequi', 'digital', 'COP', 200000.00)
) AS v(usuario, banco, tipo, moneda, saldo)
JOIN users u ON u.usuario = v.usuario;

INSERT INTO accounts (user_id, banco, tipo, moneda, saldo, activo)
SELECT u.id, v.banco, v.tipo, v.moneda, v.saldo::numeric, true
FROM (VALUES
  ('demo029', 'Efectivo', 'efectivo', 'COP', 200000.00),
  ('demo030', 'Davivienda', 'digital', 'COP', 350000.00),
  ('demo030', 'Bancolombia', 'ahorros', 'COP', 50000.00),
  ('demo031', 'BBVA', 'ahorros', 'COP', 350000.00),
  ('demo031', 'Bancolombia', 'ahorros', 'COP', 200000.00),
  ('demo031', 'Banco de Bogotá', 'digital', 'COP', 350000.00),
  ('demo031', 'Efectivo', 'efectivo', 'COP', 300000.00),
  ('demo032', 'BBVA', 'ahorros', 'COP', 50000.00),
  ('demo032', 'Daviplata', 'corriente', 'COP', 150000.00),
  ('demo032', 'Banco de Bogotá', 'corriente', 'COP', 100000.00),
  ('demo032', 'Efectivo', 'efectivo', 'COP', 300000.00),
  ('demo033', 'Nequi', 'digital', 'COP', 200000.00),
  ('demo033', 'Daviplata', 'ahorros', 'COP', 150000.00),
  ('demo033', 'BBVA', 'digital', 'COP', 350000.00),
  ('demo034', 'Bancolombia', 'corriente', 'COP', 50000.00),
  ('demo034', 'Davivienda', 'corriente', 'COP', 50000.00),
  ('demo035', 'Nequi', 'corriente', 'COP', 50000.00),
  ('demo035', 'Banco de Bogotá', 'digital', 'COP', 150000.00),
  ('demo035', 'BBVA', 'ahorros', 'COP', 100000.00),
  ('demo036', 'Davivienda', 'corriente', 'COP', 100000.00),
  ('demo036', 'BBVA', 'digital', 'COP', 150000.00),
  ('demo036', 'Daviplata', 'digital', 'COP', 350000.00),
  ('demo036', 'Efectivo', 'efectivo', 'COP', 200000.00),
  ('demo037', 'Banco de Bogotá', 'ahorros', 'COP', 200000.00),
  ('demo037', 'Nequi', 'digital', 'COP', 100000.00),
  ('demo037', 'Efectivo', 'efectivo', 'COP', 500000.00),
  ('demo038', 'Daviplata', 'corriente', 'COP', 150000.00),
  ('demo038', 'Bancolombia', 'digital', 'COP', 50000.00),
  ('demo038', 'Efectivo', 'efectivo', 'COP', 300000.00),
  ('demo039', 'Nequi', 'digital', 'COP', 150000.00),
  ('demo039', 'Banco de Bogotá', 'digital', 'COP', 50000.00),
  ('demo039', 'BBVA', 'corriente', 'COP', 100000.00),
  ('demo040', 'Banco de Bogotá', 'corriente', 'COP', 200000.00),
  ('demo040', 'Daviplata', 'ahorros', 'COP', 150000.00),
  ('demo040', 'Nequi', 'corriente', 'COP', 100000.00),
  ('demo040', 'Efectivo', 'efectivo', 'COP', 500000.00),
  ('demo041', 'Nequi', 'corriente', 'COP', 100000.00),
  ('demo041', 'Davivienda', 'ahorros', 'COP', 150000.00),
  ('demo042', 'Bancolombia', 'ahorros', 'COP', 200000.00),
  ('demo042', 'Davivienda', 'digital', 'COP', 350000.00),
  ('demo042', 'Efectivo', 'efectivo', 'COP', 200000.00),
  ('demo043', 'Davivienda', 'corriente', 'COP', 50000.00),
  ('demo043', 'Nequi', 'ahorros', 'COP', 350000.00),
  ('demo043', 'Banco de Bogotá', 'corriente', 'COP', 100000.00),
  ('demo043', 'Efectivo', 'efectivo', 'COP', 400000.00),
  ('demo044', 'Nequi', 'ahorros', 'COP', 350000.00),
  ('demo044', 'Banco de Bogotá', 'digital', 'COP', 100000.00),
  ('demo044', 'Efectivo', 'efectivo', 'COP', 300000.00),
  ('demo045', 'Nequi', 'corriente', 'COP', 150000.00),
  ('demo045', 'Davivienda', 'corriente', 'COP', 350000.00)
) AS v(usuario, banco, tipo, moneda, saldo)
JOIN users u ON u.usuario = v.usuario;

INSERT INTO accounts (user_id, banco, tipo, moneda, saldo, activo)
SELECT u.id, v.banco, v.tipo, v.moneda, v.saldo::numeric, true
FROM (VALUES
  ('demo045', 'BBVA', 'digital', 'COP', 200000.00),
  ('demo045', 'Efectivo', 'efectivo', 'COP', 200000.00),
  ('demo046', 'Daviplata', 'ahorros', 'COP', 350000.00),
  ('demo046', 'Davivienda', 'corriente', 'COP', 200000.00),
  ('demo046', 'Bancolombia', 'ahorros', 'COP', 150000.00),
  ('demo047', 'Nequi', 'ahorros', 'COP', 200000.00),
  ('demo047', 'Banco de Bogotá', 'digital', 'COP', 100000.00),
  ('demo047', 'BBVA', 'corriente', 'COP', 100000.00),
  ('demo048', 'Bancolombia', 'digital', 'COP', 200000.00),
  ('demo048', 'Daviplata', 'ahorros', 'COP', 50000.00),
  ('demo048', 'Banco de Bogotá', 'digital', 'COP', 200000.00),
  ('demo049', 'Davivienda', 'ahorros', 'COP', 200000.00),
  ('demo049', 'Banco de Bogotá', 'ahorros', 'COP', 50000.00),
  ('demo049', 'Daviplata', 'corriente', 'COP', 100000.00),
  ('demo049', 'Efectivo', 'efectivo', 'COP', 500000.00),
  ('demo050', 'Daviplata', 'digital', 'COP', 150000.00),
  ('demo050', 'Bancolombia', 'digital', 'COP', 100000.00),
  ('demo050', 'Banco de Bogotá', 'ahorros', 'COP', 350000.00),
  ('demo050', 'Efectivo', 'efectivo', 'COP', 300000.00),
  ('demo051', 'Daviplata', 'ahorros', 'COP', 350000.00),
  ('demo051', 'BBVA', 'digital', 'COP', 350000.00),
  ('demo051', 'Davivienda', 'corriente', 'COP', 100000.00),
  ('demo052', 'Banco de Bogotá', 'ahorros', 'COP', 150000.00),
  ('demo052', 'BBVA', 'digital', 'COP', 200000.00),
  ('demo052', 'Efectivo', 'efectivo', 'COP', 300000.00),
  ('demo053', 'BBVA', 'ahorros', 'COP', 350000.00),
  ('demo053', 'Nequi', 'corriente', 'COP', 200000.00),
  ('demo054', 'Daviplata', 'digital', 'COP', 350000.00),
  ('demo054', 'Davivienda', 'digital', 'COP', 350000.00),
  ('demo054', 'BBVA', 'digital', 'COP', 350000.00),
  ('demo054', 'Efectivo', 'efectivo', 'COP', 200000.00),
  ('demo055', 'Banco de Bogotá', 'ahorros', 'COP', 50000.00),
  ('demo055', 'Daviplata', 'corriente', 'COP', 350000.00),
  ('demo055', 'Efectivo', 'efectivo', 'COP', 300000.00),
  ('demo056', 'BBVA', 'digital', 'COP', 200000.00),
  ('demo056', 'Nequi', 'corriente', 'COP', 150000.00),
  ('demo057', 'Bancolombia', 'ahorros', 'COP', 50000.00),
  ('demo057', 'BBVA', 'ahorros', 'COP', 200000.00),
  ('demo057', 'Efectivo', 'efectivo', 'COP', 500000.00),
  ('demo058', 'Banco de Bogotá', 'corriente', 'COP', 150000.00),
  ('demo058', 'BBVA', 'corriente', 'COP', 100000.00),
  ('demo059', 'Bancolombia', 'digital', 'COP', 350000.00),
  ('demo059', 'Daviplata', 'digital', 'COP', 100000.00),
  ('demo059', 'Nequi', 'corriente', 'COP', 200000.00),
  ('demo060', 'Bancolombia', 'digital', 'COP', 50000.00),
  ('demo060', 'BBVA', 'digital', 'COP', 50000.00),
  ('demo060', 'Efectivo', 'efectivo', 'COP', 300000.00),
  ('demo061', 'Daviplata', 'ahorros', 'COP', 200000.00),
  ('demo061', 'Davivienda', 'digital', 'COP', 200000.00),
  ('demo061', 'Efectivo', 'efectivo', 'COP', 200000.00)
) AS v(usuario, banco, tipo, moneda, saldo)
JOIN users u ON u.usuario = v.usuario;

INSERT INTO accounts (user_id, banco, tipo, moneda, saldo, activo)
SELECT u.id, v.banco, v.tipo, v.moneda, v.saldo::numeric, true
FROM (VALUES
  ('demo062', 'Banco de Bogotá', 'ahorros', 'COP', 100000.00),
  ('demo062', 'Nequi', 'ahorros', 'COP', 350000.00),
  ('demo062', 'Efectivo', 'efectivo', 'COP', 300000.00),
  ('demo063', 'BBVA', 'ahorros', 'COP', 200000.00),
  ('demo063', 'Daviplata', 'ahorros', 'COP', 150000.00),
  ('demo064', 'Davivienda', 'digital', 'COP', 350000.00),
  ('demo064', 'Nequi', 'ahorros', 'COP', 100000.00),
  ('demo064', 'Bancolombia', 'ahorros', 'COP', 150000.00),
  ('demo064', 'Efectivo', 'efectivo', 'COP', 500000.00),
  ('demo065', 'Davivienda', 'digital', 'COP', 200000.00),
  ('demo065', 'Bancolombia', 'corriente', 'COP', 100000.00),
  ('demo065', 'Efectivo', 'efectivo', 'COP', 400000.00),
  ('demo066', 'Nequi', 'corriente', 'COP', 350000.00),
  ('demo066', 'Bancolombia', 'corriente', 'COP', 150000.00),
  ('demo066', 'Daviplata', 'corriente', 'COP', 200000.00),
  ('demo067', 'Davivienda', 'digital', 'COP', 350000.00),
  ('demo067', 'Nequi', 'ahorros', 'COP', 50000.00),
  ('demo067', 'Banco de Bogotá', 'ahorros', 'COP', 350000.00),
  ('demo067', 'Efectivo', 'efectivo', 'COP', 300000.00),
  ('demo068', 'Bancolombia', 'corriente', 'COP', 150000.00),
  ('demo068', 'BBVA', 'corriente', 'COP', 200000.00),
  ('demo068', 'Banco de Bogotá', 'ahorros', 'COP', 50000.00),
  ('demo068', 'Efectivo', 'efectivo', 'COP', 400000.00),
  ('demo069', 'BBVA', 'corriente', 'COP', 100000.00),
  ('demo069', 'Davivienda', 'corriente', 'COP', 150000.00),
  ('demo069', 'Bancolombia', 'corriente', 'COP', 100000.00),
  ('demo069', 'Efectivo', 'efectivo', 'COP', 300000.00),
  ('demo070', 'Daviplata', 'corriente', 'COP', 100000.00),
  ('demo070', 'Bancolombia', 'corriente', 'COP', 350000.00),
  ('demo070', 'Efectivo', 'efectivo', 'COP', 400000.00),
  ('demo071', 'Davivienda', 'corriente', 'COP', 100000.00),
  ('demo071', 'BBVA', 'digital', 'COP', 100000.00),
  ('demo071', 'Banco de Bogotá', 'corriente', 'COP', 100000.00),
  ('demo072', 'Bancolombia', 'ahorros', 'COP', 50000.00),
  ('demo072', 'Nequi', 'ahorros', 'COP', 100000.00),
  ('demo072', 'Banco de Bogotá', 'corriente', 'COP', 200000.00),
  ('demo072', 'Efectivo', 'efectivo', 'COP', 500000.00),
  ('demo073', 'Daviplata', 'digital', 'COP', 150000.00),
  ('demo073', 'Banco de Bogotá', 'corriente', 'COP', 50000.00),
  ('demo073', 'Nequi', 'ahorros', 'COP', 350000.00),
  ('demo073', 'Efectivo', 'efectivo', 'COP', 500000.00),
  ('demo074', 'BBVA', 'digital', 'COP', 200000.00),
  ('demo074', 'Daviplata', 'ahorros', 'COP', 100000.00),
  ('demo074', 'Bancolombia', 'digital', 'COP', 150000.00),
  ('demo075', 'BBVA', 'corriente', 'COP', 200000.00),
  ('demo075', 'Bancolombia', 'digital', 'COP', 150000.00),
  ('demo075', 'Nequi', 'ahorros', 'COP', 100000.00),
  ('demo075', 'Efectivo', 'efectivo', 'COP', 500000.00),
  ('demo076', 'Davivienda', 'digital', 'COP', 150000.00),
  ('demo076', 'Daviplata', 'digital', 'COP', 350000.00)
) AS v(usuario, banco, tipo, moneda, saldo)
JOIN users u ON u.usuario = v.usuario;

INSERT INTO accounts (user_id, banco, tipo, moneda, saldo, activo)
SELECT u.id, v.banco, v.tipo, v.moneda, v.saldo::numeric, true
FROM (VALUES
  ('demo076', 'Efectivo', 'efectivo', 'COP', 500000.00),
  ('demo077', 'Daviplata', 'ahorros', 'COP', 200000.00),
  ('demo077', 'Banco de Bogotá', 'digital', 'COP', 350000.00),
  ('demo077', 'Efectivo', 'efectivo', 'COP', 200000.00),
  ('demo078', 'Nequi', 'ahorros', 'COP', 100000.00),
  ('demo078', 'Bancolombia', 'corriente', 'COP', 200000.00),
  ('demo078', 'Davivienda', 'corriente', 'COP', 50000.00),
  ('demo078', 'Efectivo', 'efectivo', 'COP', 300000.00),
  ('demo079', 'Bancolombia', 'digital', 'COP', 100000.00),
  ('demo079', 'Banco de Bogotá', 'ahorros', 'COP', 350000.00),
  ('demo079', 'BBVA', 'corriente', 'COP', 200000.00),
  ('demo079', 'Efectivo', 'efectivo', 'COP', 500000.00),
  ('demo080', 'BBVA', 'ahorros', 'COP', 150000.00),
  ('demo080', 'Bancolombia', 'corriente', 'COP', 150000.00),
  ('demo080', 'Efectivo', 'efectivo', 'COP', 400000.00),
  ('demo081', 'Davivienda', 'corriente', 'COP', 100000.00),
  ('demo081', 'BBVA', 'corriente', 'COP', 100000.00),
  ('demo081', 'Bancolombia', 'corriente', 'COP', 50000.00),
  ('demo082', 'Bancolombia', 'ahorros', 'COP', 350000.00),
  ('demo082', 'Nequi', 'digital', 'COP', 50000.00),
  ('demo082', 'Daviplata', 'corriente', 'COP', 350000.00),
  ('demo082', 'Efectivo', 'efectivo', 'COP', 300000.00),
  ('demo083', 'Nequi', 'ahorros', 'COP', 350000.00),
  ('demo083', 'Daviplata', 'corriente', 'COP', 100000.00),
  ('demo083', 'Bancolombia', 'digital', 'COP', 50000.00),
  ('demo084', 'Davivienda', 'corriente', 'COP', 350000.00),
  ('demo084', 'Bancolombia', 'digital', 'COP', 200000.00),
  ('demo085', 'Banco de Bogotá', 'corriente', 'COP', 200000.00),
  ('demo085', 'Davivienda', 'corriente', 'COP', 200000.00),
  ('demo086', 'Daviplata', 'ahorros', 'COP', 100000.00),
  ('demo086', 'Davivienda', 'ahorros', 'COP', 150000.00),
  ('demo086', 'BBVA', 'ahorros', 'COP', 100000.00),
  ('demo086', 'Efectivo', 'efectivo', 'COP', 200000.00),
  ('demo087', 'Daviplata', 'ahorros', 'COP', 200000.00),
  ('demo087', 'Davivienda', 'corriente', 'COP', 350000.00),
  ('demo087', 'Efectivo', 'efectivo', 'COP', 200000.00),
  ('demo088', 'Daviplata', 'ahorros', 'COP', 50000.00),
  ('demo088', 'Nequi', 'digital', 'COP', 200000.00),
  ('demo088', 'Efectivo', 'efectivo', 'COP', 300000.00),
  ('demo089', 'Bancolombia', 'corriente', 'COP', 350000.00),
  ('demo089', 'Daviplata', 'digital', 'COP', 150000.00),
  ('demo089', 'Banco de Bogotá', 'corriente', 'COP', 100000.00),
  ('demo090', 'Bancolombia', 'corriente', 'COP', 350000.00),
  ('demo090', 'Davivienda', 'ahorros', 'COP', 200000.00),
  ('demo090', 'Nequi', 'corriente', 'COP', 200000.00),
  ('demo091', 'Banco de Bogotá', 'corriente', 'COP', 150000.00),
  ('demo091', 'BBVA', 'ahorros', 'COP', 150000.00),
  ('demo091', 'Efectivo', 'efectivo', 'COP', 300000.00),
  ('demo092', 'Bancolombia', 'ahorros', 'COP', 350000.00),
  ('demo092', 'BBVA', 'ahorros', 'COP', 350000.00)
) AS v(usuario, banco, tipo, moneda, saldo)
JOIN users u ON u.usuario = v.usuario;

INSERT INTO accounts (user_id, banco, tipo, moneda, saldo, activo)
SELECT u.id, v.banco, v.tipo, v.moneda, v.saldo::numeric, true
FROM (VALUES
  ('demo092', 'Nequi', 'corriente', 'COP', 100000.00),
  ('demo093', 'BBVA', 'digital', 'COP', 150000.00),
  ('demo093', 'Banco de Bogotá', 'corriente', 'COP', 150000.00),
  ('demo093', 'Efectivo', 'efectivo', 'COP', 200000.00),
  ('demo094', 'Daviplata', 'ahorros', 'COP', 350000.00),
  ('demo094', 'Bancolombia', 'corriente', 'COP', 200000.00),
  ('demo094', 'Efectivo', 'efectivo', 'COP', 200000.00),
  ('demo095', 'Daviplata', 'corriente', 'COP', 100000.00),
  ('demo095', 'Bancolombia', 'ahorros', 'COP', 50000.00),
  ('demo096', 'Bancolombia', 'ahorros', 'COP', 200000.00),
  ('demo096', 'Davivienda', 'ahorros', 'COP', 150000.00),
  ('demo096', 'Efectivo', 'efectivo', 'COP', 400000.00),
  ('demo097', 'Bancolombia', 'corriente', 'COP', 100000.00),
  ('demo097', 'BBVA', 'ahorros', 'COP', 100000.00),
  ('demo097', 'Davivienda', 'digital', 'COP', 150000.00),
  ('demo097', 'Efectivo', 'efectivo', 'COP', 200000.00),
  ('demo098', 'Daviplata', 'ahorros', 'COP', 100000.00),
  ('demo098', 'Davivienda', 'corriente', 'COP', 50000.00),
  ('demo098', 'Efectivo', 'efectivo', 'COP', 400000.00),
  ('demo099', 'Daviplata', 'corriente', 'COP', 350000.00),
  ('demo099', 'Bancolombia', 'corriente', 'COP', 50000.00),
  ('demo100', 'Daviplata', 'ahorros', 'COP', 50000.00),
  ('demo100', 'Bancolombia', 'digital', 'COP', 50000.00),
  ('demo100', 'Davivienda', 'ahorros', 'COP', 350000.00),
  ('demo100', 'Efectivo', 'efectivo', 'COP', 200000.00)
) AS v(usuario, banco, tipo, moneda, saldo)
JOIN users u ON u.usuario = v.usuario;

-- Counterparties (multi-row via VALUES + join users)
INSERT INTO counterparties (user_id, nombre, banco, numero_cuenta, notas, activo)
SELECT u.id, v.nombre, v.banco, v.numero_cuenta, NULL, true
FROM (VALUES
  ('demo001', 'Netflix', 'Bancolombia', '3410529190'),
  ('demo002', 'Arrendador Moreno', NULL::text, NULL::text),
  ('demo002', 'Restaurante Andrés', 'Banco de Bogotá', '9639245200'),
  ('demo002', 'Claro', 'Nequi', '8047877267'),
  ('demo003', 'Tienda Local', 'Nequi', '9807209816'),
  ('demo004', 'Uber', 'Banco de Bogotá', '3376077463'),
  ('demo005', 'Universidad Nacional', 'Nequi', '3476426797'),
  ('demo005', 'Restaurante Andrés', 'Banco de Bogotá', '9780573290'),
  ('demo006', 'EPS Sura', 'Daviplata', '3319936135'),
  ('demo007', 'Restaurante Andrés', NULL::text, NULL::text),
  ('demo008', 'EPS Sura', 'Nequi', '4748302739'),
  ('demo008', 'Uber', 'Banco de Bogotá', '7311011808'),
  ('demo008', 'Tienda Local', NULL::text, NULL::text),
  ('demo009', 'Supermercado Éxito', 'Banco de Bogotá', '1111088881'),
  ('demo009', 'Restaurante Andrés', 'BBVA', '5083595988'),
  ('demo009', 'Universidad Nacional', 'Banco de Bogotá', '3474961963'),
  ('demo010', 'Arrendador Moreno', NULL::text, NULL::text),
  ('demo010', 'Claro', 'Bancolombia', '4102872611'),
  ('demo011', 'Supermercado Éxito', 'Davivienda', '6562457052'),
  ('demo011', 'Universidad Nacional', NULL::text, NULL::text),
  ('demo012', 'Netflix', NULL::text, NULL::text),
  ('demo012', 'Supermercado Éxito', 'Bancolombia', '7019900273'),
  ('demo012', 'EPS Sura', 'Nequi', '9202102595'),
  ('demo013', 'Uber', 'Bancolombia', '3894673596'),
  ('demo014', 'Universidad Nacional', 'Banco de Bogotá', '9919491730'),
  ('demo015', 'Claro', NULL::text, NULL::text),
  ('demo015', 'EPM', 'Davivienda', '4508521152'),
  ('demo016', 'Arrendador Moreno', 'BBVA', '3698343112'),
  ('demo016', 'Universidad Nacional', 'Daviplata', '1572989855'),
  ('demo017', 'Universidad Nacional', 'BBVA', '5125402225'),
  ('demo017', 'EPS Sura', 'Bancolombia', '4159699467'),
  ('demo018', 'EPM', 'Daviplata', '3420721027'),
  ('demo018', 'Uber', 'Bancolombia', '1348849508'),
  ('demo018', 'Claro', 'Banco de Bogotá', '3796581976'),
  ('demo019', 'Tienda Local', 'Bancolombia', '7801180691'),
  ('demo019', 'EPS Sura', 'Davivienda', '2632905061'),
  ('demo019', 'Netflix', 'BBVA', '9725528903'),
  ('demo020', 'Tienda Local', 'Nequi', '2420277403'),
  ('demo020', 'EPS Sura', NULL::text, NULL::text),
  ('demo020', 'Netflix', 'Banco de Bogotá', '4086355679'),
  ('demo021', 'Tienda Local', 'Bancolombia', '6528012497'),
  ('demo022', 'Restaurante Andrés', NULL::text, NULL::text),
  ('demo022', 'Uber', 'BBVA', '4647891535'),
  ('demo023', 'Restaurante Andrés', 'BBVA', '8236361108'),
  ('demo024', 'EPM', 'Banco de Bogotá', '4427620889'),
  ('demo025', 'Claro', 'BBVA', '3975704877'),
  ('demo025', 'Supermercado Éxito', NULL::text, NULL::text),
  ('demo025', 'Tienda Local', NULL::text, NULL::text),
  ('demo026', 'Netflix', 'Davivienda', '2984507492'),
  ('demo026', 'Claro', NULL::text, NULL::text)
) AS v(usuario, nombre, banco, numero_cuenta)
JOIN users u ON u.usuario = v.usuario;

INSERT INTO counterparties (user_id, nombre, banco, numero_cuenta, notas, activo)
SELECT u.id, v.nombre, v.banco, v.numero_cuenta, NULL, true
FROM (VALUES
  ('demo026', 'Uber', 'Davivienda', '8118083267'),
  ('demo027', 'Tienda Local', 'Nequi', '9550822977'),
  ('demo027', 'Claro', 'Bancolombia', '2826025489'),
  ('demo027', 'Arrendador Moreno', 'BBVA', '5292015249'),
  ('demo028', 'Arrendador Moreno', 'Davivienda', '7190276026'),
  ('demo029', 'Universidad Nacional', NULL::text, NULL::text),
  ('demo029', 'Uber', NULL::text, NULL::text),
  ('demo030', 'Supermercado Éxito', 'Bancolombia', '2050340486'),
  ('demo031', 'EPS Sura', 'Banco de Bogotá', '8949613826'),
  ('demo032', 'Claro', 'Daviplata', '8651205525'),
  ('demo032', 'Supermercado Éxito', 'Daviplata', '7452729913'),
  ('demo032', 'Restaurante Andrés', NULL::text, NULL::text),
  ('demo033', 'Universidad Nacional', NULL::text, NULL::text),
  ('demo033', 'Netflix', 'Banco de Bogotá', '2264942028'),
  ('demo033', 'Uber', 'Davivienda', '4130305126'),
  ('demo034', 'EPM', 'Nequi', '1110533960'),
  ('demo034', 'Tienda Local', 'Davivienda', '8035975297'),
  ('demo034', 'Netflix', 'Nequi', '5791074361'),
  ('demo035', 'Universidad Nacional', 'Daviplata', '6596578419'),
  ('demo035', 'Supermercado Éxito', 'Banco de Bogotá', '8914965741'),
  ('demo036', 'Claro', 'Daviplata', '6509055260'),
  ('demo037', 'Restaurante Andrés', NULL::text, NULL::text),
  ('demo037', 'Tienda Local', 'Bancolombia', '9751963589'),
  ('demo038', 'Arrendador Moreno', 'Nequi', '2214216328'),
  ('demo038', 'Claro', 'Nequi', '3137772998'),
  ('demo039', 'Restaurante Andrés', NULL::text, NULL::text),
  ('demo040', 'Universidad Nacional', 'Nequi', '1952396600'),
  ('demo040', 'Tienda Local', 'Daviplata', '8730566271'),
  ('demo040', 'Arrendador Moreno', 'Daviplata', '4015479599'),
  ('demo041', 'EPS Sura', 'Daviplata', '8791183272'),
  ('demo041', 'Netflix', 'Nequi', '2670255496'),
  ('demo041', 'Supermercado Éxito', 'Banco de Bogotá', '6933852220'),
  ('demo042', 'Universidad Nacional', NULL::text, NULL::text),
  ('demo042', 'Restaurante Andrés', 'Banco de Bogotá', '2214741296'),
  ('demo042', 'Arrendador Moreno', 'Daviplata', '7479970041'),
  ('demo043', 'EPS Sura', 'Daviplata', '9412376000'),
  ('demo043', 'Uber', 'Davivienda', '5315720088'),
  ('demo043', 'Universidad Nacional', 'BBVA', '4374384508'),
  ('demo044', 'Uber', 'Banco de Bogotá', '4961879157'),
  ('demo045', 'Netflix', 'Nequi', '4035639663'),
  ('demo045', 'Tienda Local', 'Davivienda', '3731069282'),
  ('demo045', 'Uber', 'Nequi', '4535855298'),
  ('demo046', 'Uber', NULL::text, NULL::text),
  ('demo046', 'Netflix', 'BBVA', '2139907416'),
  ('demo047', 'Restaurante Andrés', NULL::text, NULL::text),
  ('demo048', 'Arrendador Moreno', 'Banco de Bogotá', '3654728627'),
  ('demo049', 'Tienda Local', 'BBVA', '2377154307'),
  ('demo049', 'EPS Sura', 'Davivienda', '3297681898'),
  ('demo049', 'EPM', 'Davivienda', '5176136758'),
  ('demo050', 'Claro', NULL::text, NULL::text)
) AS v(usuario, nombre, banco, numero_cuenta)
JOIN users u ON u.usuario = v.usuario;

INSERT INTO counterparties (user_id, nombre, banco, numero_cuenta, notas, activo)
SELECT u.id, v.nombre, v.banco, v.numero_cuenta, NULL, true
FROM (VALUES
  ('demo050', 'Universidad Nacional', 'BBVA', '9681644296'),
  ('demo051', 'EPS Sura', NULL::text, NULL::text),
  ('demo051', 'Universidad Nacional', NULL::text, NULL::text),
  ('demo051', 'Tienda Local', 'Bancolombia', '4119491798'),
  ('demo052', 'Tienda Local', 'BBVA', '7390314766'),
  ('demo053', 'Tienda Local', 'Davivienda', '4436425084'),
  ('demo053', 'Claro', 'Davivienda', '5875872347'),
  ('demo054', 'Arrendador Moreno', 'Bancolombia', '7605097681'),
  ('demo054', 'Tienda Local', 'Bancolombia', '7690274631'),
  ('demo054', 'Claro', 'Bancolombia', '6110368314'),
  ('demo055', 'Uber', 'Davivienda', '9826432406'),
  ('demo056', 'Supermercado Éxito', 'Banco de Bogotá', '8207803934'),
  ('demo056', 'Claro', 'Bancolombia', '8239138603'),
  ('demo057', 'EPM', NULL::text, NULL::text),
  ('demo058', 'Uber', 'Nequi', '3784810609'),
  ('demo058', 'EPM', 'Davivienda', '5252952412'),
  ('demo058', 'Supermercado Éxito', 'Nequi', '8756460189'),
  ('demo059', 'Netflix', 'Davivienda', '4702323796'),
  ('demo059', 'Tienda Local', 'Daviplata', '5226555608'),
  ('demo060', 'EPS Sura', 'Bancolombia', '9691727358'),
  ('demo060', 'EPM', 'Nequi', '5113699666'),
  ('demo060', 'Netflix', 'Nequi', '5852914708'),
  ('demo061', 'Supermercado Éxito', 'BBVA', '7396205104'),
  ('demo062', 'Netflix', 'Bancolombia', '1832016743'),
  ('demo062', 'EPS Sura', 'Davivienda', '7332554920'),
  ('demo063', 'Uber', 'Nequi', '7535947151'),
  ('demo063', 'EPM', 'BBVA', '7835787787'),
  ('demo063', 'Netflix', NULL::text, NULL::text),
  ('demo064', 'EPM', 'Daviplata', '8216518899'),
  ('demo064', 'Netflix', 'Banco de Bogotá', '1233903914'),
  ('demo064', 'Claro', 'Daviplata', '6777704180'),
  ('demo065', 'EPM', 'BBVA', '2193688100'),
  ('demo066', 'Arrendador Moreno', 'BBVA', '5784450697'),
  ('demo067', 'Uber', 'Bancolombia', '8334756553'),
  ('demo067', 'Claro', 'Daviplata', '6090076463'),
  ('demo068', 'Uber', 'Davivienda', '6966055281'),
  ('demo068', 'Tienda Local', 'Nequi', '7312821876'),
  ('demo068', 'Restaurante Andrés', 'Davivienda', '3176195719'),
  ('demo069', 'Netflix', 'Davivienda', '1824272995'),
  ('demo069', 'Arrendador Moreno', 'BBVA', '6628728894'),
  ('demo070', 'Arrendador Moreno', NULL::text, NULL::text),
  ('demo070', 'Claro', NULL::text, NULL::text),
  ('demo070', 'Netflix', 'Bancolombia', '6392476150'),
  ('demo071', 'Restaurante Andrés', 'Davivienda', '1626819783'),
  ('demo072', 'Arrendador Moreno', 'Bancolombia', '7191279918'),
  ('demo072', 'Tienda Local', NULL::text, NULL::text),
  ('demo073', 'EPS Sura', 'Nequi', '8544069858'),
  ('demo073', 'Restaurante Andrés', 'Daviplata', '3636542070'),
  ('demo074', 'Supermercado Éxito', 'Bancolombia', '9585752886'),
  ('demo074', 'Universidad Nacional', 'Bancolombia', '7388748888')
) AS v(usuario, nombre, banco, numero_cuenta)
JOIN users u ON u.usuario = v.usuario;

INSERT INTO counterparties (user_id, nombre, banco, numero_cuenta, notas, activo)
SELECT u.id, v.nombre, v.banco, v.numero_cuenta, NULL, true
FROM (VALUES
  ('demo075', 'Netflix', NULL::text, NULL::text),
  ('demo075', 'Uber', 'BBVA', '7136747399'),
  ('demo076', 'Netflix', 'BBVA', '6846599544'),
  ('demo076', 'Arrendador Moreno', 'Nequi', '2769753981'),
  ('demo076', 'Universidad Nacional', 'Nequi', '5562087085'),
  ('demo077', 'Supermercado Éxito', NULL::text, NULL::text),
  ('demo077', 'Universidad Nacional', 'Davivienda', '2782138375'),
  ('demo078', 'Netflix', NULL::text, NULL::text),
  ('demo079', 'EPM', 'Bancolombia', '1826700966'),
  ('demo079', 'Arrendador Moreno', 'Nequi', '9642713632'),
  ('demo079', 'Universidad Nacional', 'Nequi', '4611120314'),
  ('demo080', 'Uber', 'Nequi', '1508924953'),
  ('demo080', 'Claro', 'Davivienda', '4414061436'),
  ('demo080', 'Restaurante Andrés', 'BBVA', '7582272381'),
  ('demo081', 'Claro', 'Nequi', '8670267393'),
  ('demo081', 'EPM', 'BBVA', '1422663925'),
  ('demo082', 'Restaurante Andrés', 'Banco de Bogotá', '1884300678'),
  ('demo083', 'Arrendador Moreno', 'Bancolombia', '8204305733'),
  ('demo084', 'Uber', 'Daviplata', '8157007197'),
  ('demo084', 'Universidad Nacional', 'Nequi', '2439265956'),
  ('demo084', 'EPM', NULL::text, NULL::text),
  ('demo085', 'Restaurante Andrés', 'Banco de Bogotá', '3526767947'),
  ('demo085', 'Tienda Local', NULL::text, NULL::text),
  ('demo086', 'EPM', 'Davivienda', '1863034397'),
  ('demo086', 'Netflix', 'Davivienda', '6119106378'),
  ('demo087', 'Restaurante Andrés', 'Nequi', '8448666187'),
  ('demo087', 'Tienda Local', 'Banco de Bogotá', '3607791648'),
  ('demo088', 'Claro', NULL::text, NULL::text),
  ('demo089', 'Supermercado Éxito', 'Bancolombia', '8657075548'),
  ('demo089', 'Netflix', NULL::text, NULL::text),
  ('demo089', 'EPS Sura', 'Davivienda', '7773470371'),
  ('demo090', 'EPS Sura', 'BBVA', '4684744684'),
  ('demo090', 'EPM', 'Banco de Bogotá', '9977085483'),
  ('demo090', 'Restaurante Andrés', 'Nequi', '9919329410'),
  ('demo091', 'Universidad Nacional', 'Nequi', '7145255596'),
  ('demo091', 'Supermercado Éxito', 'BBVA', '9953906342'),
  ('demo092', 'Netflix', 'BBVA', '3624656441'),
  ('demo092', 'Restaurante Andrés', 'BBVA', '3725058806'),
  ('demo093', 'Arrendador Moreno', NULL::text, NULL::text),
  ('demo093', 'Tienda Local', 'Bancolombia', '5155324773'),
  ('demo094', 'Supermercado Éxito', 'Nequi', '2149575829'),
  ('demo094', 'Uber', 'Bancolombia', '4400156805'),
  ('demo094', 'Netflix', 'Daviplata', '1364922725'),
  ('demo095', 'Universidad Nacional', NULL::text, NULL::text),
  ('demo096', 'Universidad Nacional', 'Banco de Bogotá', '1457261738'),
  ('demo096', 'Supermercado Éxito', 'BBVA', '3564571185'),
  ('demo096', 'Netflix', 'Banco de Bogotá', '4990891827'),
  ('demo097', 'Uber', NULL::text, NULL::text),
  ('demo098', 'Netflix', 'Daviplata', '9340575870'),
  ('demo099', 'Claro', 'Bancolombia', '8162760510')
) AS v(usuario, nombre, banco, numero_cuenta)
JOIN users u ON u.usuario = v.usuario;

INSERT INTO counterparties (user_id, nombre, banco, numero_cuenta, notas, activo)
SELECT u.id, v.nombre, v.banco, v.numero_cuenta, NULL, true
FROM (VALUES
  ('demo099', 'Arrendador Moreno', NULL::text, NULL::text),
  ('demo099', 'Tienda Local', 'BBVA', '2636725415'),
  ('demo100', 'Uber', 'Banco de Bogotá', '1775790050')
) AS v(usuario, nombre, banco, numero_cuenta)
JOIN users u ON u.usuario = v.usuario;

-- Transactions (multi-row via VALUES + joins)
INSERT INTO transactions (account_id, category_id, sub_category_id, contraparte_id, monto, tipo, medio_pago, fecha, descripcion, activo, grupo_transferencia)
SELECT a.id, c.id, s.id, CASE WHEN v.use_cp THEN cp.id ELSE NULL END, v.monto::numeric, v.tipo, v.medio_pago, v.fecha::date, v.descripcion, true, NULLIF(v.grupo, '')
FROM (VALUES
  ('demo001', 'Bancolombia', 'corriente', 'Ingresos', 'Otros ingresos', false, 800000.00, 'ingreso', 'cuenta', '2026-01-09', 'Pago cliente', ''),
  ('demo001', 'Bancolombia', 'corriente', 'Ingresos', 'Otros ingresos', false, 800000.00, 'ingreso', 'cuenta', '2026-01-16', 'Pago cliente', ''),
  ('demo001', 'Efectivo', 'efectivo', 'Ocio', 'Cine', false, 40000.00, 'gasto', 'efectivo', '2026-02-13', 'Pago', ''),
  ('demo001', 'Efectivo', 'efectivo', 'Vivienda', 'Servicios', false, 5000.00, 'gasto', 'efectivo', '2026-02-16', 'Consumo', ''),
  ('demo001', 'Nequi', 'ahorros', 'Ocio', 'Suscripciones', false, 12000.00, 'gasto', 'cuenta', '2026-02-22', 'Consumo', ''),
  ('demo001', 'Bancolombia', 'corriente', 'Ocio', 'Cine', true, 25000.00, 'gasto', 'cuenta', '2026-02-23', 'Consumo', ''),
  ('demo001', 'Bancolombia', 'corriente', 'Transporte', 'Taxi / apps', true, 12000.00, 'gasto', 'cuenta', '2026-03-10', 'Pago', ''),
  ('demo001', 'Bancolombia', 'corriente', 'Vivienda', 'Servicios', false, 78000.00, 'gasto', 'cuenta', '2026-03-26', 'Consumo', ''),
  ('demo001', 'Nequi', 'ahorros', 'Alimentación', 'Restaurante', false, 45000.00, 'gasto', 'cuenta', '2026-04-11', 'Consumo', ''),
  ('demo001', 'Efectivo', 'efectivo', 'Vivienda', 'Arriendo', true, 5000.00, 'gasto', 'efectivo', '2026-04-28', 'Consumo', ''),
  ('demo001', 'Bancolombia', 'corriente', 'Transferencias', 'Entre mis cuentas', false, 300000.00, 'transferencia_salida', 'cuenta', '2026-04-29', 'Transferencia entre cuentas (salida)', '3556f0b4-32a2-4630-aafe-7fe2aed256a0'),
  ('demo001', 'Efectivo', 'efectivo', 'Transferencias', 'Entre mis cuentas', false, 300000.00, 'transferencia_entrada', 'cuenta', '2026-04-29', 'Transferencia entre cuentas (entrada)', '3556f0b4-32a2-4630-aafe-7fe2aed256a0'),
  ('demo001', 'Bancolombia', 'corriente', 'Vivienda', 'Mantenimiento', true, 25000.00, 'gasto', 'cuenta', '2026-05-02', 'Pago', ''),
  ('demo002', 'Davivienda', 'corriente', 'Ingresos', 'Freelance', true, 1800000.00, 'ingreso', 'cuenta', '2026-01-11', 'Nomina', ''),
  ('demo002', 'Banco de Bogotá', 'ahorros', 'Alimentación', 'Café', false, 12000.00, 'gasto', 'cuenta', '2026-01-15', 'Servicio', ''),
  ('demo002', 'Davivienda', 'corriente', 'Transferencias', 'Entre mis cuentas', false, 200000.00, 'transferencia_salida', 'cuenta', '2026-01-22', 'Retiro a efectivo (salida)', '1a08fc88-27e6-49f5-8b5d-a9d47acf1fc4'),
  ('demo002', 'Efectivo', 'efectivo', 'Transferencias', 'Entre mis cuentas', false, 200000.00, 'transferencia_entrada', 'cuenta', '2026-01-22', 'Retiro a efectivo (entrada)', '1a08fc88-27e6-49f5-8b5d-a9d47acf1fc4'),
  ('demo002', 'Davivienda', 'corriente', 'Transferencias', 'Entre mis cuentas', false, 300000.00, 'transferencia_salida', 'cuenta', '2026-02-05', 'Transferencia entre cuentas (salida)', 'e2add2c7-ca6c-4987-b53c-edd49e0a0b6c'),
  ('demo002', 'Nequi', 'ahorros', 'Transferencias', 'Entre mis cuentas', false, 300000.00, 'transferencia_entrada', 'cuenta', '2026-02-05', 'Transferencia entre cuentas (entrada)', 'e2add2c7-ca6c-4987-b53c-edd49e0a0b6c'),
  ('demo002', 'Nequi', 'ahorros', 'Vivienda', 'Mantenimiento', false, 25000.00, 'gasto', 'cuenta', '2026-02-11', 'Servicio', ''),
  ('demo002', 'Banco de Bogotá', 'ahorros', 'Salud', 'Medicamentos', false, 38000.00, 'gasto', 'cuenta', '2026-02-23', 'Servicio', ''),
  ('demo002', 'Nequi', 'ahorros', 'Transporte', 'Combustible', true, 250000.00, 'gasto', 'cuenta', '2026-03-06', 'Pago', ''),
  ('demo002', 'Nequi', 'ahorros', 'Vivienda', 'Servicios', true, 5000.00, 'gasto', 'cuenta', '2026-03-23', 'Pago', ''),
  ('demo002', 'Davivienda', 'corriente', 'Alimentación', 'Restaurante', true, 12000.00, 'gasto', 'cuenta', '2026-05-23', 'Consumo', ''),
  ('demo002', 'Davivienda', 'corriente', 'Educación', 'Libros', false, 78000.00, 'gasto', 'cuenta', '2026-05-24', 'Pago', ''),
  ('demo002', 'Davivienda', 'corriente', 'Ocio', 'Salidas', true, 250000.00, 'gasto', 'cuenta', '2026-06-19', 'Pago', ''),
  ('demo002', 'Efectivo', 'efectivo', 'Ocio', 'Salidas', false, 15000.00, 'gasto', 'efectivo', '2026-06-24', 'Servicio', ''),
  ('demo003', 'Banco de Bogotá', 'ahorros', 'Ingresos', 'Otros ingresos', false, 2800000.00, 'ingreso', 'cuenta', '2026-01-09', 'Ingreso extra', ''),
  ('demo003', 'Bancolombia', 'digital', 'Vivienda', 'Arriendo', false, 78000.00, 'gasto', 'cuenta', '2026-01-31', 'Compra', ''),
  ('demo003', 'Bancolombia', 'digital', 'Transferencias', 'Entre mis cuentas', false, 22000.00, 'transferencia_salida', 'cuenta', '2026-02-06', 'Retiro a efectivo (salida)', '3a56e326-786a-4b46-bf65-1b4a11d693dd'),
  ('demo003', 'Efectivo', 'efectivo', 'Transferencias', 'Entre mis cuentas', false, 22000.00, 'transferencia_entrada', 'cuenta', '2026-02-06', 'Retiro a efectivo (entrada)', '3a56e326-786a-4b46-bf65-1b4a11d693dd'),
  ('demo003', 'Banco de Bogotá', 'ahorros', 'Transporte', 'Taxi / apps', false, 250000.00, 'gasto', 'cuenta', '2026-03-11', 'Compra', ''),
  ('demo003', 'Efectivo', 'efectivo', 'Transporte', 'Taxi / apps', false, 5000.00, 'gasto', 'efectivo', '2026-04-06', 'Compra', ''),
  ('demo003', 'Banco de Bogotá', 'ahorros', 'Ocio', 'Suscripciones', false, 45000.00, 'gasto', 'cuenta', '2026-04-23', 'Compra', ''),
  ('demo003', 'Banco de Bogotá', 'ahorros', 'Alimentación', 'Restaurante', false, 45000.00, 'gasto', 'cuenta', '2026-04-28', 'Compra', ''),
  ('demo003', 'Banco de Bogotá', 'ahorros', 'Vivienda', 'Mantenimiento', false, 120000.00, 'gasto', 'cuenta', '2026-04-30', 'Pago', ''),
  ('demo003', 'Efectivo', 'efectivo', 'Vivienda', 'Servicios', false, 15000.00, 'gasto', 'efectivo', '2026-05-11', 'Consumo', ''),
  ('demo003', 'Banco de Bogotá', 'ahorros', 'Educación', 'Cursos', false, 78000.00, 'gasto', 'cuenta', '2026-05-19', 'Consumo', ''),
  ('demo003', 'Efectivo', 'efectivo', 'Alimentación', 'Supermercado', false, 5000.00, 'gasto', 'efectivo', '2026-05-19', 'Servicio', ''),
  ('demo003', 'Banco de Bogotá', 'ahorros', 'Alimentación', 'Café', false, 12000.00, 'gasto', 'cuenta', '2026-05-20', 'Pago', '')
) AS v(usuario, banco, tipo_cta, cat, sub, use_cp, monto, tipo, medio_pago, fecha, descripcion, grupo)
JOIN users u ON u.usuario = v.usuario
JOIN accounts a ON a.user_id = u.id AND a.banco = v.banco AND a.tipo = v.tipo_cta
JOIN categories c ON c.nombre = v.cat
JOIN sub_categories s ON s.category_id = c.id AND s.nombre = v.sub
LEFT JOIN LATERAL (
  SELECT id FROM counterparties WHERE user_id = u.id ORDER BY id LIMIT 1
) cp ON v.use_cp;

INSERT INTO transactions (account_id, category_id, sub_category_id, contraparte_id, monto, tipo, medio_pago, fecha, descripcion, activo, grupo_transferencia)
SELECT a.id, c.id, s.id, CASE WHEN v.use_cp THEN cp.id ELSE NULL END, v.monto::numeric, v.tipo, v.medio_pago, v.fecha::date, v.descripcion, true, NULLIF(v.grupo, '')
FROM (VALUES
  ('demo004', 'Nequi', 'digital', 'Ingresos', 'Freelance', false, 800000.00, 'ingreso', 'cuenta', '2026-01-13', 'Nomina', ''),
  ('demo004', 'BBVA', 'ahorros', 'Ingresos', 'Otros ingresos', false, 1200000.00, 'ingreso', 'cuenta', '2026-01-21', 'Pago cliente', ''),
  ('demo004', 'BBVA', 'ahorros', 'Transporte', 'Combustible', false, 5000.00, 'gasto', 'cuenta', '2026-01-30', 'Compra', ''),
  ('demo004', 'Davivienda', 'corriente', 'Alimentación', 'Restaurante', false, 25000.00, 'gasto', 'cuenta', '2026-02-09', 'Consumo', ''),
  ('demo004', 'Nequi', 'digital', 'Transporte', 'Transporte público', true, 180000.00, 'gasto', 'cuenta', '2026-03-22', 'Compra', ''),
  ('demo004', 'Nequi', 'digital', 'Vivienda', 'Arriendo', false, 120000.00, 'gasto', 'cuenta', '2026-03-25', 'Pago', ''),
  ('demo004', 'BBVA', 'ahorros', 'Ingresos', 'Freelance', false, 2800000.00, 'ingreso', 'cuenta', '2026-04-02', 'Ingreso extra', ''),
  ('demo004', 'Nequi', 'digital', 'Transporte', 'Taxi / apps', true, 25000.00, 'gasto', 'cuenta', '2026-05-05', 'Servicio', ''),
  ('demo004', 'Davivienda', 'corriente', 'Ocio', 'Salidas', true, 120000.00, 'gasto', 'cuenta', '2026-05-22', 'Pago', ''),
  ('demo004', 'Davivienda', 'corriente', 'Ocio', 'Suscripciones', false, 12000.00, 'gasto', 'cuenta', '2026-05-26', 'Compra', ''),
  ('demo004', 'Nequi', 'digital', 'Educación', 'Cursos', true, 45000.00, 'gasto', 'cuenta', '2026-06-28', 'Consumo', ''),
  ('demo004', 'Nequi', 'digital', 'Alimentación', 'Supermercado', true, 45000.00, 'gasto', 'cuenta', '2026-06-28', 'Pago', ''),
  ('demo005', 'Banco de Bogotá', 'ahorros', 'Ingresos', 'Otros ingresos', false, 3500000.00, 'ingreso', 'cuenta', '2026-01-10', 'Nomina', ''),
  ('demo005', 'Banco de Bogotá', 'ahorros', 'Ingresos', 'Otros ingresos', false, 2200000.00, 'ingreso', 'cuenta', '2026-01-21', 'Nomina', ''),
  ('demo005', 'Daviplata', 'ahorros', 'Salud', 'Consultas', false, 50000.00, 'gasto', 'cuenta', '2026-02-04', 'Servicio', ''),
  ('demo005', 'Davivienda', 'corriente', 'Educación', 'Libros', false, 45000.00, 'gasto', 'cuenta', '2026-02-18', 'Pago', ''),
  ('demo005', 'Banco de Bogotá', 'ahorros', 'Alimentación', 'Café', false, 120000.00, 'gasto', 'cuenta', '2026-03-09', 'Pago', ''),
  ('demo005', 'Efectivo', 'efectivo', 'Vivienda', 'Arriendo', true, 10000.00, 'gasto', 'efectivo', '2026-03-15', 'Pago', ''),
  ('demo005', 'Davivienda', 'corriente', 'Educación', 'Cursos', false, 12000.00, 'gasto', 'cuenta', '2026-04-07', 'Servicio', ''),
  ('demo005', 'Davivienda', 'corriente', 'Ocio', 'Suscripciones', true, 45000.00, 'gasto', 'cuenta', '2026-04-08', 'Servicio', ''),
  ('demo005', 'Davivienda', 'corriente', 'Alimentación', 'Restaurante', false, 248000.00, 'gasto', 'cuenta', '2026-05-01', 'Pago', ''),
  ('demo005', 'Efectivo', 'efectivo', 'Salud', 'Consultas', false, 55000.00, 'gasto', 'efectivo', '2026-05-12', 'Servicio', ''),
  ('demo006', 'Davivienda', 'corriente', 'Ingresos', 'Freelance', false, 2200000.00, 'ingreso', 'cuenta', '2026-01-13', 'Ingreso extra', ''),
  ('demo006', 'Efectivo', 'efectivo', 'Vivienda', 'Servicios', true, 40000.00, 'gasto', 'efectivo', '2026-01-31', 'Servicio', ''),
  ('demo006', 'Davivienda', 'corriente', 'Alimentación', 'Supermercado', true, 250000.00, 'gasto', 'cuenta', '2026-02-03', 'Servicio', ''),
  ('demo006', 'Davivienda', 'corriente', 'Educación', 'Cursos', false, 25000.00, 'gasto', 'cuenta', '2026-02-04', 'Pago', ''),
  ('demo006', 'Daviplata', 'corriente', 'Ingresos', 'Otros ingresos', false, 2200000.00, 'ingreso', 'cuenta', '2026-03-11', 'Ingreso extra', ''),
  ('demo006', 'Daviplata', 'corriente', 'Transporte', 'Transporte público', true, 180000.00, 'gasto', 'cuenta', '2026-03-12', 'Servicio', ''),
  ('demo006', 'Davivienda', 'corriente', 'Salud', 'Consultas', false, 180000.00, 'gasto', 'cuenta', '2026-04-13', 'Pago', ''),
  ('demo006', 'Davivienda', 'corriente', 'Vivienda', 'Mantenimiento', true, 180000.00, 'gasto', 'cuenta', '2026-05-03', 'Servicio', ''),
  ('demo006', 'Efectivo', 'efectivo', 'Educación', 'Libros', false, 5000.00, 'gasto', 'efectivo', '2026-05-03', 'Compra', ''),
  ('demo006', 'Daviplata', 'corriente', 'Vivienda', 'Servicios', false, 120000.00, 'gasto', 'cuenta', '2026-05-05', 'Compra', ''),
  ('demo006', 'Daviplata', 'corriente', 'Vivienda', 'Servicios', false, 5000.00, 'gasto', 'cuenta', '2026-05-05', 'Pago', ''),
  ('demo006', 'Daviplata', 'corriente', 'Transferencias', 'Entre mis cuentas', false, 80000.00, 'transferencia_salida', 'cuenta', '2026-05-06', 'Transferencia entre cuentas (salida)', '00f8b862-9e06-4487-9fb2-9bfc2da0d850'),
  ('demo006', 'Davivienda', 'corriente', 'Transferencias', 'Entre mis cuentas', false, 80000.00, 'transferencia_entrada', 'cuenta', '2026-05-06', 'Transferencia entre cuentas (entrada)', '00f8b862-9e06-4487-9fb2-9bfc2da0d850'),
  ('demo006', 'Davivienda', 'corriente', 'Vivienda', 'Arriendo', false, 12000.00, 'gasto', 'cuenta', '2026-05-18', 'Servicio', ''),
  ('demo006', 'Davivienda', 'corriente', 'Transporte', 'Combustible', false, 25000.00, 'gasto', 'cuenta', '2026-06-06', 'Pago', ''),
  ('demo006', 'Efectivo', 'efectivo', 'Alimentación', 'Supermercado', false, 5000.00, 'gasto', 'efectivo', '2026-06-22', 'Consumo', ''),
  ('demo006', 'Efectivo', 'efectivo', 'Ocio', 'Suscripciones', true, 25000.00, 'gasto', 'efectivo', '2026-06-24', 'Pago', ''),
  ('demo007', 'Daviplata', 'ahorros', 'Ingresos', 'Otros ingresos', false, 2200000.00, 'ingreso', 'cuenta', '2026-01-11', 'Ingreso extra', '')
) AS v(usuario, banco, tipo_cta, cat, sub, use_cp, monto, tipo, medio_pago, fecha, descripcion, grupo)
JOIN users u ON u.usuario = v.usuario
JOIN accounts a ON a.user_id = u.id AND a.banco = v.banco AND a.tipo = v.tipo_cta
JOIN categories c ON c.nombre = v.cat
JOIN sub_categories s ON s.category_id = c.id AND s.nombre = v.sub
LEFT JOIN LATERAL (
  SELECT id FROM counterparties WHERE user_id = u.id ORDER BY id LIMIT 1
) cp ON v.use_cp;

INSERT INTO transactions (account_id, category_id, sub_category_id, contraparte_id, monto, tipo, medio_pago, fecha, descripcion, activo, grupo_transferencia)
SELECT a.id, c.id, s.id, CASE WHEN v.use_cp THEN cp.id ELSE NULL END, v.monto::numeric, v.tipo, v.medio_pago, v.fecha::date, v.descripcion, true, NULLIF(v.grupo, '')
FROM (VALUES
  ('demo007', 'Daviplata', 'ahorros', 'Transferencias', 'Entre mis cuentas', false, 100000.00, 'transferencia_salida', 'cuenta', '2026-01-25', 'Retiro a efectivo (salida)', '0e0ae453-d97f-476e-a718-f88d2e771752'),
  ('demo007', 'Efectivo', 'efectivo', 'Transferencias', 'Entre mis cuentas', false, 100000.00, 'transferencia_entrada', 'cuenta', '2026-01-25', 'Retiro a efectivo (entrada)', '0e0ae453-d97f-476e-a718-f88d2e771752'),
  ('demo007', 'Daviplata', 'ahorros', 'Salud', 'Consultas', false, 250000.00, 'gasto', 'cuenta', '2026-02-21', 'Pago', ''),
  ('demo007', 'Banco de Bogotá', 'digital', 'Salud', 'Consultas', false, 78000.00, 'gasto', 'cuenta', '2026-02-27', 'Consumo', ''),
  ('demo007', 'Bancolombia', 'digital', 'Alimentación', 'Supermercado', true, 78000.00, 'gasto', 'cuenta', '2026-03-22', 'Pago', ''),
  ('demo007', 'Bancolombia', 'digital', 'Educación', 'Libros', false, 122000.00, 'gasto', 'cuenta', '2026-03-23', 'Pago', ''),
  ('demo007', 'Efectivo', 'efectivo', 'Educación', 'Libros', false, 55000.00, 'gasto', 'efectivo', '2026-04-01', 'Servicio', ''),
  ('demo007', 'Daviplata', 'ahorros', 'Vivienda', 'Servicios', false, 78000.00, 'gasto', 'cuenta', '2026-05-04', 'Servicio', ''),
  ('demo007', 'Banco de Bogotá', 'digital', 'Educación', 'Libros', false, 72000.00, 'gasto', 'cuenta', '2026-05-04', 'Consumo', ''),
  ('demo007', 'Daviplata', 'ahorros', 'Salud', 'Consultas', false, 45000.00, 'gasto', 'cuenta', '2026-06-13', 'Compra', ''),
  ('demo007', 'Daviplata', 'ahorros', 'Educación', 'Libros', false, 45000.00, 'gasto', 'cuenta', '2026-06-28', 'Consumo', ''),
  ('demo008', 'Nequi', 'ahorros', 'Ingresos', 'Salario', false, 1200000.00, 'ingreso', 'cuenta', '2026-01-08', 'Ingreso extra', ''),
  ('demo008', 'Daviplata', 'ahorros', 'Ingresos', 'Otros ingresos', false, 2800000.00, 'ingreso', 'cuenta', '2026-01-09', 'Nomina', ''),
  ('demo008', 'Davivienda', 'ahorros', 'Educación', 'Cursos', false, 250000.00, 'gasto', 'cuenta', '2026-01-27', 'Consumo', ''),
  ('demo008', 'Davivienda', 'ahorros', 'Alimentación', 'Restaurante', false, 78000.00, 'gasto', 'cuenta', '2026-01-30', 'Compra', ''),
  ('demo008', 'Nequi', 'ahorros', 'Vivienda', 'Mantenimiento', true, 45000.00, 'gasto', 'cuenta', '2026-02-01', 'Compra', ''),
  ('demo008', 'Nequi', 'ahorros', 'Ingresos', 'Salario', true, 2800000.00, 'ingreso', 'cuenta', '2026-04-17', 'Nomina', ''),
  ('demo008', 'Nequi', 'ahorros', 'Salud', 'Medicamentos', false, 45000.00, 'gasto', 'cuenta', '2026-04-26', 'Consumo', ''),
  ('demo008', 'Davivienda', 'ahorros', 'Vivienda', 'Servicios', false, 12000.00, 'gasto', 'cuenta', '2026-05-19', 'Consumo', ''),
  ('demo008', 'Daviplata', 'ahorros', 'Ocio', 'Salidas', false, 45000.00, 'gasto', 'cuenta', '2026-06-10', 'Compra', ''),
  ('demo008', 'Daviplata', 'ahorros', 'Vivienda', 'Mantenimiento', true, 25000.00, 'gasto', 'cuenta', '2026-06-24', 'Pago', ''),
  ('demo009', 'Bancolombia', 'corriente', 'Ingresos', 'Salario', true, 2800000.00, 'ingreso', 'cuenta', '2026-01-14', 'Pago cliente', ''),
  ('demo009', 'Bancolombia', 'corriente', 'Transporte', 'Combustible', false, 120000.00, 'gasto', 'cuenta', '2026-02-07', 'Servicio', ''),
  ('demo009', 'BBVA', 'digital', 'Ocio', 'Salidas', true, 150000.00, 'gasto', 'cuenta', '2026-02-10', 'Compra', ''),
  ('demo009', 'Bancolombia', 'corriente', 'Educación', 'Cursos', true, 250000.00, 'gasto', 'cuenta', '2026-03-02', 'Compra', ''),
  ('demo009', 'Daviplata', 'digital', 'Salud', 'Medicamentos', false, 25000.00, 'gasto', 'cuenta', '2026-03-27', 'Servicio', ''),
  ('demo009', 'Efectivo', 'efectivo', 'Transporte', 'Combustible', false, 25000.00, 'gasto', 'efectivo', '2026-04-05', 'Compra', ''),
  ('demo009', 'Daviplata', 'digital', 'Transporte', 'Taxi / apps', false, 45000.00, 'gasto', 'cuenta', '2026-04-07', 'Consumo', ''),
  ('demo009', 'Daviplata', 'digital', 'Alimentación', 'Café', false, 180000.00, 'gasto', 'cuenta', '2026-04-10', 'Pago', ''),
  ('demo009', 'Bancolombia', 'corriente', 'Vivienda', 'Mantenimiento', false, 78000.00, 'gasto', 'cuenta', '2026-05-06', 'Servicio', ''),
  ('demo009', 'Efectivo', 'efectivo', 'Vivienda', 'Servicios', false, 25000.00, 'gasto', 'efectivo', '2026-05-07', 'Servicio', ''),
  ('demo009', 'Bancolombia', 'corriente', 'Transporte', 'Transporte público', true, 45000.00, 'gasto', 'cuenta', '2026-05-15', 'Compra', ''),
  ('demo009', 'Bancolombia', 'corriente', 'Vivienda', 'Mantenimiento', true, 120000.00, 'gasto', 'cuenta', '2026-05-20', 'Compra', ''),
  ('demo009', 'Efectivo', 'efectivo', 'Educación', 'Libros', false, 15000.00, 'gasto', 'efectivo', '2026-05-28', 'Pago', ''),
  ('demo009', 'Bancolombia', 'corriente', 'Salud', 'Consultas', false, 120000.00, 'gasto', 'cuenta', '2026-06-13', 'Servicio', ''),
  ('demo009', 'Bancolombia', 'corriente', 'Vivienda', 'Servicios', true, 45000.00, 'gasto', 'cuenta', '2026-06-26', 'Servicio', ''),
  ('demo010', 'BBVA', 'ahorros', 'Ingresos', 'Otros ingresos', false, 3500000.00, 'ingreso', 'cuenta', '2026-01-13', 'Pago cliente', ''),
  ('demo010', 'Daviplata', 'ahorros', 'Ingresos', 'Freelance', false, 800000.00, 'ingreso', 'cuenta', '2026-01-18', 'Nomina', ''),
  ('demo010', 'Daviplata', 'ahorros', 'Educación', 'Cursos', false, 12000.00, 'gasto', 'cuenta', '2026-02-05', 'Pago', ''),
  ('demo010', 'BBVA', 'ahorros', 'Transferencias', 'Entre mis cuentas', false, 100000.00, 'transferencia_salida', 'cuenta', '2026-02-19', 'Transferencia entre cuentas (salida)', '1a712f7e-a18d-4d18-8c93-364cdc1090b7')
) AS v(usuario, banco, tipo_cta, cat, sub, use_cp, monto, tipo, medio_pago, fecha, descripcion, grupo)
JOIN users u ON u.usuario = v.usuario
JOIN accounts a ON a.user_id = u.id AND a.banco = v.banco AND a.tipo = v.tipo_cta
JOIN categories c ON c.nombre = v.cat
JOIN sub_categories s ON s.category_id = c.id AND s.nombre = v.sub
LEFT JOIN LATERAL (
  SELECT id FROM counterparties WHERE user_id = u.id ORDER BY id LIMIT 1
) cp ON v.use_cp;

INSERT INTO transactions (account_id, category_id, sub_category_id, contraparte_id, monto, tipo, medio_pago, fecha, descripcion, activo, grupo_transferencia)
SELECT a.id, c.id, s.id, CASE WHEN v.use_cp THEN cp.id ELSE NULL END, v.monto::numeric, v.tipo, v.medio_pago, v.fecha::date, v.descripcion, true, NULLIF(v.grupo, '')
FROM (VALUES
  ('demo010', 'Nequi', 'digital', 'Transferencias', 'Entre mis cuentas', false, 100000.00, 'transferencia_entrada', 'cuenta', '2026-02-19', 'Transferencia entre cuentas (entrada)', '1a712f7e-a18d-4d18-8c93-364cdc1090b7'),
  ('demo010', 'BBVA', 'ahorros', 'Ingresos', 'Freelance', false, 1800000.00, 'ingreso', 'cuenta', '2026-03-22', 'Pago cliente', ''),
  ('demo010', 'BBVA', 'ahorros', 'Transporte', 'Taxi / apps', true, 180000.00, 'gasto', 'cuenta', '2026-04-07', 'Pago', ''),
  ('demo010', 'Daviplata', 'ahorros', 'Vivienda', 'Servicios', false, 180000.00, 'gasto', 'cuenta', '2026-04-10', 'Servicio', ''),
  ('demo010', 'BBVA', 'ahorros', 'Educación', 'Cursos', false, 45000.00, 'gasto', 'cuenta', '2026-04-23', 'Consumo', ''),
  ('demo010', 'Daviplata', 'ahorros', 'Educación', 'Cursos', false, 5000.00, 'gasto', 'cuenta', '2026-04-27', 'Consumo', ''),
  ('demo010', 'BBVA', 'ahorros', 'Educación', 'Cursos', false, 12000.00, 'gasto', 'cuenta', '2026-05-20', 'Consumo', ''),
  ('demo010', 'Nequi', 'digital', 'Vivienda', 'Mantenimiento', false, 180000.00, 'gasto', 'cuenta', '2026-06-01', 'Servicio', ''),
  ('demo010', 'BBVA', 'ahorros', 'Educación', 'Libros', true, 180000.00, 'gasto', 'cuenta', '2026-06-03', 'Compra', ''),
  ('demo010', 'Daviplata', 'ahorros', 'Salud', 'Medicamentos', true, 120000.00, 'gasto', 'cuenta', '2026-06-24', 'Consumo', ''),
  ('demo010', 'Daviplata', 'ahorros', 'Vivienda', 'Mantenimiento', false, 180000.00, 'gasto', 'cuenta', '2026-06-25', 'Compra', ''),
  ('demo010', 'Daviplata', 'ahorros', 'Educación', 'Libros', false, 5000.00, 'gasto', 'cuenta', '2026-07-01', 'Consumo', ''),
  ('demo011', 'Davivienda', 'digital', 'Ingresos', 'Otros ingresos', false, 1800000.00, 'ingreso', 'cuenta', '2026-01-12', 'Ingreso extra', ''),
  ('demo011', 'Banco de Bogotá', 'digital', 'Transferencias', 'Entre mis cuentas', false, 100000.00, 'transferencia_salida', 'cuenta', '2026-01-28', 'Retiro a efectivo (salida)', '1f23b76b-a5b2-41d4-ad9d-54031a52d2fa'),
  ('demo011', 'Efectivo', 'efectivo', 'Transferencias', 'Entre mis cuentas', false, 100000.00, 'transferencia_entrada', 'cuenta', '2026-01-28', 'Retiro a efectivo (entrada)', '1f23b76b-a5b2-41d4-ad9d-54031a52d2fa'),
  ('demo011', 'Davivienda', 'digital', 'Transporte', 'Combustible', false, 120000.00, 'gasto', 'cuenta', '2026-02-05', 'Pago', ''),
  ('demo011', 'Davivienda', 'digital', 'Alimentación', 'Café', false, 45000.00, 'gasto', 'cuenta', '2026-02-15', 'Servicio', ''),
  ('demo011', 'Efectivo', 'efectivo', 'Ocio', 'Salidas', true, 15000.00, 'gasto', 'efectivo', '2026-02-16', 'Compra', ''),
  ('demo011', 'Davivienda', 'digital', 'Transferencias', 'Entre mis cuentas', false, 50000.00, 'transferencia_salida', 'cuenta', '2026-03-06', 'Transferencia entre cuentas (salida)', '67558f51-7926-426b-9776-b29760d80571'),
  ('demo011', 'Banco de Bogotá', 'digital', 'Transferencias', 'Entre mis cuentas', false, 50000.00, 'transferencia_entrada', 'cuenta', '2026-03-06', 'Transferencia entre cuentas (entrada)', '67558f51-7926-426b-9776-b29760d80571'),
  ('demo011', 'Banco de Bogotá', 'digital', 'Ocio', 'Suscripciones', true, 25000.00, 'gasto', 'cuenta', '2026-03-23', 'Servicio', ''),
  ('demo011', 'Davivienda', 'digital', 'Ocio', 'Salidas', false, 25000.00, 'gasto', 'cuenta', '2026-03-27', 'Compra', ''),
  ('demo011', 'Davivienda', 'digital', 'Alimentación', 'Restaurante', true, 78000.00, 'gasto', 'cuenta', '2026-04-02', 'Consumo', ''),
  ('demo011', 'Davivienda', 'digital', 'Ocio', 'Cine', false, 45000.00, 'gasto', 'cuenta', '2026-04-13', 'Compra', ''),
  ('demo011', 'Efectivo', 'efectivo', 'Ocio', 'Cine', false, 15000.00, 'gasto', 'efectivo', '2026-04-27', 'Compra', ''),
  ('demo011', 'Banco de Bogotá', 'digital', 'Ingresos', 'Freelance', false, 800000.00, 'ingreso', 'cuenta', '2026-04-28', 'Nomina', ''),
  ('demo011', 'Efectivo', 'efectivo', 'Alimentación', 'Supermercado', false, 55000.00, 'gasto', 'efectivo', '2026-05-05', 'Compra', ''),
  ('demo011', 'Banco de Bogotá', 'digital', 'Vivienda', 'Arriendo', false, 25000.00, 'gasto', 'cuenta', '2026-05-16', 'Compra', ''),
  ('demo011', 'Banco de Bogotá', 'digital', 'Vivienda', 'Servicios', false, 45000.00, 'gasto', 'cuenta', '2026-05-20', 'Consumo', ''),
  ('demo011', 'Banco de Bogotá', 'digital', 'Transporte', 'Transporte público', false, 78000.00, 'gasto', 'cuenta', '2026-05-25', 'Pago', ''),
  ('demo011', 'Banco de Bogotá', 'digital', 'Alimentación', 'Supermercado', true, 12000.00, 'gasto', 'cuenta', '2026-06-01', 'Pago', ''),
  ('demo011', 'Efectivo', 'efectivo', 'Vivienda', 'Servicios', true, 80000.00, 'gasto', 'efectivo', '2026-06-15', 'Consumo', ''),
  ('demo012', 'Daviplata', 'corriente', 'Ingresos', 'Freelance', false, 2200000.00, 'ingreso', 'cuenta', '2026-01-11', 'Nomina', ''),
  ('demo012', 'Daviplata', 'corriente', 'Transferencias', 'Entre mis cuentas', false, 150000.00, 'transferencia_salida', 'cuenta', '2026-02-17', 'Retiro a efectivo (salida)', '68069c60-e99d-479b-8b32-eeda75fa30bf'),
  ('demo012', 'Efectivo', 'efectivo', 'Transferencias', 'Entre mis cuentas', false, 150000.00, 'transferencia_entrada', 'cuenta', '2026-02-17', 'Retiro a efectivo (entrada)', '68069c60-e99d-479b-8b32-eeda75fa30bf'),
  ('demo012', 'Bancolombia', 'digital', 'Transporte', 'Combustible', false, 150000.00, 'gasto', 'cuenta', '2026-02-19', 'Consumo', ''),
  ('demo012', 'Bancolombia', 'digital', 'Ingresos', 'Salario', true, 800000.00, 'ingreso', 'cuenta', '2026-03-09', 'Nomina', ''),
  ('demo012', 'Daviplata', 'corriente', 'Transporte', 'Transporte público', false, 120000.00, 'gasto', 'cuenta', '2026-03-29', 'Compra', ''),
  ('demo012', 'Bancolombia', 'digital', 'Ocio', 'Salidas', false, 12000.00, 'gasto', 'cuenta', '2026-04-11', 'Consumo', ''),
  ('demo012', 'Efectivo', 'efectivo', 'Ocio', 'Salidas', false, 80000.00, 'gasto', 'efectivo', '2026-05-21', 'Compra', '')
) AS v(usuario, banco, tipo_cta, cat, sub, use_cp, monto, tipo, medio_pago, fecha, descripcion, grupo)
JOIN users u ON u.usuario = v.usuario
JOIN accounts a ON a.user_id = u.id AND a.banco = v.banco AND a.tipo = v.tipo_cta
JOIN categories c ON c.nombre = v.cat
JOIN sub_categories s ON s.category_id = c.id AND s.nombre = v.sub
LEFT JOIN LATERAL (
  SELECT id FROM counterparties WHERE user_id = u.id ORDER BY id LIMIT 1
) cp ON v.use_cp;

INSERT INTO transactions (account_id, category_id, sub_category_id, contraparte_id, monto, tipo, medio_pago, fecha, descripcion, activo, grupo_transferencia)
SELECT a.id, c.id, s.id, CASE WHEN v.use_cp THEN cp.id ELSE NULL END, v.monto::numeric, v.tipo, v.medio_pago, v.fecha::date, v.descripcion, true, NULLIF(v.grupo, '')
FROM (VALUES
  ('demo012', 'Efectivo', 'efectivo', 'Salud', 'Medicamentos', true, 40000.00, 'gasto', 'efectivo', '2026-06-03', 'Consumo', ''),
  ('demo012', 'Daviplata', 'corriente', 'Educación', 'Libros', false, 25000.00, 'gasto', 'cuenta', '2026-06-07', 'Pago', ''),
  ('demo012', 'Bancolombia', 'digital', 'Transporte', 'Combustible', false, 120000.00, 'gasto', 'cuenta', '2026-06-16', 'Consumo', ''),
  ('demo012', 'Bancolombia', 'digital', 'Vivienda', 'Mantenimiento', true, 5000.00, 'gasto', 'cuenta', '2026-06-26', 'Compra', ''),
  ('demo012', 'Efectivo', 'efectivo', 'Salud', 'Medicamentos', false, 55000.00, 'gasto', 'efectivo', '2026-06-28', 'Consumo', ''),
  ('demo012', 'Daviplata', 'corriente', 'Ocio', 'Suscripciones', true, 25000.00, 'gasto', 'cuenta', '2026-06-29', 'Compra', ''),
  ('demo013', 'BBVA', 'corriente', 'Ingresos', 'Freelance', true, 1800000.00, 'ingreso', 'cuenta', '2026-01-18', 'Pago cliente', ''),
  ('demo013', 'Daviplata', 'digital', 'Ingresos', 'Freelance', true, 3500000.00, 'ingreso', 'cuenta', '2026-01-24', 'Nomina', ''),
  ('demo013', 'Efectivo', 'efectivo', 'Vivienda', 'Servicios', true, 40000.00, 'gasto', 'efectivo', '2026-01-27', 'Consumo', ''),
  ('demo013', 'BBVA', 'corriente', 'Transferencias', 'Entre mis cuentas', false, 300000.00, 'transferencia_salida', 'cuenta', '2026-02-10', 'Retiro a efectivo (salida)', 'b87948d8-1ba0-46a0-94b9-f364cb93ea47'),
  ('demo013', 'Efectivo', 'efectivo', 'Transferencias', 'Entre mis cuentas', false, 300000.00, 'transferencia_entrada', 'cuenta', '2026-02-10', 'Retiro a efectivo (entrada)', 'b87948d8-1ba0-46a0-94b9-f364cb93ea47'),
  ('demo013', 'BBVA', 'corriente', 'Alimentación', 'Supermercado', false, 180000.00, 'gasto', 'cuenta', '2026-02-16', 'Servicio', ''),
  ('demo013', 'Daviplata', 'digital', 'Ocio', 'Suscripciones', true, 180000.00, 'gasto', 'cuenta', '2026-02-17', 'Servicio', ''),
  ('demo013', 'Daviplata', 'digital', 'Salud', 'Consultas', false, 5000.00, 'gasto', 'cuenta', '2026-03-15', 'Pago', ''),
  ('demo013', 'Davivienda', 'digital', 'Ocio', 'Cine', false, 150000.00, 'gasto', 'cuenta', '2026-03-29', 'Compra', ''),
  ('demo013', 'BBVA', 'corriente', 'Transferencias', 'Entre mis cuentas', false, 150000.00, 'transferencia_salida', 'cuenta', '2026-03-31', 'Transferencia entre cuentas (salida)', '032303c7-3ae3-48d5-94ef-a4dca35e352f'),
  ('demo013', 'Daviplata', 'digital', 'Transferencias', 'Entre mis cuentas', false, 150000.00, 'transferencia_entrada', 'cuenta', '2026-03-31', 'Transferencia entre cuentas (entrada)', '032303c7-3ae3-48d5-94ef-a4dca35e352f'),
  ('demo013', 'Daviplata', 'digital', 'Salud', 'Consultas', true, 78000.00, 'gasto', 'cuenta', '2026-04-17', 'Pago', ''),
  ('demo013', 'BBVA', 'corriente', 'Transporte', 'Combustible', false, 12000.00, 'gasto', 'cuenta', '2026-05-05', 'Pago', ''),
  ('demo013', 'Daviplata', 'digital', 'Transporte', 'Transporte público', true, 120000.00, 'gasto', 'cuenta', '2026-05-09', 'Pago', ''),
  ('demo013', 'Daviplata', 'digital', 'Transporte', 'Taxi / apps', false, 45000.00, 'gasto', 'cuenta', '2026-05-23', 'Pago', ''),
  ('demo013', 'BBVA', 'corriente', 'Educación', 'Cursos', false, 250000.00, 'gasto', 'cuenta', '2026-06-02', 'Servicio', ''),
  ('demo014', 'BBVA', 'ahorros', 'Transferencias', 'Entre mis cuentas', false, 50000.00, 'transferencia_salida', 'cuenta', '2026-01-13', 'Retiro a efectivo (salida)', '700385eb-9de3-4912-b5d7-319a9d948025'),
  ('demo014', 'Efectivo', 'efectivo', 'Transferencias', 'Entre mis cuentas', false, 50000.00, 'transferencia_entrada', 'cuenta', '2026-01-13', 'Retiro a efectivo (entrada)', '700385eb-9de3-4912-b5d7-319a9d948025'),
  ('demo014', 'BBVA', 'ahorros', 'Ingresos', 'Freelance', false, 3500000.00, 'ingreso', 'cuenta', '2026-01-14', 'Pago cliente', ''),
  ('demo014', 'Banco de Bogotá', 'corriente', 'Ocio', 'Cine', false, 25000.00, 'gasto', 'cuenta', '2026-01-23', 'Consumo', ''),
  ('demo014', 'Efectivo', 'efectivo', 'Ocio', 'Salidas', false, 25000.00, 'gasto', 'efectivo', '2026-02-10', 'Consumo', ''),
  ('demo014', 'Efectivo', 'efectivo', 'Salud', 'Consultas', true, 5000.00, 'gasto', 'efectivo', '2026-02-15', 'Compra', ''),
  ('demo014', 'Banco de Bogotá', 'corriente', 'Salud', 'Medicamentos', false, 25000.00, 'gasto', 'cuenta', '2026-03-02', 'Consumo', ''),
  ('demo014', 'Efectivo', 'efectivo', 'Alimentación', 'Café', false, 15000.00, 'gasto', 'efectivo', '2026-04-17', 'Pago', ''),
  ('demo014', 'Davivienda', 'digital', 'Transporte', 'Transporte público', true, 150000.00, 'gasto', 'cuenta', '2026-05-08', 'Compra', ''),
  ('demo014', 'BBVA', 'ahorros', 'Ocio', 'Salidas', true, 12000.00, 'gasto', 'cuenta', '2026-05-14', 'Consumo', ''),
  ('demo014', 'Efectivo', 'efectivo', 'Salud', 'Consultas', true, 10000.00, 'gasto', 'efectivo', '2026-05-29', 'Servicio', ''),
  ('demo014', 'BBVA', 'ahorros', 'Alimentación', 'Café', false, 25000.00, 'gasto', 'cuenta', '2026-06-03', 'Consumo', ''),
  ('demo014', 'BBVA', 'ahorros', 'Salud', 'Consultas', false, 5000.00, 'gasto', 'cuenta', '2026-06-08', 'Pago', ''),
  ('demo014', 'BBVA', 'ahorros', 'Transporte', 'Taxi / apps', false, 25000.00, 'gasto', 'cuenta', '2026-06-10', 'Pago', ''),
  ('demo014', 'BBVA', 'ahorros', 'Ocio', 'Cine', false, 180000.00, 'gasto', 'cuenta', '2026-06-16', 'Pago', ''),
  ('demo015', 'BBVA', 'corriente', 'Ingresos', 'Freelance', false, 800000.00, 'ingreso', 'cuenta', '2026-01-10', 'Nomina', ''),
  ('demo015', 'BBVA', 'corriente', 'Ocio', 'Suscripciones', true, 45000.00, 'gasto', 'cuenta', '2026-02-04', 'Compra', ''),
  ('demo015', 'Davivienda', 'corriente', 'Transporte', 'Combustible', false, 100000.00, 'gasto', 'cuenta', '2026-02-09', 'Consumo', '')
) AS v(usuario, banco, tipo_cta, cat, sub, use_cp, monto, tipo, medio_pago, fecha, descripcion, grupo)
JOIN users u ON u.usuario = v.usuario
JOIN accounts a ON a.user_id = u.id AND a.banco = v.banco AND a.tipo = v.tipo_cta
JOIN categories c ON c.nombre = v.cat
JOIN sub_categories s ON s.category_id = c.id AND s.nombre = v.sub
LEFT JOIN LATERAL (
  SELECT id FROM counterparties WHERE user_id = u.id ORDER BY id LIMIT 1
) cp ON v.use_cp;

INSERT INTO transactions (account_id, category_id, sub_category_id, contraparte_id, monto, tipo, medio_pago, fecha, descripcion, activo, grupo_transferencia)
SELECT a.id, c.id, s.id, CASE WHEN v.use_cp THEN cp.id ELSE NULL END, v.monto::numeric, v.tipo, v.medio_pago, v.fecha::date, v.descripcion, true, NULLIF(v.grupo, '')
FROM (VALUES
  ('demo015', 'BBVA', 'corriente', 'Transporte', 'Transporte público', false, 250000.00, 'gasto', 'cuenta', '2026-02-20', 'Servicio', ''),
  ('demo015', 'Efectivo', 'efectivo', 'Vivienda', 'Mantenimiento', false, 5000.00, 'gasto', 'efectivo', '2026-03-18', 'Pago', ''),
  ('demo015', 'BBVA', 'corriente', 'Salud', 'Medicamentos', true, 12000.00, 'gasto', 'cuenta', '2026-03-24', 'Pago', ''),
  ('demo015', 'BBVA', 'corriente', 'Ingresos', 'Otros ingresos', true, 3500000.00, 'ingreso', 'cuenta', '2026-04-17', 'Pago cliente', ''),
  ('demo015', 'BBVA', 'corriente', 'Vivienda', 'Servicios', true, 5000.00, 'gasto', 'cuenta', '2026-05-09', 'Pago', ''),
  ('demo016', 'BBVA', 'digital', 'Transferencias', 'Entre mis cuentas', false, 50000.00, 'transferencia_salida', 'cuenta', '2026-01-14', 'Retiro a efectivo (salida)', 'faccd912-3c25-4853-be36-d8b12edc9fa0'),
  ('demo016', 'Efectivo', 'efectivo', 'Transferencias', 'Entre mis cuentas', false, 50000.00, 'transferencia_entrada', 'cuenta', '2026-01-14', 'Retiro a efectivo (entrada)', 'faccd912-3c25-4853-be36-d8b12edc9fa0'),
  ('demo016', 'Daviplata', 'corriente', 'Ingresos', 'Freelance', true, 2800000.00, 'ingreso', 'cuenta', '2026-01-15', 'Pago cliente', ''),
  ('demo016', 'BBVA', 'digital', 'Ingresos', 'Freelance', false, 1800000.00, 'ingreso', 'cuenta', '2026-01-15', 'Nomina', ''),
  ('demo016', 'Daviplata', 'corriente', 'Transporte', 'Combustible', false, 78000.00, 'gasto', 'cuenta', '2026-01-24', 'Consumo', ''),
  ('demo016', 'Daviplata', 'corriente', 'Ocio', 'Suscripciones', false, 250000.00, 'gasto', 'cuenta', '2026-01-31', 'Consumo', ''),
  ('demo016', 'Efectivo', 'efectivo', 'Educación', 'Libros', false, 25000.00, 'gasto', 'efectivo', '2026-02-01', 'Consumo', ''),
  ('demo016', 'Daviplata', 'corriente', 'Ocio', 'Salidas', false, 12000.00, 'gasto', 'cuenta', '2026-02-18', 'Compra', ''),
  ('demo016', 'BBVA', 'digital', 'Salud', 'Consultas', true, 78000.00, 'gasto', 'cuenta', '2026-03-02', 'Compra', ''),
  ('demo016', 'Efectivo', 'efectivo', 'Salud', 'Medicamentos', false, 55000.00, 'gasto', 'efectivo', '2026-04-12', 'Consumo', ''),
  ('demo016', 'Daviplata', 'corriente', 'Educación', 'Cursos', false, 25000.00, 'gasto', 'cuenta', '2026-05-12', 'Consumo', ''),
  ('demo016', 'Daviplata', 'corriente', 'Vivienda', 'Mantenimiento', true, 180000.00, 'gasto', 'cuenta', '2026-05-13', 'Compra', ''),
  ('demo016', 'Daviplata', 'corriente', 'Transporte', 'Taxi / apps', true, 120000.00, 'gasto', 'cuenta', '2026-05-17', 'Compra', ''),
  ('demo016', 'Daviplata', 'corriente', 'Transporte', 'Transporte público', true, 5000.00, 'gasto', 'cuenta', '2026-06-25', 'Compra', ''),
  ('demo017', 'Daviplata', 'corriente', 'Ingresos', 'Freelance', false, 3500000.00, 'ingreso', 'cuenta', '2026-01-16', 'Ingreso extra', ''),
  ('demo017', 'Daviplata', 'corriente', 'Ingresos', 'Otros ingresos', false, 2800000.00, 'ingreso', 'cuenta', '2026-01-17', 'Pago cliente', ''),
  ('demo017', 'Daviplata', 'corriente', 'Transferencias', 'Entre mis cuentas', false, 80000.00, 'transferencia_salida', 'cuenta', '2026-01-21', 'Retiro a efectivo (salida)', 'fc2554ee-8195-4d32-ad5b-3c8233975a3a'),
  ('demo017', 'Efectivo', 'efectivo', 'Transferencias', 'Entre mis cuentas', false, 80000.00, 'transferencia_entrada', 'cuenta', '2026-01-21', 'Retiro a efectivo (entrada)', 'fc2554ee-8195-4d32-ad5b-3c8233975a3a'),
  ('demo017', 'Daviplata', 'corriente', 'Vivienda', 'Servicios', false, 120000.00, 'gasto', 'cuenta', '2026-03-11', 'Compra', ''),
  ('demo017', 'Daviplata', 'corriente', 'Educación', 'Libros', true, 45000.00, 'gasto', 'cuenta', '2026-03-23', 'Compra', ''),
  ('demo017', 'BBVA', 'ahorros', 'Transporte', 'Transporte público', true, 200000.00, 'gasto', 'cuenta', '2026-03-24', 'Compra', ''),
  ('demo017', 'Efectivo', 'efectivo', 'Alimentación', 'Café', false, 80000.00, 'gasto', 'efectivo', '2026-05-18', 'Pago', ''),
  ('demo017', 'Daviplata', 'corriente', 'Educación', 'Cursos', true, 250000.00, 'gasto', 'cuenta', '2026-05-21', 'Consumo', ''),
  ('demo017', 'Daviplata', 'corriente', 'Transferencias', 'Entre mis cuentas', false, 150000.00, 'transferencia_salida', 'cuenta', '2026-05-26', 'Transferencia entre cuentas (salida)', '91eeda94-fc0e-4be0-94ce-ceece786d8a7'),
  ('demo017', 'BBVA', 'ahorros', 'Transferencias', 'Entre mis cuentas', false, 150000.00, 'transferencia_entrada', 'cuenta', '2026-05-26', 'Transferencia entre cuentas (entrada)', '91eeda94-fc0e-4be0-94ce-ceece786d8a7'),
  ('demo017', 'Daviplata', 'corriente', 'Transporte', 'Transporte público', true, 12000.00, 'gasto', 'cuenta', '2026-06-21', 'Consumo', ''),
  ('demo018', 'Davivienda', 'digital', 'Ingresos', 'Salario', false, 2200000.00, 'ingreso', 'cuenta', '2026-01-18', 'Pago cliente', ''),
  ('demo018', 'Bancolombia', 'corriente', 'Ingresos', 'Salario', true, 1800000.00, 'ingreso', 'cuenta', '2026-01-22', 'Pago cliente', ''),
  ('demo018', 'Davivienda', 'digital', 'Transporte', 'Transporte público', true, 45000.00, 'gasto', 'cuenta', '2026-02-01', 'Compra', ''),
  ('demo018', 'Davivienda', 'digital', 'Vivienda', 'Servicios', false, 180000.00, 'gasto', 'cuenta', '2026-02-04', 'Pago', ''),
  ('demo018', 'Bancolombia', 'corriente', 'Transferencias', 'Entre mis cuentas', false, 200000.00, 'transferencia_salida', 'cuenta', '2026-02-04', 'Retiro a efectivo (salida)', '0cad2fe1-a211-4f6a-af51-6287ba01c3a8'),
  ('demo018', 'Efectivo', 'efectivo', 'Transferencias', 'Entre mis cuentas', false, 200000.00, 'transferencia_entrada', 'cuenta', '2026-02-04', 'Retiro a efectivo (entrada)', '0cad2fe1-a211-4f6a-af51-6287ba01c3a8'),
  ('demo018', 'Nequi', 'digital', 'Vivienda', 'Arriendo', false, 120000.00, 'gasto', 'cuenta', '2026-02-26', 'Pago', ''),
  ('demo018', 'Nequi', 'digital', 'Educación', 'Libros', false, 30000.00, 'gasto', 'cuenta', '2026-03-20', 'Consumo', ''),
  ('demo018', 'Bancolombia', 'corriente', 'Educación', 'Cursos', true, 180000.00, 'gasto', 'cuenta', '2026-04-01', 'Pago', '')
) AS v(usuario, banco, tipo_cta, cat, sub, use_cp, monto, tipo, medio_pago, fecha, descripcion, grupo)
JOIN users u ON u.usuario = v.usuario
JOIN accounts a ON a.user_id = u.id AND a.banco = v.banco AND a.tipo = v.tipo_cta
JOIN categories c ON c.nombre = v.cat
JOIN sub_categories s ON s.category_id = c.id AND s.nombre = v.sub
LEFT JOIN LATERAL (
  SELECT id FROM counterparties WHERE user_id = u.id ORDER BY id LIMIT 1
) cp ON v.use_cp;

INSERT INTO transactions (account_id, category_id, sub_category_id, contraparte_id, monto, tipo, medio_pago, fecha, descripcion, activo, grupo_transferencia)
SELECT a.id, c.id, s.id, CASE WHEN v.use_cp THEN cp.id ELSE NULL END, v.monto::numeric, v.tipo, v.medio_pago, v.fecha::date, v.descripcion, true, NULLIF(v.grupo, '')
FROM (VALUES
  ('demo018', 'Davivienda', 'digital', 'Alimentación', 'Restaurante', false, 5000.00, 'gasto', 'cuenta', '2026-04-03', 'Consumo', ''),
  ('demo018', 'Efectivo', 'efectivo', 'Alimentación', 'Supermercado', false, 15000.00, 'gasto', 'efectivo', '2026-04-14', 'Compra', ''),
  ('demo018', 'Efectivo', 'efectivo', 'Ocio', 'Cine', false, 15000.00, 'gasto', 'efectivo', '2026-04-15', 'Servicio', ''),
  ('demo018', 'Davivienda', 'digital', 'Vivienda', 'Arriendo', false, 5000.00, 'gasto', 'cuenta', '2026-04-30', 'Consumo', ''),
  ('demo018', 'Bancolombia', 'corriente', 'Educación', 'Cursos', false, 180000.00, 'gasto', 'cuenta', '2026-05-03', 'Consumo', ''),
  ('demo018', 'Nequi', 'digital', 'Ingresos', 'Otros ingresos', true, 3500000.00, 'ingreso', 'cuenta', '2026-05-09', 'Nomina', ''),
  ('demo018', 'Bancolombia', 'corriente', 'Ocio', 'Cine', false, 180000.00, 'gasto', 'cuenta', '2026-05-09', 'Consumo', ''),
  ('demo018', 'Davivienda', 'digital', 'Vivienda', 'Arriendo', false, 25000.00, 'gasto', 'cuenta', '2026-05-13', 'Servicio', ''),
  ('demo018', 'Bancolombia', 'corriente', 'Transporte', 'Transporte público', false, 5000.00, 'gasto', 'cuenta', '2026-05-20', 'Consumo', ''),
  ('demo018', 'Nequi', 'digital', 'Transporte', 'Transporte público', true, 250000.00, 'gasto', 'cuenta', '2026-05-20', 'Pago', ''),
  ('demo018', 'Nequi', 'digital', 'Transporte', 'Taxi / apps', false, 120000.00, 'gasto', 'cuenta', '2026-06-30', 'Servicio', ''),
  ('demo019', 'Davivienda', 'corriente', 'Ingresos', 'Otros ingresos', false, 3500000.00, 'ingreso', 'cuenta', '2026-01-13', 'Ingreso extra', ''),
  ('demo019', 'Banco de Bogotá', 'corriente', 'Vivienda', 'Arriendo', true, 150000.00, 'gasto', 'cuenta', '2026-02-02', 'Pago', ''),
  ('demo019', 'Daviplata', 'ahorros', 'Transferencias', 'Entre mis cuentas', false, 100000.00, 'transferencia_salida', 'cuenta', '2026-02-14', 'Retiro a efectivo (salida)', '137999f8-c6a3-49d3-809d-76599a1e0210'),
  ('demo019', 'Efectivo', 'efectivo', 'Transferencias', 'Entre mis cuentas', false, 100000.00, 'transferencia_entrada', 'cuenta', '2026-02-14', 'Retiro a efectivo (entrada)', '137999f8-c6a3-49d3-809d-76599a1e0210'),
  ('demo019', 'Daviplata', 'ahorros', 'Salud', 'Medicamentos', false, 78000.00, 'gasto', 'cuenta', '2026-02-22', 'Pago', ''),
  ('demo019', 'Efectivo', 'efectivo', 'Ocio', 'Cine', true, 25000.00, 'gasto', 'efectivo', '2026-03-10', 'Consumo', ''),
  ('demo019', 'Davivienda', 'corriente', 'Ocio', 'Suscripciones', false, 180000.00, 'gasto', 'cuenta', '2026-03-11', 'Consumo', ''),
  ('demo019', 'Daviplata', 'ahorros', 'Alimentación', 'Restaurante', false, 22000.00, 'gasto', 'cuenta', '2026-03-12', 'Consumo', ''),
  ('demo019', 'Daviplata', 'ahorros', 'Ingresos', 'Freelance', false, 1800000.00, 'ingreso', 'cuenta', '2026-03-31', 'Ingreso extra', ''),
  ('demo019', 'Efectivo', 'efectivo', 'Vivienda', 'Arriendo', false, 25000.00, 'gasto', 'efectivo', '2026-04-15', 'Pago', ''),
  ('demo019', 'Daviplata', 'ahorros', 'Vivienda', 'Servicios', true, 12000.00, 'gasto', 'cuenta', '2026-05-03', 'Pago', ''),
  ('demo019', 'Davivienda', 'corriente', 'Transferencias', 'Entre mis cuentas', false, 300000.00, 'transferencia_salida', 'cuenta', '2026-05-05', 'Transferencia entre cuentas (salida)', 'e5dc6865-b82f-4562-80c2-c1b11d5887fb'),
  ('demo019', 'Daviplata', 'ahorros', 'Transferencias', 'Entre mis cuentas', false, 300000.00, 'transferencia_entrada', 'cuenta', '2026-05-05', 'Transferencia entre cuentas (entrada)', 'e5dc6865-b82f-4562-80c2-c1b11d5887fb'),
  ('demo019', 'Daviplata', 'ahorros', 'Transporte', 'Combustible', true, 5000.00, 'gasto', 'cuenta', '2026-05-18', 'Servicio', ''),
  ('demo019', 'Efectivo', 'efectivo', 'Transporte', 'Combustible', true, 25000.00, 'gasto', 'efectivo', '2026-05-22', 'Pago', ''),
  ('demo019', 'Davivienda', 'corriente', 'Ocio', 'Salidas', false, 25000.00, 'gasto', 'cuenta', '2026-05-26', 'Servicio', ''),
  ('demo019', 'Daviplata', 'ahorros', 'Salud', 'Consultas', false, 78000.00, 'gasto', 'cuenta', '2026-05-30', 'Consumo', ''),
  ('demo019', 'Daviplata', 'ahorros', 'Alimentación', 'Restaurante', false, 45000.00, 'gasto', 'cuenta', '2026-06-10', 'Pago', ''),
  ('demo019', 'Efectivo', 'efectivo', 'Transporte', 'Taxi / apps', false, 80000.00, 'gasto', 'efectivo', '2026-06-10', 'Compra', ''),
  ('demo020', 'Banco de Bogotá', 'corriente', 'Ingresos', 'Freelance', false, 1800000.00, 'ingreso', 'cuenta', '2026-01-22', 'Nomina', ''),
  ('demo020', 'Daviplata', 'digital', 'Salud', 'Medicamentos', true, 120000.00, 'gasto', 'cuenta', '2026-02-10', 'Compra', ''),
  ('demo020', 'Efectivo', 'efectivo', 'Vivienda', 'Servicios', false, 15000.00, 'gasto', 'efectivo', '2026-03-02', 'Compra', ''),
  ('demo020', 'Daviplata', 'digital', 'Transporte', 'Taxi / apps', false, 78000.00, 'gasto', 'cuenta', '2026-03-04', 'Servicio', ''),
  ('demo020', 'Bancolombia', 'digital', 'Ingresos', 'Otros ingresos', false, 1800000.00, 'ingreso', 'cuenta', '2026-03-29', 'Nomina', ''),
  ('demo020', 'Banco de Bogotá', 'corriente', 'Transporte', 'Transporte público', true, 45000.00, 'gasto', 'cuenta', '2026-04-12', 'Servicio', ''),
  ('demo020', 'Bancolombia', 'digital', 'Ocio', 'Salidas', false, 120000.00, 'gasto', 'cuenta', '2026-05-01', 'Servicio', ''),
  ('demo020', 'Bancolombia', 'digital', 'Vivienda', 'Servicios', false, 45000.00, 'gasto', 'cuenta', '2026-05-02', 'Compra', ''),
  ('demo020', 'Bancolombia', 'digital', 'Alimentación', 'Café', true, 120000.00, 'gasto', 'cuenta', '2026-05-08', 'Compra', ''),
  ('demo020', 'Efectivo', 'efectivo', 'Vivienda', 'Arriendo', true, 40000.00, 'gasto', 'efectivo', '2026-05-28', 'Pago', '')
) AS v(usuario, banco, tipo_cta, cat, sub, use_cp, monto, tipo, medio_pago, fecha, descripcion, grupo)
JOIN users u ON u.usuario = v.usuario
JOIN accounts a ON a.user_id = u.id AND a.banco = v.banco AND a.tipo = v.tipo_cta
JOIN categories c ON c.nombre = v.cat
JOIN sub_categories s ON s.category_id = c.id AND s.nombre = v.sub
LEFT JOIN LATERAL (
  SELECT id FROM counterparties WHERE user_id = u.id ORDER BY id LIMIT 1
) cp ON v.use_cp;

INSERT INTO transactions (account_id, category_id, sub_category_id, contraparte_id, monto, tipo, medio_pago, fecha, descripcion, activo, grupo_transferencia)
SELECT a.id, c.id, s.id, CASE WHEN v.use_cp THEN cp.id ELSE NULL END, v.monto::numeric, v.tipo, v.medio_pago, v.fecha::date, v.descripcion, true, NULLIF(v.grupo, '')
FROM (VALUES
  ('demo020', 'Bancolombia', 'digital', 'Transporte', 'Combustible', false, 250000.00, 'gasto', 'cuenta', '2026-05-30', 'Pago', ''),
  ('demo020', 'Daviplata', 'digital', 'Educación', 'Cursos', false, 2000.00, 'gasto', 'cuenta', '2026-06-24', 'Compra', ''),
  ('demo020', 'Bancolombia', 'digital', 'Educación', 'Cursos', false, 180000.00, 'gasto', 'cuenta', '2026-07-01', 'Compra', ''),
  ('demo021', 'Nequi', 'digital', 'Ingresos', 'Salario', false, 2800000.00, 'ingreso', 'cuenta', '2026-01-17', 'Ingreso extra', ''),
  ('demo021', 'Bancolombia', 'corriente', 'Salud', 'Medicamentos', false, 5000.00, 'gasto', 'cuenta', '2026-02-02', 'Servicio', ''),
  ('demo021', 'Daviplata', 'digital', 'Ocio', 'Suscripciones', true, 50000.00, 'gasto', 'cuenta', '2026-02-12', 'Pago', ''),
  ('demo021', 'Nequi', 'digital', 'Vivienda', 'Mantenimiento', false, 25000.00, 'gasto', 'cuenta', '2026-02-16', 'Pago', ''),
  ('demo021', 'Bancolombia', 'corriente', 'Ingresos', 'Freelance', false, 3500000.00, 'ingreso', 'cuenta', '2026-04-08', 'Ingreso extra', ''),
  ('demo021', 'Bancolombia', 'corriente', 'Vivienda', 'Arriendo', true, 45000.00, 'gasto', 'cuenta', '2026-04-12', 'Compra', ''),
  ('demo021', 'Bancolombia', 'corriente', 'Alimentación', 'Restaurante', false, 250000.00, 'gasto', 'cuenta', '2026-04-19', 'Pago', ''),
  ('demo021', 'Nequi', 'digital', 'Vivienda', 'Servicios', false, 250000.00, 'gasto', 'cuenta', '2026-04-19', 'Pago', ''),
  ('demo021', 'Bancolombia', 'corriente', 'Salud', 'Medicamentos', false, 25000.00, 'gasto', 'cuenta', '2026-04-20', 'Pago', ''),
  ('demo021', 'Bancolombia', 'corriente', 'Transporte', 'Transporte público', false, 78000.00, 'gasto', 'cuenta', '2026-06-29', 'Pago', ''),
  ('demo022', 'BBVA', 'digital', 'Ingresos', 'Otros ingresos', false, 800000.00, 'ingreso', 'cuenta', '2026-01-11', 'Ingreso extra', ''),
  ('demo022', 'Banco de Bogotá', 'digital', 'Ingresos', 'Freelance', false, 1800000.00, 'ingreso', 'cuenta', '2026-01-17', 'Ingreso extra', ''),
  ('demo022', 'Banco de Bogotá', 'digital', 'Transferencias', 'Entre mis cuentas', false, 50000.00, 'transferencia_salida', 'cuenta', '2026-01-27', 'Retiro a efectivo (salida)', 'fa301d89-aaa6-4722-ac0b-803ec02d02dd'),
  ('demo022', 'Efectivo', 'efectivo', 'Transferencias', 'Entre mis cuentas', false, 50000.00, 'transferencia_entrada', 'cuenta', '2026-01-27', 'Retiro a efectivo (entrada)', 'fa301d89-aaa6-4722-ac0b-803ec02d02dd'),
  ('demo022', 'Efectivo', 'efectivo', 'Alimentación', 'Café', false, 80000.00, 'gasto', 'efectivo', '2026-02-10', 'Pago', ''),
  ('demo022', 'Bancolombia', 'digital', 'Educación', 'Libros', false, 45000.00, 'gasto', 'cuenta', '2026-02-17', 'Pago', ''),
  ('demo022', 'Efectivo', 'efectivo', 'Salud', 'Medicamentos', true, 15000.00, 'gasto', 'efectivo', '2026-04-15', 'Compra', ''),
  ('demo022', 'Banco de Bogotá', 'digital', 'Educación', 'Libros', false, 12000.00, 'gasto', 'cuenta', '2026-04-29', 'Pago', ''),
  ('demo022', 'Bancolombia', 'digital', 'Ocio', 'Suscripciones', false, 45000.00, 'gasto', 'cuenta', '2026-04-30', 'Pago', ''),
  ('demo022', 'BBVA', 'digital', 'Educación', 'Cursos', true, 180000.00, 'gasto', 'cuenta', '2026-05-29', 'Consumo', ''),
  ('demo022', 'BBVA', 'digital', 'Educación', 'Cursos', false, 250000.00, 'gasto', 'cuenta', '2026-06-05', 'Compra', ''),
  ('demo022', 'Bancolombia', 'digital', 'Salud', 'Consultas', true, 60000.00, 'gasto', 'cuenta', '2026-06-06', 'Pago', ''),
  ('demo023', 'Banco de Bogotá', 'corriente', 'Ingresos', 'Otros ingresos', true, 1200000.00, 'ingreso', 'cuenta', '2026-01-17', 'Nomina', ''),
  ('demo023', 'Davivienda', 'digital', 'Ingresos', 'Salario', false, 800000.00, 'ingreso', 'cuenta', '2026-01-19', 'Ingreso extra', ''),
  ('demo023', 'Davivienda', 'digital', 'Educación', 'Libros', true, 250000.00, 'gasto', 'cuenta', '2026-01-23', 'Compra', ''),
  ('demo023', 'Banco de Bogotá', 'corriente', 'Alimentación', 'Supermercado', false, 5000.00, 'gasto', 'cuenta', '2026-01-30', 'Consumo', ''),
  ('demo023', 'Efectivo', 'efectivo', 'Alimentación', 'Supermercado', false, 15000.00, 'gasto', 'efectivo', '2026-02-03', 'Servicio', ''),
  ('demo023', 'Davivienda', 'digital', 'Transporte', 'Combustible', true, 12000.00, 'gasto', 'cuenta', '2026-02-19', 'Pago', ''),
  ('demo023', 'Banco de Bogotá', 'corriente', 'Vivienda', 'Mantenimiento', true, 120000.00, 'gasto', 'cuenta', '2026-02-27', 'Servicio', ''),
  ('demo023', 'Banco de Bogotá', 'corriente', 'Vivienda', 'Servicios', true, 250000.00, 'gasto', 'cuenta', '2026-02-27', 'Pago', ''),
  ('demo023', 'Davivienda', 'digital', 'Alimentación', 'Café', true, 5000.00, 'gasto', 'cuenta', '2026-03-03', 'Servicio', ''),
  ('demo023', 'Banco de Bogotá', 'corriente', 'Alimentación', 'Supermercado', true, 5000.00, 'gasto', 'cuenta', '2026-04-15', 'Pago', ''),
  ('demo023', 'Banco de Bogotá', 'corriente', 'Transporte', 'Combustible', true, 120000.00, 'gasto', 'cuenta', '2026-05-12', 'Compra', ''),
  ('demo023', 'Banco de Bogotá', 'corriente', 'Alimentación', 'Restaurante', false, 78000.00, 'gasto', 'cuenta', '2026-05-20', 'Compra', ''),
  ('demo023', 'Banco de Bogotá', 'corriente', 'Transporte', 'Taxi / apps', true, 5000.00, 'gasto', 'cuenta', '2026-05-29', 'Consumo', ''),
  ('demo023', 'Davivienda', 'digital', 'Ocio', 'Suscripciones', true, 25000.00, 'gasto', 'cuenta', '2026-06-02', 'Compra', ''),
  ('demo023', 'Davivienda', 'digital', 'Salud', 'Consultas', false, 180000.00, 'gasto', 'cuenta', '2026-06-03', 'Servicio', '')
) AS v(usuario, banco, tipo_cta, cat, sub, use_cp, monto, tipo, medio_pago, fecha, descripcion, grupo)
JOIN users u ON u.usuario = v.usuario
JOIN accounts a ON a.user_id = u.id AND a.banco = v.banco AND a.tipo = v.tipo_cta
JOIN categories c ON c.nombre = v.cat
JOIN sub_categories s ON s.category_id = c.id AND s.nombre = v.sub
LEFT JOIN LATERAL (
  SELECT id FROM counterparties WHERE user_id = u.id ORDER BY id LIMIT 1
) cp ON v.use_cp;

INSERT INTO transactions (account_id, category_id, sub_category_id, contraparte_id, monto, tipo, medio_pago, fecha, descripcion, activo, grupo_transferencia)
SELECT a.id, c.id, s.id, CASE WHEN v.use_cp THEN cp.id ELSE NULL END, v.monto::numeric, v.tipo, v.medio_pago, v.fecha::date, v.descripcion, true, NULLIF(v.grupo, '')
FROM (VALUES
  ('demo023', 'Davivienda', 'digital', 'Ocio', 'Cine', true, 12000.00, 'gasto', 'cuenta', '2026-06-28', 'Compra', ''),
  ('demo024', 'Bancolombia', 'corriente', 'Ingresos', 'Otros ingresos', false, 2800000.00, 'ingreso', 'cuenta', '2026-01-09', 'Ingreso extra', ''),
  ('demo024', 'Davivienda', 'corriente', 'Ocio', 'Cine', false, 12000.00, 'gasto', 'cuenta', '2026-01-17', 'Compra', ''),
  ('demo024', 'Davivienda', 'corriente', 'Transferencias', 'Entre mis cuentas', false, 100000.00, 'transferencia_salida', 'cuenta', '2026-01-30', 'Retiro a efectivo (salida)', '710b30c4-0afa-4678-8b5f-4b92f89701a2'),
  ('demo024', 'Efectivo', 'efectivo', 'Transferencias', 'Entre mis cuentas', false, 100000.00, 'transferencia_entrada', 'cuenta', '2026-01-30', 'Retiro a efectivo (entrada)', '710b30c4-0afa-4678-8b5f-4b92f89701a2'),
  ('demo024', 'Bancolombia', 'corriente', 'Salud', 'Medicamentos', true, 5000.00, 'gasto', 'cuenta', '2026-02-08', 'Servicio', ''),
  ('demo024', 'Davivienda', 'corriente', 'Transporte', 'Taxi / apps', true, 45000.00, 'gasto', 'cuenta', '2026-02-12', 'Servicio', ''),
  ('demo024', 'Efectivo', 'efectivo', 'Salud', 'Medicamentos', false, 15000.00, 'gasto', 'efectivo', '2026-02-25', 'Consumo', ''),
  ('demo024', 'Davivienda', 'corriente', 'Ocio', 'Salidas', false, 25000.00, 'gasto', 'cuenta', '2026-04-04', 'Consumo', ''),
  ('demo024', 'Bancolombia', 'corriente', 'Ingresos', 'Freelance', false, 800000.00, 'ingreso', 'cuenta', '2026-04-06', 'Pago cliente', ''),
  ('demo024', 'Daviplata', 'corriente', 'Vivienda', 'Arriendo', true, 250000.00, 'gasto', 'cuenta', '2026-04-07', 'Servicio', ''),
  ('demo024', 'Bancolombia', 'corriente', 'Ocio', 'Suscripciones', false, 5000.00, 'gasto', 'cuenta', '2026-04-18', 'Consumo', ''),
  ('demo024', 'Bancolombia', 'corriente', 'Educación', 'Cursos', false, 120000.00, 'gasto', 'cuenta', '2026-04-25', 'Consumo', ''),
  ('demo024', 'Daviplata', 'corriente', 'Salud', 'Medicamentos', false, 25000.00, 'gasto', 'cuenta', '2026-05-09', 'Consumo', ''),
  ('demo025', 'Davivienda', 'digital', 'Ingresos', 'Otros ingresos', true, 2800000.00, 'ingreso', 'cuenta', '2026-01-19', 'Nomina', ''),
  ('demo025', 'Banco de Bogotá', 'corriente', 'Transporte', 'Taxi / apps', false, 120000.00, 'gasto', 'cuenta', '2026-02-04', 'Compra', ''),
  ('demo025', 'Banco de Bogotá', 'corriente', 'Transferencias', 'Entre mis cuentas', false, 80000.00, 'transferencia_salida', 'cuenta', '2026-02-09', 'Retiro a efectivo (salida)', 'df3a1b05-c84b-4b77-90bf-6e6020bda16a'),
  ('demo025', 'Efectivo', 'efectivo', 'Transferencias', 'Entre mis cuentas', false, 80000.00, 'transferencia_entrada', 'cuenta', '2026-02-09', 'Retiro a efectivo (entrada)', 'df3a1b05-c84b-4b77-90bf-6e6020bda16a'),
  ('demo025', 'Davivienda', 'digital', 'Ingresos', 'Freelance', false, 3500000.00, 'ingreso', 'cuenta', '2026-03-22', 'Pago cliente', ''),
  ('demo025', 'Nequi', 'corriente', 'Alimentación', 'Supermercado', true, 12000.00, 'gasto', 'cuenta', '2026-04-23', 'Compra', ''),
  ('demo025', 'Efectivo', 'efectivo', 'Vivienda', 'Servicios', false, 40000.00, 'gasto', 'efectivo', '2026-04-26', 'Servicio', ''),
  ('demo025', 'Nequi', 'corriente', 'Ocio', 'Cine', false, 25000.00, 'gasto', 'cuenta', '2026-04-29', 'Compra', ''),
  ('demo025', 'Nequi', 'corriente', 'Alimentación', 'Café', false, 163000.00, 'gasto', 'cuenta', '2026-05-05', 'Compra', ''),
  ('demo025', 'Davivienda', 'digital', 'Ocio', 'Cine', true, 25000.00, 'gasto', 'cuenta', '2026-05-11', 'Consumo', ''),
  ('demo026', 'Daviplata', 'corriente', 'Ingresos', 'Freelance', false, 1800000.00, 'ingreso', 'cuenta', '2026-01-10', 'Nomina', ''),
  ('demo026', 'Bancolombia', 'digital', 'Salud', 'Consultas', false, 50000.00, 'gasto', 'cuenta', '2026-01-19', 'Servicio', ''),
  ('demo026', 'Daviplata', 'corriente', 'Ingresos', 'Freelance', false, 1800000.00, 'ingreso', 'cuenta', '2026-01-24', 'Pago cliente', ''),
  ('demo026', 'Daviplata', 'corriente', 'Transporte', 'Combustible', true, 120000.00, 'gasto', 'cuenta', '2026-03-11', 'Pago', ''),
  ('demo026', 'Daviplata', 'corriente', 'Transporte', 'Transporte público', false, 120000.00, 'gasto', 'cuenta', '2026-03-13', 'Servicio', ''),
  ('demo026', 'Daviplata', 'corriente', 'Ocio', 'Salidas', false, 180000.00, 'gasto', 'cuenta', '2026-03-30', 'Pago', ''),
  ('demo026', 'Daviplata', 'corriente', 'Educación', 'Libros', true, 25000.00, 'gasto', 'cuenta', '2026-04-27', 'Consumo', ''),
  ('demo026', 'Daviplata', 'corriente', 'Alimentación', 'Supermercado', true, 120000.00, 'gasto', 'cuenta', '2026-05-13', 'Servicio', ''),
  ('demo027', 'Nequi', 'corriente', 'Ingresos', 'Freelance', false, 2800000.00, 'ingreso', 'cuenta', '2026-01-15', 'Ingreso extra', ''),
  ('demo027', 'Banco de Bogotá', 'digital', 'Ingresos', 'Freelance', false, 1200000.00, 'ingreso', 'cuenta', '2026-01-19', 'Ingreso extra', ''),
  ('demo027', 'Banco de Bogotá', 'digital', 'Transporte', 'Combustible', false, 78000.00, 'gasto', 'cuenta', '2026-02-18', 'Pago', ''),
  ('demo027', 'Efectivo', 'efectivo', 'Ocio', 'Salidas', false, 80000.00, 'gasto', 'efectivo', '2026-03-02', 'Compra', ''),
  ('demo027', 'Banco de Bogotá', 'digital', 'Transporte', 'Transporte público', true, 25000.00, 'gasto', 'cuenta', '2026-03-13', 'Pago', ''),
  ('demo027', 'Efectivo', 'efectivo', 'Vivienda', 'Servicios', false, 15000.00, 'gasto', 'efectivo', '2026-03-19', 'Servicio', ''),
  ('demo027', 'Banco de Bogotá', 'digital', 'Ocio', 'Salidas', false, 78000.00, 'gasto', 'cuenta', '2026-03-20', 'Servicio', ''),
  ('demo027', 'Banco de Bogotá', 'digital', 'Ocio', 'Suscripciones', false, 12000.00, 'gasto', 'cuenta', '2026-04-18', 'Consumo', '')
) AS v(usuario, banco, tipo_cta, cat, sub, use_cp, monto, tipo, medio_pago, fecha, descripcion, grupo)
JOIN users u ON u.usuario = v.usuario
JOIN accounts a ON a.user_id = u.id AND a.banco = v.banco AND a.tipo = v.tipo_cta
JOIN categories c ON c.nombre = v.cat
JOIN sub_categories s ON s.category_id = c.id AND s.nombre = v.sub
LEFT JOIN LATERAL (
  SELECT id FROM counterparties WHERE user_id = u.id ORDER BY id LIMIT 1
) cp ON v.use_cp;

INSERT INTO transactions (account_id, category_id, sub_category_id, contraparte_id, monto, tipo, medio_pago, fecha, descripcion, activo, grupo_transferencia)
SELECT a.id, c.id, s.id, CASE WHEN v.use_cp THEN cp.id ELSE NULL END, v.monto::numeric, v.tipo, v.medio_pago, v.fecha::date, v.descripcion, true, NULLIF(v.grupo, '')
FROM (VALUES
  ('demo027', 'Bancolombia', 'corriente', 'Educación', 'Libros', false, 50000.00, 'gasto', 'cuenta', '2026-05-11', 'Consumo', ''),
  ('demo027', 'Banco de Bogotá', 'digital', 'Educación', 'Cursos', false, 12000.00, 'gasto', 'cuenta', '2026-06-18', 'Consumo', ''),
  ('demo027', 'Banco de Bogotá', 'digital', 'Vivienda', 'Arriendo', false, 180000.00, 'gasto', 'cuenta', '2026-06-24', 'Servicio', ''),
  ('demo028', 'Banco de Bogotá', 'digital', 'Ingresos', 'Freelance', true, 1200000.00, 'ingreso', 'cuenta', '2026-01-11', 'Nomina', ''),
  ('demo028', 'Banco de Bogotá', 'digital', 'Transferencias', 'Entre mis cuentas', false, 80000.00, 'transferencia_salida', 'cuenta', '2026-01-29', 'Retiro a efectivo (salida)', '45ce7e16-dd73-4741-87d5-30ad4e8c6fb2'),
  ('demo028', 'Efectivo', 'efectivo', 'Transferencias', 'Entre mis cuentas', false, 80000.00, 'transferencia_entrada', 'cuenta', '2026-01-29', 'Retiro a efectivo (entrada)', '45ce7e16-dd73-4741-87d5-30ad4e8c6fb2'),
  ('demo028', 'BBVA', 'ahorros', 'Alimentación', 'Supermercado', false, 5000.00, 'gasto', 'cuenta', '2026-02-03', 'Consumo', ''),
  ('demo028', 'BBVA', 'ahorros', 'Educación', 'Libros', true, 25000.00, 'gasto', 'cuenta', '2026-02-05', 'Compra', ''),
  ('demo028', 'Efectivo', 'efectivo', 'Transporte', 'Combustible', true, 5000.00, 'gasto', 'efectivo', '2026-02-12', 'Compra', ''),
  ('demo028', 'BBVA', 'ahorros', 'Ocio', 'Suscripciones', false, 20000.00, 'gasto', 'cuenta', '2026-02-22', 'Pago', ''),
  ('demo028', 'Banco de Bogotá', 'digital', 'Alimentación', 'Supermercado', false, 12000.00, 'gasto', 'cuenta', '2026-02-24', 'Pago', ''),
  ('demo028', 'Banco de Bogotá', 'digital', 'Ingresos', 'Otros ingresos', false, 3500000.00, 'ingreso', 'cuenta', '2026-03-02', 'Nomina', ''),
  ('demo028', 'Banco de Bogotá', 'digital', 'Transporte', 'Transporte público', false, 12000.00, 'gasto', 'cuenta', '2026-03-24', 'Compra', ''),
  ('demo028', 'Efectivo', 'efectivo', 'Transporte', 'Transporte público', true, 80000.00, 'gasto', 'efectivo', '2026-05-09', 'Pago', ''),
  ('demo028', 'Banco de Bogotá', 'digital', 'Salud', 'Medicamentos', false, 45000.00, 'gasto', 'cuenta', '2026-06-28', 'Compra', ''),
  ('demo029', 'Daviplata', 'corriente', 'Ingresos', 'Otros ingresos', false, 3500000.00, 'ingreso', 'cuenta', '2026-01-14', 'Ingreso extra', ''),
  ('demo029', 'Bancolombia', 'ahorros', 'Salud', 'Medicamentos', false, 12000.00, 'gasto', 'cuenta', '2026-01-17', 'Compra', ''),
  ('demo029', 'Daviplata', 'corriente', 'Salud', 'Consultas', false, 25000.00, 'gasto', 'cuenta', '2026-01-18', 'Servicio', ''),
  ('demo029', 'Nequi', 'digital', 'Ingresos', 'Otros ingresos', false, 3500000.00, 'ingreso', 'cuenta', '2026-01-19', 'Nomina', ''),
  ('demo029', 'Bancolombia', 'ahorros', 'Alimentación', 'Restaurante', true, 38000.00, 'gasto', 'cuenta', '2026-01-24', 'Pago', ''),
  ('demo029', 'Efectivo', 'efectivo', 'Alimentación', 'Supermercado', false, 5000.00, 'gasto', 'efectivo', '2026-04-04', 'Pago', ''),
  ('demo029', 'Daviplata', 'corriente', 'Ingresos', 'Freelance', false, 2200000.00, 'ingreso', 'cuenta', '2026-04-16', 'Ingreso extra', ''),
  ('demo029', 'Efectivo', 'efectivo', 'Vivienda', 'Mantenimiento', false, 80000.00, 'gasto', 'efectivo', '2026-05-07', 'Pago', ''),
  ('demo029', 'Nequi', 'digital', 'Transferencias', 'Entre mis cuentas', false, 300000.00, 'transferencia_salida', 'cuenta', '2026-05-13', 'Transferencia entre cuentas (salida)', '14593065-e40e-4913-8f78-87ddaf600636'),
  ('demo029', 'Bancolombia', 'ahorros', 'Transferencias', 'Entre mis cuentas', false, 300000.00, 'transferencia_entrada', 'cuenta', '2026-05-13', 'Transferencia entre cuentas (entrada)', '14593065-e40e-4913-8f78-87ddaf600636'),
  ('demo029', 'Efectivo', 'efectivo', 'Alimentación', 'Supermercado', false, 5000.00, 'gasto', 'efectivo', '2026-05-29', 'Consumo', ''),
  ('demo029', 'Efectivo', 'efectivo', 'Alimentación', 'Café', false, 15000.00, 'gasto', 'efectivo', '2026-05-30', 'Consumo', ''),
  ('demo029', 'Nequi', 'digital', 'Educación', 'Libros', false, 12000.00, 'gasto', 'cuenta', '2026-06-13', 'Servicio', ''),
  ('demo030', 'Bancolombia', 'ahorros', 'Ingresos', 'Salario', false, 1800000.00, 'ingreso', 'cuenta', '2026-01-12', 'Ingreso extra', ''),
  ('demo030', 'Davivienda', 'digital', 'Ingresos', 'Salario', false, 1200000.00, 'ingreso', 'cuenta', '2026-01-16', 'Ingreso extra', ''),
  ('demo030', 'Bancolombia', 'ahorros', 'Educación', 'Cursos', false, 12000.00, 'gasto', 'cuenta', '2026-01-24', 'Consumo', ''),
  ('demo030', 'Bancolombia', 'ahorros', 'Alimentación', 'Café', true, 120000.00, 'gasto', 'cuenta', '2026-03-13', 'Servicio', ''),
  ('demo030', 'Davivienda', 'digital', 'Salud', 'Medicamentos', false, 78000.00, 'gasto', 'cuenta', '2026-03-19', 'Pago', ''),
  ('demo030', 'Bancolombia', 'ahorros', 'Vivienda', 'Servicios', true, 45000.00, 'gasto', 'cuenta', '2026-04-07', 'Pago', ''),
  ('demo030', 'Bancolombia', 'ahorros', 'Vivienda', 'Servicios', false, 5000.00, 'gasto', 'cuenta', '2026-05-01', 'Consumo', ''),
  ('demo030', 'Davivienda', 'digital', 'Alimentación', 'Supermercado', false, 120000.00, 'gasto', 'cuenta', '2026-05-02', 'Servicio', ''),
  ('demo030', 'Bancolombia', 'ahorros', 'Vivienda', 'Arriendo', false, 12000.00, 'gasto', 'cuenta', '2026-06-05', 'Pago', ''),
  ('demo030', 'Davivienda', 'digital', 'Vivienda', 'Mantenimiento', true, 25000.00, 'gasto', 'cuenta', '2026-07-01', 'Compra', ''),
  ('demo031', 'Bancolombia', 'ahorros', 'Ingresos', 'Freelance', false, 1800000.00, 'ingreso', 'cuenta', '2026-01-19', 'Pago cliente', ''),
  ('demo031', 'BBVA', 'ahorros', 'Ingresos', 'Otros ingresos', false, 1200000.00, 'ingreso', 'cuenta', '2026-01-22', 'Pago cliente', '')
) AS v(usuario, banco, tipo_cta, cat, sub, use_cp, monto, tipo, medio_pago, fecha, descripcion, grupo)
JOIN users u ON u.usuario = v.usuario
JOIN accounts a ON a.user_id = u.id AND a.banco = v.banco AND a.tipo = v.tipo_cta
JOIN categories c ON c.nombre = v.cat
JOIN sub_categories s ON s.category_id = c.id AND s.nombre = v.sub
LEFT JOIN LATERAL (
  SELECT id FROM counterparties WHERE user_id = u.id ORDER BY id LIMIT 1
) cp ON v.use_cp;

INSERT INTO transactions (account_id, category_id, sub_category_id, contraparte_id, monto, tipo, medio_pago, fecha, descripcion, activo, grupo_transferencia)
SELECT a.id, c.id, s.id, CASE WHEN v.use_cp THEN cp.id ELSE NULL END, v.monto::numeric, v.tipo, v.medio_pago, v.fecha::date, v.descripcion, true, NULLIF(v.grupo, '')
FROM (VALUES
  ('demo031', 'Banco de Bogotá', 'digital', 'Vivienda', 'Arriendo', true, 5000.00, 'gasto', 'cuenta', '2026-02-04', 'Consumo', ''),
  ('demo031', 'BBVA', 'ahorros', 'Transferencias', 'Entre mis cuentas', false, 300000.00, 'transferencia_salida', 'cuenta', '2026-02-08', 'Retiro a efectivo (salida)', '7d68524b-2ab1-423d-9757-1f433c1c4d39'),
  ('demo031', 'Efectivo', 'efectivo', 'Transferencias', 'Entre mis cuentas', false, 300000.00, 'transferencia_entrada', 'cuenta', '2026-02-08', 'Retiro a efectivo (entrada)', '7d68524b-2ab1-423d-9757-1f433c1c4d39'),
  ('demo031', 'BBVA', 'ahorros', 'Ocio', 'Suscripciones', false, 120000.00, 'gasto', 'cuenta', '2026-02-12', 'Compra', ''),
  ('demo031', 'Bancolombia', 'ahorros', 'Alimentación', 'Supermercado', false, 25000.00, 'gasto', 'cuenta', '2026-02-12', 'Servicio', ''),
  ('demo031', 'Banco de Bogotá', 'digital', 'Transporte', 'Combustible', true, 45000.00, 'gasto', 'cuenta', '2026-02-19', 'Servicio', ''),
  ('demo031', 'BBVA', 'ahorros', 'Alimentación', 'Supermercado', false, 12000.00, 'gasto', 'cuenta', '2026-02-24', 'Compra', ''),
  ('demo031', 'BBVA', 'ahorros', 'Vivienda', 'Arriendo', true, 25000.00, 'gasto', 'cuenta', '2026-02-27', 'Servicio', ''),
  ('demo031', 'Banco de Bogotá', 'digital', 'Vivienda', 'Mantenimiento', true, 12000.00, 'gasto', 'cuenta', '2026-03-08', 'Compra', ''),
  ('demo031', 'BBVA', 'ahorros', 'Educación', 'Cursos', true, 45000.00, 'gasto', 'cuenta', '2026-03-16', 'Pago', ''),
  ('demo031', 'Bancolombia', 'ahorros', 'Transferencias', 'Entre mis cuentas', false, 50000.00, 'transferencia_salida', 'cuenta', '2026-03-27', 'Transferencia entre cuentas (salida)', '6820b807-769b-47b9-b5ea-d2296b244a64'),
  ('demo031', 'BBVA', 'ahorros', 'Transferencias', 'Entre mis cuentas', false, 50000.00, 'transferencia_entrada', 'cuenta', '2026-03-27', 'Transferencia entre cuentas (entrada)', '6820b807-769b-47b9-b5ea-d2296b244a64'),
  ('demo031', 'Bancolombia', 'ahorros', 'Ingresos', 'Salario', false, 800000.00, 'ingreso', 'cuenta', '2026-04-15', 'Ingreso extra', ''),
  ('demo031', 'Banco de Bogotá', 'digital', 'Educación', 'Libros', true, 180000.00, 'gasto', 'cuenta', '2026-05-11', 'Compra', ''),
  ('demo031', 'Efectivo', 'efectivo', 'Transporte', 'Taxi / apps', true, 25000.00, 'gasto', 'efectivo', '2026-06-09', 'Consumo', ''),
  ('demo031', 'BBVA', 'ahorros', 'Vivienda', 'Mantenimiento', false, 78000.00, 'gasto', 'cuenta', '2026-06-14', 'Servicio', ''),
  ('demo032', 'Daviplata', 'corriente', 'Ingresos', 'Otros ingresos', false, 2800000.00, 'ingreso', 'cuenta', '2026-01-11', 'Nomina', ''),
  ('demo032', 'BBVA', 'ahorros', 'Ingresos', 'Freelance', false, 2800000.00, 'ingreso', 'cuenta', '2026-01-12', 'Pago cliente', ''),
  ('demo032', 'BBVA', 'ahorros', 'Vivienda', 'Servicios', false, 25000.00, 'gasto', 'cuenta', '2026-01-31', 'Consumo', ''),
  ('demo032', 'Efectivo', 'efectivo', 'Ocio', 'Cine', false, 55000.00, 'gasto', 'efectivo', '2026-02-18', 'Compra', ''),
  ('demo032', 'Daviplata', 'corriente', 'Ingresos', 'Otros ingresos', false, 2800000.00, 'ingreso', 'cuenta', '2026-03-18', 'Nomina', ''),
  ('demo032', 'Efectivo', 'efectivo', 'Educación', 'Libros', true, 10000.00, 'gasto', 'efectivo', '2026-03-28', 'Consumo', ''),
  ('demo032', 'BBVA', 'ahorros', 'Alimentación', 'Restaurante', false, 12000.00, 'gasto', 'cuenta', '2026-03-29', 'Pago', ''),
  ('demo032', 'BBVA', 'ahorros', 'Alimentación', 'Supermercado', false, 250000.00, 'gasto', 'cuenta', '2026-04-18', 'Consumo', ''),
  ('demo032', 'BBVA', 'ahorros', 'Salud', 'Consultas', false, 25000.00, 'gasto', 'cuenta', '2026-05-17', 'Pago', ''),
  ('demo032', 'Daviplata', 'corriente', 'Alimentación', 'Supermercado', false, 5000.00, 'gasto', 'cuenta', '2026-06-01', 'Pago', ''),
  ('demo032', 'BBVA', 'ahorros', 'Ocio', 'Cine', true, 12000.00, 'gasto', 'cuenta', '2026-06-15', 'Compra', ''),
  ('demo033', 'Nequi', 'digital', 'Ingresos', 'Salario', false, 3500000.00, 'ingreso', 'cuenta', '2026-01-22', 'Ingreso extra', ''),
  ('demo033', 'BBVA', 'digital', 'Ingresos', 'Freelance', false, 1800000.00, 'ingreso', 'cuenta', '2026-01-22', 'Nomina', ''),
  ('demo033', 'Nequi', 'digital', 'Ocio', 'Cine', false, 12000.00, 'gasto', 'cuenta', '2026-02-06', 'Consumo', ''),
  ('demo033', 'BBVA', 'digital', 'Alimentación', 'Restaurante', false, 5000.00, 'gasto', 'cuenta', '2026-02-13', 'Servicio', ''),
  ('demo033', 'Daviplata', 'ahorros', 'Ocio', 'Salidas', false, 25000.00, 'gasto', 'cuenta', '2026-02-23', 'Servicio', ''),
  ('demo033', 'Daviplata', 'ahorros', 'Transporte', 'Combustible', false, 125000.00, 'gasto', 'cuenta', '2026-03-15', 'Servicio', ''),
  ('demo033', 'BBVA', 'digital', 'Transporte', 'Taxi / apps', true, 45000.00, 'gasto', 'cuenta', '2026-03-19', 'Servicio', ''),
  ('demo033', 'Nequi', 'digital', 'Alimentación', 'Supermercado', true, 78000.00, 'gasto', 'cuenta', '2026-04-12', 'Consumo', ''),
  ('demo033', 'Nequi', 'digital', 'Salud', 'Consultas', false, 12000.00, 'gasto', 'cuenta', '2026-04-16', 'Pago', ''),
  ('demo033', 'Nequi', 'digital', 'Ingresos', 'Salario', false, 3500000.00, 'ingreso', 'cuenta', '2026-05-07', 'Ingreso extra', ''),
  ('demo033', 'Nequi', 'digital', 'Educación', 'Libros', false, 120000.00, 'gasto', 'cuenta', '2026-05-25', 'Compra', ''),
  ('demo033', 'BBVA', 'digital', 'Ocio', 'Salidas', true, 25000.00, 'gasto', 'cuenta', '2026-06-11', 'Pago', ''),
  ('demo033', 'Nequi', 'digital', 'Vivienda', 'Mantenimiento', true, 180000.00, 'gasto', 'cuenta', '2026-06-30', 'Consumo', '')
) AS v(usuario, banco, tipo_cta, cat, sub, use_cp, monto, tipo, medio_pago, fecha, descripcion, grupo)
JOIN users u ON u.usuario = v.usuario
JOIN accounts a ON a.user_id = u.id AND a.banco = v.banco AND a.tipo = v.tipo_cta
JOIN categories c ON c.nombre = v.cat
JOIN sub_categories s ON s.category_id = c.id AND s.nombre = v.sub
LEFT JOIN LATERAL (
  SELECT id FROM counterparties WHERE user_id = u.id ORDER BY id LIMIT 1
) cp ON v.use_cp;

INSERT INTO transactions (account_id, category_id, sub_category_id, contraparte_id, monto, tipo, medio_pago, fecha, descripcion, activo, grupo_transferencia)
SELECT a.id, c.id, s.id, CASE WHEN v.use_cp THEN cp.id ELSE NULL END, v.monto::numeric, v.tipo, v.medio_pago, v.fecha::date, v.descripcion, true, NULLIF(v.grupo, '')
FROM (VALUES
  ('demo034', 'Davivienda', 'corriente', 'Ingresos', 'Salario', false, 1800000.00, 'ingreso', 'cuenta', '2026-01-18', 'Pago cliente', ''),
  ('demo034', 'Bancolombia', 'corriente', 'Ingresos', 'Otros ingresos', true, 3500000.00, 'ingreso', 'cuenta', '2026-01-21', 'Nomina', ''),
  ('demo034', 'Davivienda', 'corriente', 'Vivienda', 'Servicios', false, 180000.00, 'gasto', 'cuenta', '2026-02-11', 'Compra', ''),
  ('demo034', 'Davivienda', 'corriente', 'Vivienda', 'Servicios', true, 250000.00, 'gasto', 'cuenta', '2026-03-07', 'Servicio', ''),
  ('demo034', 'Davivienda', 'corriente', 'Transporte', 'Transporte público', false, 5000.00, 'gasto', 'cuenta', '2026-03-07', 'Compra', ''),
  ('demo034', 'Davivienda', 'corriente', 'Transporte', 'Taxi / apps', false, 25000.00, 'gasto', 'cuenta', '2026-04-23', 'Pago', ''),
  ('demo034', 'Bancolombia', 'corriente', 'Ocio', 'Salidas', false, 5000.00, 'gasto', 'cuenta', '2026-04-23', 'Compra', ''),
  ('demo034', 'Davivienda', 'corriente', 'Transporte', 'Transporte público', true, 45000.00, 'gasto', 'cuenta', '2026-04-26', 'Consumo', ''),
  ('demo034', 'Bancolombia', 'corriente', 'Ocio', 'Suscripciones', false, 12000.00, 'gasto', 'cuenta', '2026-04-28', 'Servicio', ''),
  ('demo034', 'Davivienda', 'corriente', 'Alimentación', 'Supermercado', true, 250000.00, 'gasto', 'cuenta', '2026-05-13', 'Servicio', ''),
  ('demo034', 'Bancolombia', 'corriente', 'Transferencias', 'Entre mis cuentas', false, 200000.00, 'transferencia_salida', 'cuenta', '2026-05-28', 'Transferencia entre cuentas (salida)', '50b44632-2fcb-44e2-b74a-55862c91cdd5'),
  ('demo034', 'Davivienda', 'corriente', 'Transferencias', 'Entre mis cuentas', false, 200000.00, 'transferencia_entrada', 'cuenta', '2026-05-28', 'Transferencia entre cuentas (entrada)', '50b44632-2fcb-44e2-b74a-55862c91cdd5'),
  ('demo034', 'Bancolombia', 'corriente', 'Transporte', 'Combustible', false, 12000.00, 'gasto', 'cuenta', '2026-06-07', 'Consumo', ''),
  ('demo034', 'Davivienda', 'corriente', 'Vivienda', 'Mantenimiento', false, 180000.00, 'gasto', 'cuenta', '2026-07-02', 'Servicio', ''),
  ('demo035', 'Nequi', 'corriente', 'Ingresos', 'Salario', false, 2800000.00, 'ingreso', 'cuenta', '2026-01-08', 'Nomina', ''),
  ('demo035', 'BBVA', 'ahorros', 'Transporte', 'Transporte público', true, 100000.00, 'gasto', 'cuenta', '2026-02-04', 'Compra', ''),
  ('demo035', 'Nequi', 'corriente', 'Vivienda', 'Servicios', false, 5000.00, 'gasto', 'cuenta', '2026-03-02', 'Compra', ''),
  ('demo035', 'Banco de Bogotá', 'digital', 'Vivienda', 'Mantenimiento', false, 45000.00, 'gasto', 'cuenta', '2026-03-08', 'Consumo', ''),
  ('demo035', 'BBVA', 'ahorros', 'Ingresos', 'Otros ingresos', true, 800000.00, 'ingreso', 'cuenta', '2026-04-11', 'Nomina', ''),
  ('demo035', 'Banco de Bogotá', 'digital', 'Transporte', 'Taxi / apps', false, 105000.00, 'gasto', 'cuenta', '2026-04-27', 'Servicio', ''),
  ('demo035', 'Nequi', 'corriente', 'Alimentación', 'Café', true, 78000.00, 'gasto', 'cuenta', '2026-05-06', 'Consumo', ''),
  ('demo035', 'Nequi', 'corriente', 'Vivienda', 'Arriendo', false, 25000.00, 'gasto', 'cuenta', '2026-05-17', 'Pago', ''),
  ('demo035', 'BBVA', 'ahorros', 'Vivienda', 'Mantenimiento', false, 45000.00, 'gasto', 'cuenta', '2026-05-25', 'Servicio', ''),
  ('demo035', 'BBVA', 'ahorros', 'Educación', 'Libros', false, 5000.00, 'gasto', 'cuenta', '2026-06-16', 'Pago', ''),
  ('demo035', 'BBVA', 'ahorros', 'Vivienda', 'Servicios', false, 5000.00, 'gasto', 'cuenta', '2026-06-27', 'Consumo', ''),
  ('demo036', 'BBVA', 'digital', 'Ingresos', 'Freelance', false, 2200000.00, 'ingreso', 'cuenta', '2026-01-13', 'Pago cliente', ''),
  ('demo036', 'Efectivo', 'efectivo', 'Vivienda', 'Arriendo', false, 40000.00, 'gasto', 'efectivo', '2026-01-27', 'Consumo', ''),
  ('demo036', 'Davivienda', 'corriente', 'Ocio', 'Cine', false, 100000.00, 'gasto', 'cuenta', '2026-01-28', 'Consumo', ''),
  ('demo036', 'Daviplata', 'digital', 'Salud', 'Medicamentos', false, 25000.00, 'gasto', 'cuenta', '2026-02-21', 'Compra', ''),
  ('demo036', 'Daviplata', 'digital', 'Transporte', 'Taxi / apps', false, 78000.00, 'gasto', 'cuenta', '2026-03-03', 'Consumo', ''),
  ('demo036', 'BBVA', 'digital', 'Ingresos', 'Freelance', false, 1800000.00, 'ingreso', 'cuenta', '2026-03-22', 'Pago cliente', ''),
  ('demo036', 'BBVA', 'digital', 'Educación', 'Libros', false, 12000.00, 'gasto', 'cuenta', '2026-03-25', 'Compra', ''),
  ('demo036', 'Daviplata', 'digital', 'Educación', 'Libros', false, 12000.00, 'gasto', 'cuenta', '2026-03-31', 'Pago', ''),
  ('demo036', 'Daviplata', 'digital', 'Salud', 'Medicamentos', true, 180000.00, 'gasto', 'cuenta', '2026-05-26', 'Servicio', ''),
  ('demo036', 'Efectivo', 'efectivo', 'Transporte', 'Transporte público', false, 80000.00, 'gasto', 'efectivo', '2026-05-28', 'Pago', ''),
  ('demo036', 'BBVA', 'digital', 'Educación', 'Cursos', true, 180000.00, 'gasto', 'cuenta', '2026-06-16', 'Pago', ''),
  ('demo036', 'Daviplata', 'digital', 'Alimentación', 'Café', true, 25000.00, 'gasto', 'cuenta', '2026-06-29', 'Servicio', ''),
  ('demo037', 'Nequi', 'digital', 'Alimentación', 'Café', true, 25000.00, 'gasto', 'cuenta', '2026-01-16', 'Compra', ''),
  ('demo037', 'Nequi', 'digital', 'Ingresos', 'Otros ingresos', false, 2200000.00, 'ingreso', 'cuenta', '2026-01-18', 'Ingreso extra', ''),
  ('demo037', 'Nequi', 'digital', 'Transporte', 'Transporte público', false, 180000.00, 'gasto', 'cuenta', '2026-01-19', 'Consumo', '')
) AS v(usuario, banco, tipo_cta, cat, sub, use_cp, monto, tipo, medio_pago, fecha, descripcion, grupo)
JOIN users u ON u.usuario = v.usuario
JOIN accounts a ON a.user_id = u.id AND a.banco = v.banco AND a.tipo = v.tipo_cta
JOIN categories c ON c.nombre = v.cat
JOIN sub_categories s ON s.category_id = c.id AND s.nombre = v.sub
LEFT JOIN LATERAL (
  SELECT id FROM counterparties WHERE user_id = u.id ORDER BY id LIMIT 1
) cp ON v.use_cp;

INSERT INTO transactions (account_id, category_id, sub_category_id, contraparte_id, monto, tipo, medio_pago, fecha, descripcion, activo, grupo_transferencia)
SELECT a.id, c.id, s.id, CASE WHEN v.use_cp THEN cp.id ELSE NULL END, v.monto::numeric, v.tipo, v.medio_pago, v.fecha::date, v.descripcion, true, NULLIF(v.grupo, '')
FROM (VALUES
  ('demo037', 'Nequi', 'digital', 'Vivienda', 'Arriendo', false, 120000.00, 'gasto', 'cuenta', '2026-03-04', 'Pago', ''),
  ('demo037', 'Nequi', 'digital', 'Vivienda', 'Servicios', false, 5000.00, 'gasto', 'cuenta', '2026-04-07', 'Pago', ''),
  ('demo037', 'Efectivo', 'efectivo', 'Vivienda', 'Arriendo', false, 10000.00, 'gasto', 'efectivo', '2026-04-11', 'Compra', ''),
  ('demo037', 'Efectivo', 'efectivo', 'Transporte', 'Combustible', false, 10000.00, 'gasto', 'efectivo', '2026-04-20', 'Consumo', ''),
  ('demo037', 'Nequi', 'digital', 'Alimentación', 'Restaurante', false, 5000.00, 'gasto', 'cuenta', '2026-05-30', 'Compra', ''),
  ('demo037', 'Banco de Bogotá', 'ahorros', 'Transporte', 'Combustible', false, 5000.00, 'gasto', 'cuenta', '2026-06-24', 'Servicio', ''),
  ('demo038', 'Daviplata', 'corriente', 'Transferencias', 'Entre mis cuentas', false, 150000.00, 'transferencia_salida', 'cuenta', '2026-01-13', 'Retiro a efectivo (salida)', 'a65e78bd-63a7-4cdc-bd87-2f387da150ce'),
  ('demo038', 'Efectivo', 'efectivo', 'Transferencias', 'Entre mis cuentas', false, 150000.00, 'transferencia_entrada', 'cuenta', '2026-01-13', 'Retiro a efectivo (entrada)', 'a65e78bd-63a7-4cdc-bd87-2f387da150ce'),
  ('demo038', 'Bancolombia', 'digital', 'Ingresos', 'Salario', true, 1200000.00, 'ingreso', 'cuenta', '2026-01-20', 'Ingreso extra', ''),
  ('demo038', 'Efectivo', 'efectivo', 'Vivienda', 'Servicios', false, 55000.00, 'gasto', 'efectivo', '2026-02-14', 'Servicio', ''),
  ('demo038', 'Bancolombia', 'digital', 'Educación', 'Cursos', true, 78000.00, 'gasto', 'cuenta', '2026-02-26', 'Compra', ''),
  ('demo038', 'Bancolombia', 'digital', 'Salud', 'Consultas', false, 120000.00, 'gasto', 'cuenta', '2026-04-01', 'Servicio', ''),
  ('demo038', 'Daviplata', 'corriente', 'Ingresos', 'Otros ingresos', true, 1200000.00, 'ingreso', 'cuenta', '2026-04-24', 'Ingreso extra', ''),
  ('demo038', 'Bancolombia', 'digital', 'Vivienda', 'Mantenimiento', true, 250000.00, 'gasto', 'cuenta', '2026-04-30', 'Compra', ''),
  ('demo038', 'Bancolombia', 'digital', 'Transporte', 'Combustible', false, 25000.00, 'gasto', 'cuenta', '2026-05-19', 'Servicio', ''),
  ('demo038', 'Bancolombia', 'digital', 'Ocio', 'Suscripciones', false, 78000.00, 'gasto', 'cuenta', '2026-05-23', 'Servicio', ''),
  ('demo038', 'Daviplata', 'corriente', 'Transporte', 'Transporte público', false, 12000.00, 'gasto', 'cuenta', '2026-06-05', 'Compra', ''),
  ('demo039', 'Banco de Bogotá', 'digital', 'Ingresos', 'Otros ingresos', false, 3500000.00, 'ingreso', 'cuenta', '2026-01-10', 'Nomina', ''),
  ('demo039', 'BBVA', 'corriente', 'Transferencias', 'Entre mis cuentas', false, 80000.00, 'transferencia_salida', 'cuenta', '2026-02-27', 'Transferencia entre cuentas (salida)', 'f5bbe2eb-befe-4081-b5db-4b8d93dd58f1'),
  ('demo039', 'Banco de Bogotá', 'digital', 'Transferencias', 'Entre mis cuentas', false, 80000.00, 'transferencia_entrada', 'cuenta', '2026-02-27', 'Transferencia entre cuentas (entrada)', 'f5bbe2eb-befe-4081-b5db-4b8d93dd58f1'),
  ('demo039', 'BBVA', 'corriente', 'Alimentación', 'Supermercado', false, 5000.00, 'gasto', 'cuenta', '2026-03-15', 'Pago', ''),
  ('demo039', 'Banco de Bogotá', 'digital', 'Ingresos', 'Salario', false, 2200000.00, 'ingreso', 'cuenta', '2026-03-30', 'Nomina', ''),
  ('demo039', 'Banco de Bogotá', 'digital', 'Salud', 'Consultas', true, 45000.00, 'gasto', 'cuenta', '2026-04-13', 'Consumo', ''),
  ('demo039', 'Nequi', 'digital', 'Ocio', 'Suscripciones', true, 150000.00, 'gasto', 'cuenta', '2026-05-29', 'Pago', ''),
  ('demo039', 'Banco de Bogotá', 'digital', 'Alimentación', 'Café', false, 250000.00, 'gasto', 'cuenta', '2026-05-31', 'Servicio', ''),
  ('demo039', 'BBVA', 'corriente', 'Transporte', 'Combustible', false, 5000.00, 'gasto', 'cuenta', '2026-06-13', 'Servicio', ''),
  ('demo040', 'Daviplata', 'ahorros', 'Ingresos', 'Otros ingresos', true, 3500000.00, 'ingreso', 'cuenta', '2026-01-12', 'Ingreso extra', ''),
  ('demo040', 'Daviplata', 'ahorros', 'Alimentación', 'Restaurante', false, 5000.00, 'gasto', 'cuenta', '2026-02-14', 'Servicio', ''),
  ('demo040', 'Daviplata', 'ahorros', 'Transporte', 'Taxi / apps', true, 25000.00, 'gasto', 'cuenta', '2026-02-14', 'Pago', ''),
  ('demo040', 'Nequi', 'corriente', 'Ocio', 'Suscripciones', false, 100000.00, 'gasto', 'cuenta', '2026-02-17', 'Servicio', ''),
  ('demo040', 'Daviplata', 'ahorros', 'Salud', 'Consultas', false, 180000.00, 'gasto', 'cuenta', '2026-03-07', 'Consumo', ''),
  ('demo040', 'Banco de Bogotá', 'corriente', 'Ocio', 'Salidas', false, 25000.00, 'gasto', 'cuenta', '2026-03-09', 'Consumo', ''),
  ('demo040', 'Banco de Bogotá', 'corriente', 'Salud', 'Medicamentos', false, 45000.00, 'gasto', 'cuenta', '2026-04-14', 'Consumo', ''),
  ('demo040', 'Banco de Bogotá', 'corriente', 'Salud', 'Consultas', false, 25000.00, 'gasto', 'cuenta', '2026-04-28', 'Compra', ''),
  ('demo040', 'Efectivo', 'efectivo', 'Salud', 'Medicamentos', false, 55000.00, 'gasto', 'efectivo', '2026-06-24', 'Servicio', ''),
  ('demo041', 'Davivienda', 'ahorros', 'Vivienda', 'Arriendo', false, 45000.00, 'gasto', 'cuenta', '2026-01-22', 'Consumo', ''),
  ('demo041', 'Nequi', 'corriente', 'Ingresos', 'Salario', false, 1200000.00, 'ingreso', 'cuenta', '2026-01-23', 'Ingreso extra', ''),
  ('demo041', 'Davivienda', 'ahorros', 'Ingresos', 'Freelance', false, 800000.00, 'ingreso', 'cuenta', '2026-01-24', 'Pago cliente', ''),
  ('demo041', 'Nequi', 'corriente', 'Vivienda', 'Mantenimiento', true, 25000.00, 'gasto', 'cuenta', '2026-03-11', 'Compra', ''),
  ('demo041', 'Nequi', 'corriente', 'Transporte', 'Transporte público', false, 5000.00, 'gasto', 'cuenta', '2026-03-17', 'Consumo', '')
) AS v(usuario, banco, tipo_cta, cat, sub, use_cp, monto, tipo, medio_pago, fecha, descripcion, grupo)
JOIN users u ON u.usuario = v.usuario
JOIN accounts a ON a.user_id = u.id AND a.banco = v.banco AND a.tipo = v.tipo_cta
JOIN categories c ON c.nombre = v.cat
JOIN sub_categories s ON s.category_id = c.id AND s.nombre = v.sub
LEFT JOIN LATERAL (
  SELECT id FROM counterparties WHERE user_id = u.id ORDER BY id LIMIT 1
) cp ON v.use_cp;

INSERT INTO transactions (account_id, category_id, sub_category_id, contraparte_id, monto, tipo, medio_pago, fecha, descripcion, activo, grupo_transferencia)
SELECT a.id, c.id, s.id, CASE WHEN v.use_cp THEN cp.id ELSE NULL END, v.monto::numeric, v.tipo, v.medio_pago, v.fecha::date, v.descripcion, true, NULLIF(v.grupo, '')
FROM (VALUES
  ('demo041', 'Davivienda', 'ahorros', 'Ocio', 'Cine', false, 250000.00, 'gasto', 'cuenta', '2026-03-24', 'Compra', ''),
  ('demo041', 'Davivienda', 'ahorros', 'Ingresos', 'Salario', false, 2800000.00, 'ingreso', 'cuenta', '2026-05-01', 'Nomina', ''),
  ('demo041', 'Nequi', 'corriente', 'Ocio', 'Suscripciones', true, 180000.00, 'gasto', 'cuenta', '2026-05-12', 'Compra', ''),
  ('demo041', 'Nequi', 'corriente', 'Salud', 'Consultas', true, 120000.00, 'gasto', 'cuenta', '2026-06-26', 'Consumo', ''),
  ('demo042', 'Bancolombia', 'ahorros', 'Ingresos', 'Otros ingresos', true, 3500000.00, 'ingreso', 'cuenta', '2026-01-05', 'Nomina', ''),
  ('demo042', 'Davivienda', 'digital', 'Ingresos', 'Salario', true, 800000.00, 'ingreso', 'cuenta', '2026-01-12', 'Nomina', ''),
  ('demo042', 'Davivienda', 'digital', 'Vivienda', 'Servicios', false, 12000.00, 'gasto', 'cuenta', '2026-01-14', 'Consumo', ''),
  ('demo042', 'Bancolombia', 'ahorros', 'Transferencias', 'Entre mis cuentas', false, 150000.00, 'transferencia_salida', 'cuenta', '2026-01-23', 'Retiro a efectivo (salida)', '951607ec-3b43-46a3-b98e-475c7c35421a'),
  ('demo042', 'Efectivo', 'efectivo', 'Transferencias', 'Entre mis cuentas', false, 150000.00, 'transferencia_entrada', 'cuenta', '2026-01-23', 'Retiro a efectivo (entrada)', '951607ec-3b43-46a3-b98e-475c7c35421a'),
  ('demo042', 'Davivienda', 'digital', 'Salud', 'Consultas', true, 180000.00, 'gasto', 'cuenta', '2026-02-03', 'Compra', ''),
  ('demo042', 'Bancolombia', 'ahorros', 'Alimentación', 'Café', false, 5000.00, 'gasto', 'cuenta', '2026-02-06', 'Compra', ''),
  ('demo042', 'Efectivo', 'efectivo', 'Ocio', 'Cine', true, 5000.00, 'gasto', 'efectivo', '2026-02-15', 'Compra', ''),
  ('demo042', 'Davivienda', 'digital', 'Salud', 'Medicamentos', true, 12000.00, 'gasto', 'cuenta', '2026-02-24', 'Servicio', ''),
  ('demo042', 'Efectivo', 'efectivo', 'Alimentación', 'Supermercado', true, 80000.00, 'gasto', 'efectivo', '2026-03-13', 'Servicio', ''),
  ('demo042', 'Bancolombia', 'ahorros', 'Ocio', 'Suscripciones', false, 25000.00, 'gasto', 'cuenta', '2026-04-05', 'Consumo', ''),
  ('demo042', 'Efectivo', 'efectivo', 'Salud', 'Medicamentos', false, 10000.00, 'gasto', 'efectivo', '2026-05-11', 'Consumo', ''),
  ('demo042', 'Bancolombia', 'ahorros', 'Transporte', 'Combustible', true, 25000.00, 'gasto', 'cuenta', '2026-05-24', 'Compra', ''),
  ('demo042', 'Davivienda', 'digital', 'Salud', 'Medicamentos', false, 12000.00, 'gasto', 'cuenta', '2026-05-29', 'Pago', ''),
  ('demo042', 'Davivienda', 'digital', 'Ocio', 'Salidas', true, 45000.00, 'gasto', 'cuenta', '2026-05-30', 'Pago', ''),
  ('demo042', 'Efectivo', 'efectivo', 'Vivienda', 'Mantenimiento', true, 10000.00, 'gasto', 'efectivo', '2026-06-06', 'Pago', ''),
  ('demo042', 'Bancolombia', 'ahorros', 'Alimentación', 'Café', false, 250000.00, 'gasto', 'cuenta', '2026-06-22', 'Consumo', ''),
  ('demo043', 'Davivienda', 'corriente', 'Ingresos', 'Otros ingresos', false, 2800000.00, 'ingreso', 'cuenta', '2026-01-10', 'Nomina', ''),
  ('demo043', 'Banco de Bogotá', 'corriente', 'Ingresos', 'Otros ingresos', false, 2200000.00, 'ingreso', 'cuenta', '2026-01-14', 'Nomina', ''),
  ('demo043', 'Banco de Bogotá', 'corriente', 'Educación', 'Libros', true, 78000.00, 'gasto', 'cuenta', '2026-02-03', 'Pago', ''),
  ('demo043', 'Efectivo', 'efectivo', 'Salud', 'Medicamentos', false, 10000.00, 'gasto', 'efectivo', '2026-02-09', 'Pago', ''),
  ('demo043', 'Banco de Bogotá', 'corriente', 'Ocio', 'Suscripciones', false, 12000.00, 'gasto', 'cuenta', '2026-02-10', 'Consumo', ''),
  ('demo043', 'Banco de Bogotá', 'corriente', 'Transporte', 'Taxi / apps', false, 45000.00, 'gasto', 'cuenta', '2026-02-18', 'Pago', ''),
  ('demo043', 'Davivienda', 'corriente', 'Educación', 'Libros', true, 25000.00, 'gasto', 'cuenta', '2026-02-27', 'Consumo', ''),
  ('demo043', 'Nequi', 'ahorros', 'Alimentación', 'Café', true, 45000.00, 'gasto', 'cuenta', '2026-03-26', 'Consumo', ''),
  ('demo043', 'Davivienda', 'corriente', 'Ingresos', 'Salario', false, 3500000.00, 'ingreso', 'cuenta', '2026-03-29', 'Ingreso extra', ''),
  ('demo043', 'Efectivo', 'efectivo', 'Ocio', 'Suscripciones', false, 15000.00, 'gasto', 'efectivo', '2026-03-29', 'Servicio', ''),
  ('demo043', 'Davivienda', 'corriente', 'Salud', 'Consultas', false, 5000.00, 'gasto', 'cuenta', '2026-04-02', 'Compra', ''),
  ('demo043', 'Banco de Bogotá', 'corriente', 'Vivienda', 'Mantenimiento', true, 78000.00, 'gasto', 'cuenta', '2026-04-15', 'Pago', ''),
  ('demo043', 'Nequi', 'ahorros', 'Alimentación', 'Café', true, 120000.00, 'gasto', 'cuenta', '2026-05-08', 'Consumo', ''),
  ('demo043', 'Davivienda', 'corriente', 'Ocio', 'Cine', false, 180000.00, 'gasto', 'cuenta', '2026-05-12', 'Consumo', ''),
  ('demo043', 'Nequi', 'ahorros', 'Transporte', 'Transporte público', true, 5000.00, 'gasto', 'cuenta', '2026-05-18', 'Servicio', ''),
  ('demo043', 'Davivienda', 'corriente', 'Vivienda', 'Arriendo', true, 78000.00, 'gasto', 'cuenta', '2026-06-04', 'Pago', ''),
  ('demo043', 'Nequi', 'ahorros', 'Vivienda', 'Servicios', false, 12000.00, 'gasto', 'cuenta', '2026-06-18', 'Servicio', ''),
  ('demo043', 'Banco de Bogotá', 'corriente', 'Educación', 'Libros', false, 12000.00, 'gasto', 'cuenta', '2026-06-28', 'Servicio', ''),
  ('demo044', 'Nequi', 'ahorros', 'Ingresos', 'Freelance', true, 1200000.00, 'ingreso', 'cuenta', '2026-01-16', 'Pago cliente', '')
) AS v(usuario, banco, tipo_cta, cat, sub, use_cp, monto, tipo, medio_pago, fecha, descripcion, grupo)
JOIN users u ON u.usuario = v.usuario
JOIN accounts a ON a.user_id = u.id AND a.banco = v.banco AND a.tipo = v.tipo_cta
JOIN categories c ON c.nombre = v.cat
JOIN sub_categories s ON s.category_id = c.id AND s.nombre = v.sub
LEFT JOIN LATERAL (
  SELECT id FROM counterparties WHERE user_id = u.id ORDER BY id LIMIT 1
) cp ON v.use_cp;

INSERT INTO transactions (account_id, category_id, sub_category_id, contraparte_id, monto, tipo, medio_pago, fecha, descripcion, activo, grupo_transferencia)
SELECT a.id, c.id, s.id, CASE WHEN v.use_cp THEN cp.id ELSE NULL END, v.monto::numeric, v.tipo, v.medio_pago, v.fecha::date, v.descripcion, true, NULLIF(v.grupo, '')
FROM (VALUES
  ('demo044', 'Nequi', 'ahorros', 'Ingresos', 'Otros ingresos', false, 1200000.00, 'ingreso', 'cuenta', '2026-01-19', 'Ingreso extra', ''),
  ('demo044', 'Nequi', 'ahorros', 'Transferencias', 'Entre mis cuentas', false, 80000.00, 'transferencia_salida', 'cuenta', '2026-01-23', 'Retiro a efectivo (salida)', '8f4a4666-50ce-47ed-b450-764f2f07c298'),
  ('demo044', 'Efectivo', 'efectivo', 'Transferencias', 'Entre mis cuentas', false, 80000.00, 'transferencia_entrada', 'cuenta', '2026-01-23', 'Retiro a efectivo (entrada)', '8f4a4666-50ce-47ed-b450-764f2f07c298'),
  ('demo044', 'Nequi', 'ahorros', 'Educación', 'Libros', false, 25000.00, 'gasto', 'cuenta', '2026-02-05', 'Compra', ''),
  ('demo044', 'Nequi', 'ahorros', 'Educación', 'Libros', false, 12000.00, 'gasto', 'cuenta', '2026-02-27', 'Pago', ''),
  ('demo044', 'Efectivo', 'efectivo', 'Alimentación', 'Supermercado', false, 40000.00, 'gasto', 'efectivo', '2026-03-05', 'Servicio', ''),
  ('demo044', 'Banco de Bogotá', 'digital', 'Ocio', 'Salidas', false, 5000.00, 'gasto', 'cuenta', '2026-03-11', 'Pago', ''),
  ('demo044', 'Banco de Bogotá', 'digital', 'Ocio', 'Cine', false, 95000.00, 'gasto', 'cuenta', '2026-03-12', 'Compra', ''),
  ('demo044', 'Efectivo', 'efectivo', 'Educación', 'Libros', false, 15000.00, 'gasto', 'efectivo', '2026-04-19', 'Pago', ''),
  ('demo044', 'Nequi', 'ahorros', 'Ocio', 'Salidas', true, 78000.00, 'gasto', 'cuenta', '2026-04-30', 'Consumo', ''),
  ('demo044', 'Nequi', 'ahorros', 'Alimentación', 'Supermercado', false, 12000.00, 'gasto', 'cuenta', '2026-05-09', 'Servicio', ''),
  ('demo044', 'Efectivo', 'efectivo', 'Ocio', 'Salidas', true, 10000.00, 'gasto', 'efectivo', '2026-05-18', 'Consumo', ''),
  ('demo045', 'Nequi', 'corriente', 'Transferencias', 'Entre mis cuentas', false, 100000.00, 'transferencia_salida', 'cuenta', '2026-01-16', 'Retiro a efectivo (salida)', '4d25ea72-37c0-4d89-918c-311766f7e64a'),
  ('demo045', 'Efectivo', 'efectivo', 'Transferencias', 'Entre mis cuentas', false, 100000.00, 'transferencia_entrada', 'cuenta', '2026-01-16', 'Retiro a efectivo (entrada)', '4d25ea72-37c0-4d89-918c-311766f7e64a'),
  ('demo045', 'Nequi', 'corriente', 'Ingresos', 'Otros ingresos', false, 800000.00, 'ingreso', 'cuenta', '2026-01-17', 'Ingreso extra', ''),
  ('demo045', 'Nequi', 'corriente', 'Ingresos', 'Salario', true, 2800000.00, 'ingreso', 'cuenta', '2026-01-17', 'Ingreso extra', ''),
  ('demo045', 'Nequi', 'corriente', 'Transporte', 'Taxi / apps', false, 5000.00, 'gasto', 'cuenta', '2026-01-25', 'Compra', ''),
  ('demo045', 'Davivienda', 'corriente', 'Ocio', 'Suscripciones', false, 120000.00, 'gasto', 'cuenta', '2026-02-05', 'Servicio', ''),
  ('demo045', 'BBVA', 'digital', 'Ingresos', 'Otros ingresos', true, 800000.00, 'ingreso', 'cuenta', '2026-03-22', 'Ingreso extra', ''),
  ('demo045', 'Nequi', 'corriente', 'Ocio', 'Cine', false, 78000.00, 'gasto', 'cuenta', '2026-04-20', 'Consumo', ''),
  ('demo045', 'Davivienda', 'corriente', 'Vivienda', 'Arriendo', false, 45000.00, 'gasto', 'cuenta', '2026-04-24', 'Servicio', ''),
  ('demo045', 'BBVA', 'digital', 'Vivienda', 'Mantenimiento', false, 5000.00, 'gasto', 'cuenta', '2026-04-28', 'Pago', ''),
  ('demo045', 'Efectivo', 'efectivo', 'Alimentación', 'Café', true, 5000.00, 'gasto', 'efectivo', '2026-05-15', 'Consumo', ''),
  ('demo045', 'Nequi', 'corriente', 'Vivienda', 'Mantenimiento', false, 78000.00, 'gasto', 'cuenta', '2026-05-29', 'Servicio', ''),
  ('demo045', 'Efectivo', 'efectivo', 'Educación', 'Libros', false, 40000.00, 'gasto', 'efectivo', '2026-05-29', 'Pago', ''),
  ('demo045', 'Davivienda', 'corriente', 'Transferencias', 'Entre mis cuentas', false, 150000.00, 'transferencia_salida', 'cuenta', '2026-06-14', 'Transferencia entre cuentas (salida)', '7d47979d-b5a6-4bc9-b7b0-4238118f14cb'),
  ('demo045', 'Efectivo', 'efectivo', 'Transferencias', 'Entre mis cuentas', false, 150000.00, 'transferencia_entrada', 'cuenta', '2026-06-14', 'Transferencia entre cuentas (entrada)', '7d47979d-b5a6-4bc9-b7b0-4238118f14cb'),
  ('demo045', 'BBVA', 'digital', 'Educación', 'Libros', true, 5000.00, 'gasto', 'cuenta', '2026-06-20', 'Compra', ''),
  ('demo045', 'Davivienda', 'corriente', 'Vivienda', 'Servicios', false, 35000.00, 'gasto', 'cuenta', '2026-06-22', 'Consumo', ''),
  ('demo046', 'Davivienda', 'corriente', 'Ingresos', 'Freelance', true, 2800000.00, 'ingreso', 'cuenta', '2026-01-12', 'Pago cliente', ''),
  ('demo046', 'Bancolombia', 'ahorros', 'Ocio', 'Suscripciones', false, 78000.00, 'gasto', 'cuenta', '2026-01-18', 'Pago', ''),
  ('demo046', 'Daviplata', 'ahorros', 'Ocio', 'Salidas', false, 5000.00, 'gasto', 'cuenta', '2026-01-27', 'Servicio', ''),
  ('demo046', 'Daviplata', 'ahorros', 'Ocio', 'Suscripciones', false, 120000.00, 'gasto', 'cuenta', '2026-02-06', 'Pago', ''),
  ('demo046', 'Daviplata', 'ahorros', 'Salud', 'Consultas', true, 225000.00, 'gasto', 'cuenta', '2026-02-13', 'Compra', ''),
  ('demo046', 'Bancolombia', 'ahorros', 'Salud', 'Consultas', false, 12000.00, 'gasto', 'cuenta', '2026-02-25', 'Consumo', ''),
  ('demo046', 'Davivienda', 'corriente', 'Vivienda', 'Mantenimiento', true, 25000.00, 'gasto', 'cuenta', '2026-04-22', 'Pago', ''),
  ('demo046', 'Bancolombia', 'ahorros', 'Ocio', 'Cine', false, 60000.00, 'gasto', 'cuenta', '2026-05-20', 'Pago', ''),
  ('demo046', 'Davivienda', 'corriente', 'Vivienda', 'Mantenimiento', true, 180000.00, 'gasto', 'cuenta', '2026-06-23', 'Servicio', ''),
  ('demo047', 'Banco de Bogotá', 'digital', 'Ingresos', 'Salario', false, 3500000.00, 'ingreso', 'cuenta', '2026-01-20', 'Pago cliente', ''),
  ('demo047', 'Banco de Bogotá', 'digital', 'Ocio', 'Cine', true, 120000.00, 'gasto', 'cuenta', '2026-01-30', 'Consumo', '')
) AS v(usuario, banco, tipo_cta, cat, sub, use_cp, monto, tipo, medio_pago, fecha, descripcion, grupo)
JOIN users u ON u.usuario = v.usuario
JOIN accounts a ON a.user_id = u.id AND a.banco = v.banco AND a.tipo = v.tipo_cta
JOIN categories c ON c.nombre = v.cat
JOIN sub_categories s ON s.category_id = c.id AND s.nombre = v.sub
LEFT JOIN LATERAL (
  SELECT id FROM counterparties WHERE user_id = u.id ORDER BY id LIMIT 1
) cp ON v.use_cp;

INSERT INTO transactions (account_id, category_id, sub_category_id, contraparte_id, monto, tipo, medio_pago, fecha, descripcion, activo, grupo_transferencia)
SELECT a.id, c.id, s.id, CASE WHEN v.use_cp THEN cp.id ELSE NULL END, v.monto::numeric, v.tipo, v.medio_pago, v.fecha::date, v.descripcion, true, NULLIF(v.grupo, '')
FROM (VALUES
  ('demo047', 'Banco de Bogotá', 'digital', 'Ocio', 'Cine', false, 12000.00, 'gasto', 'cuenta', '2026-02-02', 'Pago', ''),
  ('demo047', 'BBVA', 'corriente', 'Salud', 'Medicamentos', true, 25000.00, 'gasto', 'cuenta', '2026-02-12', 'Consumo', ''),
  ('demo047', 'BBVA', 'corriente', 'Educación', 'Cursos', true, 75000.00, 'gasto', 'cuenta', '2026-02-28', 'Compra', ''),
  ('demo047', 'Banco de Bogotá', 'digital', 'Transporte', 'Transporte público', false, 250000.00, 'gasto', 'cuenta', '2026-03-14', 'Pago', ''),
  ('demo047', 'Banco de Bogotá', 'digital', 'Ocio', 'Suscripciones', true, 180000.00, 'gasto', 'cuenta', '2026-03-23', 'Compra', ''),
  ('demo047', 'Banco de Bogotá', 'digital', 'Salud', 'Consultas', false, 45000.00, 'gasto', 'cuenta', '2026-04-04', 'Consumo', ''),
  ('demo047', 'Banco de Bogotá', 'digital', 'Ocio', 'Cine', false, 250000.00, 'gasto', 'cuenta', '2026-06-10', 'Servicio', ''),
  ('demo047', 'Nequi', 'ahorros', 'Transporte', 'Transporte público', false, 5000.00, 'gasto', 'cuenta', '2026-06-12', 'Pago', ''),
  ('demo048', 'Daviplata', 'ahorros', 'Ingresos', 'Freelance', false, 2200000.00, 'ingreso', 'cuenta', '2026-01-21', 'Ingreso extra', ''),
  ('demo048', 'Banco de Bogotá', 'digital', 'Transporte', 'Transporte público', false, 200000.00, 'gasto', 'cuenta', '2026-01-26', 'Pago', ''),
  ('demo048', 'Daviplata', 'ahorros', 'Salud', 'Medicamentos', false, 180000.00, 'gasto', 'cuenta', '2026-01-27', 'Consumo', ''),
  ('demo048', 'Bancolombia', 'digital', 'Educación', 'Cursos', true, 12000.00, 'gasto', 'cuenta', '2026-02-20', 'Consumo', ''),
  ('demo048', 'Daviplata', 'ahorros', 'Salud', 'Medicamentos', true, 25000.00, 'gasto', 'cuenta', '2026-02-21', 'Compra', ''),
  ('demo048', 'Bancolombia', 'digital', 'Salud', 'Medicamentos', false, 120000.00, 'gasto', 'cuenta', '2026-03-03', 'Servicio', ''),
  ('demo048', 'Daviplata', 'ahorros', 'Alimentación', 'Supermercado', false, 78000.00, 'gasto', 'cuenta', '2026-03-23', 'Servicio', ''),
  ('demo048', 'Bancolombia', 'digital', 'Vivienda', 'Arriendo', false, 68000.00, 'gasto', 'cuenta', '2026-04-08', 'Servicio', ''),
  ('demo048', 'Daviplata', 'ahorros', 'Vivienda', 'Servicios', false, 180000.00, 'gasto', 'cuenta', '2026-05-12', 'Pago', ''),
  ('demo048', 'Daviplata', 'ahorros', 'Vivienda', 'Mantenimiento', false, 45000.00, 'gasto', 'cuenta', '2026-06-28', 'Compra', ''),
  ('demo049', 'Davivienda', 'ahorros', 'Ingresos', 'Freelance', false, 1800000.00, 'ingreso', 'cuenta', '2026-01-09', 'Nomina', ''),
  ('demo049', 'Davivienda', 'ahorros', 'Ingresos', 'Freelance', false, 1200000.00, 'ingreso', 'cuenta', '2026-01-10', 'Pago cliente', ''),
  ('demo049', 'Davivienda', 'ahorros', 'Ocio', 'Suscripciones', true, 45000.00, 'gasto', 'cuenta', '2026-01-16', 'Servicio', ''),
  ('demo049', 'Efectivo', 'efectivo', 'Vivienda', 'Arriendo', false, 5000.00, 'gasto', 'efectivo', '2026-01-28', 'Servicio', ''),
  ('demo049', 'Davivienda', 'ahorros', 'Transferencias', 'Entre mis cuentas', false, 50000.00, 'transferencia_salida', 'cuenta', '2026-01-29', 'Retiro a efectivo (salida)', 'b3999906-1208-4760-bccc-5f2a0f4f4206'),
  ('demo049', 'Efectivo', 'efectivo', 'Transferencias', 'Entre mis cuentas', false, 50000.00, 'transferencia_entrada', 'cuenta', '2026-01-29', 'Retiro a efectivo (entrada)', 'b3999906-1208-4760-bccc-5f2a0f4f4206'),
  ('demo049', 'Daviplata', 'corriente', 'Educación', 'Libros', false, 45000.00, 'gasto', 'cuenta', '2026-02-05', 'Servicio', ''),
  ('demo049', 'Banco de Bogotá', 'ahorros', 'Transporte', 'Taxi / apps', false, 50000.00, 'gasto', 'cuenta', '2026-02-20', 'Compra', ''),
  ('demo049', 'Daviplata', 'corriente', 'Transferencias', 'Entre mis cuentas', false, 50000.00, 'transferencia_salida', 'cuenta', '2026-03-08', 'Transferencia entre cuentas (salida)', 'd89d940a-c06b-47b5-80b9-f0c67917b358'),
  ('demo049', 'Efectivo', 'efectivo', 'Transferencias', 'Entre mis cuentas', false, 50000.00, 'transferencia_entrada', 'cuenta', '2026-03-08', 'Transferencia entre cuentas (entrada)', 'd89d940a-c06b-47b5-80b9-f0c67917b358'),
  ('demo049', 'Daviplata', 'corriente', 'Vivienda', 'Arriendo', false, 5000.00, 'gasto', 'cuenta', '2026-03-13', 'Consumo', ''),
  ('demo049', 'Efectivo', 'efectivo', 'Vivienda', 'Arriendo', true, 80000.00, 'gasto', 'efectivo', '2026-04-14', 'Compra', ''),
  ('demo049', 'Efectivo', 'efectivo', 'Salud', 'Consultas', true, 25000.00, 'gasto', 'efectivo', '2026-04-25', 'Compra', ''),
  ('demo049', 'Efectivo', 'efectivo', 'Transporte', 'Combustible', false, 15000.00, 'gasto', 'efectivo', '2026-05-18', 'Servicio', ''),
  ('demo049', 'Davivienda', 'ahorros', 'Educación', 'Libros', true, 5000.00, 'gasto', 'cuenta', '2026-05-19', 'Pago', ''),
  ('demo050', 'Bancolombia', 'digital', 'Ingresos', 'Freelance', true, 2800000.00, 'ingreso', 'cuenta', '2026-01-11', 'Pago cliente', ''),
  ('demo050', 'Banco de Bogotá', 'ahorros', 'Ingresos', 'Freelance', true, 2800000.00, 'ingreso', 'cuenta', '2026-01-20', 'Ingreso extra', ''),
  ('demo050', 'Efectivo', 'efectivo', 'Ocio', 'Cine', true, 5000.00, 'gasto', 'efectivo', '2026-02-07', 'Pago', ''),
  ('demo050', 'Daviplata', 'digital', 'Ingresos', 'Otros ingresos', true, 3500000.00, 'ingreso', 'cuenta', '2026-02-20', 'Pago cliente', ''),
  ('demo050', 'Banco de Bogotá', 'ahorros', 'Transporte', 'Transporte público', true, 250000.00, 'gasto', 'cuenta', '2026-03-02', 'Consumo', ''),
  ('demo050', 'Banco de Bogotá', 'ahorros', 'Transporte', 'Combustible', false, 120000.00, 'gasto', 'cuenta', '2026-03-03', 'Compra', ''),
  ('demo050', 'Daviplata', 'digital', 'Transporte', 'Transporte público', false, 5000.00, 'gasto', 'cuenta', '2026-03-25', 'Pago', '')
) AS v(usuario, banco, tipo_cta, cat, sub, use_cp, monto, tipo, medio_pago, fecha, descripcion, grupo)
JOIN users u ON u.usuario = v.usuario
JOIN accounts a ON a.user_id = u.id AND a.banco = v.banco AND a.tipo = v.tipo_cta
JOIN categories c ON c.nombre = v.cat
JOIN sub_categories s ON s.category_id = c.id AND s.nombre = v.sub
LEFT JOIN LATERAL (
  SELECT id FROM counterparties WHERE user_id = u.id ORDER BY id LIMIT 1
) cp ON v.use_cp;

INSERT INTO transactions (account_id, category_id, sub_category_id, contraparte_id, monto, tipo, medio_pago, fecha, descripcion, activo, grupo_transferencia)
SELECT a.id, c.id, s.id, CASE WHEN v.use_cp THEN cp.id ELSE NULL END, v.monto::numeric, v.tipo, v.medio_pago, v.fecha::date, v.descripcion, true, NULLIF(v.grupo, '')
FROM (VALUES
  ('demo050', 'Daviplata', 'digital', 'Educación', 'Libros', true, 12000.00, 'gasto', 'cuenta', '2026-03-30', 'Pago', ''),
  ('demo050', 'Banco de Bogotá', 'ahorros', 'Educación', 'Libros', true, 180000.00, 'gasto', 'cuenta', '2026-04-06', 'Consumo', ''),
  ('demo050', 'Daviplata', 'digital', 'Alimentación', 'Supermercado', false, 12000.00, 'gasto', 'cuenta', '2026-04-13', 'Pago', ''),
  ('demo050', 'Daviplata', 'digital', 'Transferencias', 'Entre mis cuentas', false, 300000.00, 'transferencia_salida', 'cuenta', '2026-04-16', 'Transferencia entre cuentas (salida)', 'e321ed8d-996f-4208-bc96-f0b6b9936f6a'),
  ('demo050', 'Banco de Bogotá', 'ahorros', 'Transferencias', 'Entre mis cuentas', false, 300000.00, 'transferencia_entrada', 'cuenta', '2026-04-16', 'Transferencia entre cuentas (entrada)', 'e321ed8d-996f-4208-bc96-f0b6b9936f6a'),
  ('demo050', 'Daviplata', 'digital', 'Ocio', 'Salidas', false, 120000.00, 'gasto', 'cuenta', '2026-05-06', 'Consumo', ''),
  ('demo050', 'Daviplata', 'digital', 'Alimentación', 'Restaurante', false, 78000.00, 'gasto', 'cuenta', '2026-05-13', 'Compra', ''),
  ('demo050', 'Daviplata', 'digital', 'Transporte', 'Combustible', false, 45000.00, 'gasto', 'cuenta', '2026-05-19', 'Compra', ''),
  ('demo050', 'Banco de Bogotá', 'ahorros', 'Vivienda', 'Arriendo', false, 180000.00, 'gasto', 'cuenta', '2026-06-01', 'Pago', ''),
  ('demo050', 'Daviplata', 'digital', 'Ocio', 'Salidas', false, 25000.00, 'gasto', 'cuenta', '2026-06-02', 'Compra', ''),
  ('demo050', 'Efectivo', 'efectivo', 'Ocio', 'Cine', false, 40000.00, 'gasto', 'efectivo', '2026-06-05', 'Servicio', ''),
  ('demo050', 'Bancolombia', 'digital', 'Transporte', 'Taxi / apps', false, 12000.00, 'gasto', 'cuenta', '2026-06-06', 'Pago', ''),
  ('demo050', 'Banco de Bogotá', 'ahorros', 'Transporte', 'Taxi / apps', false, 120000.00, 'gasto', 'cuenta', '2026-06-08', 'Servicio', ''),
  ('demo051', 'Davivienda', 'corriente', 'Ingresos', 'Salario', false, 1200000.00, 'ingreso', 'cuenta', '2026-01-10', 'Nomina', ''),
  ('demo051', 'Daviplata', 'ahorros', 'Ingresos', 'Freelance', false, 1200000.00, 'ingreso', 'cuenta', '2026-01-16', 'Pago cliente', ''),
  ('demo051', 'Daviplata', 'ahorros', 'Vivienda', 'Mantenimiento', true, 45000.00, 'gasto', 'cuenta', '2026-01-16', 'Consumo', ''),
  ('demo051', 'BBVA', 'digital', 'Alimentación', 'Café', false, 45000.00, 'gasto', 'cuenta', '2026-01-20', 'Consumo', ''),
  ('demo051', 'Daviplata', 'ahorros', 'Transporte', 'Combustible', true, 250000.00, 'gasto', 'cuenta', '2026-03-10', 'Consumo', ''),
  ('demo051', 'Davivienda', 'corriente', 'Alimentación', 'Café', false, 180000.00, 'gasto', 'cuenta', '2026-03-12', 'Compra', ''),
  ('demo051', 'BBVA', 'digital', 'Ocio', 'Salidas', false, 120000.00, 'gasto', 'cuenta', '2026-03-26', 'Servicio', ''),
  ('demo051', 'Daviplata', 'ahorros', 'Alimentación', 'Supermercado', true, 45000.00, 'gasto', 'cuenta', '2026-04-01', 'Servicio', ''),
  ('demo051', 'Davivienda', 'corriente', 'Salud', 'Consultas', true, 5000.00, 'gasto', 'cuenta', '2026-04-05', 'Pago', ''),
  ('demo051', 'Davivienda', 'corriente', 'Transporte', 'Transporte público', false, 45000.00, 'gasto', 'cuenta', '2026-05-25', 'Compra', ''),
  ('demo051', 'BBVA', 'digital', 'Alimentación', 'Café', false, 185000.00, 'gasto', 'cuenta', '2026-06-05', 'Pago', ''),
  ('demo052', 'Banco de Bogotá', 'ahorros', 'Transferencias', 'Entre mis cuentas', false, 150000.00, 'transferencia_salida', 'cuenta', '2026-01-14', 'Retiro a efectivo (salida)', '323e7353-8137-4055-9552-5aaeb09cc47c'),
  ('demo052', 'Efectivo', 'efectivo', 'Transferencias', 'Entre mis cuentas', false, 150000.00, 'transferencia_entrada', 'cuenta', '2026-01-14', 'Retiro a efectivo (entrada)', '323e7353-8137-4055-9552-5aaeb09cc47c'),
  ('demo052', 'Banco de Bogotá', 'ahorros', 'Ingresos', 'Salario', false, 1200000.00, 'ingreso', 'cuenta', '2026-01-16', 'Ingreso extra', ''),
  ('demo052', 'Banco de Bogotá', 'ahorros', 'Alimentación', 'Restaurante', false, 12000.00, 'gasto', 'cuenta', '2026-02-03', 'Pago', ''),
  ('demo052', 'Banco de Bogotá', 'ahorros', 'Alimentación', 'Supermercado', false, 78000.00, 'gasto', 'cuenta', '2026-02-07', 'Consumo', ''),
  ('demo052', 'Banco de Bogotá', 'ahorros', 'Educación', 'Cursos', true, 78000.00, 'gasto', 'cuenta', '2026-02-13', 'Servicio', ''),
  ('demo052', 'Banco de Bogotá', 'ahorros', 'Vivienda', 'Arriendo', false, 45000.00, 'gasto', 'cuenta', '2026-03-05', 'Consumo', ''),
  ('demo052', 'Efectivo', 'efectivo', 'Transporte', 'Transporte público', false, 40000.00, 'gasto', 'efectivo', '2026-03-07', 'Compra', ''),
  ('demo052', 'Banco de Bogotá', 'ahorros', 'Transporte', 'Taxi / apps', true, 78000.00, 'gasto', 'cuenta', '2026-03-19', 'Compra', ''),
  ('demo052', 'BBVA', 'digital', 'Educación', 'Cursos', true, 5000.00, 'gasto', 'cuenta', '2026-03-20', 'Compra', ''),
  ('demo052', 'BBVA', 'digital', 'Transporte', 'Combustible', true, 120000.00, 'gasto', 'cuenta', '2026-03-25', 'Compra', ''),
  ('demo052', 'BBVA', 'digital', 'Ocio', 'Suscripciones', false, 45000.00, 'gasto', 'cuenta', '2026-04-08', 'Compra', ''),
  ('demo052', 'BBVA', 'digital', 'Transporte', 'Taxi / apps', false, 12000.00, 'gasto', 'cuenta', '2026-04-15', 'Pago', ''),
  ('demo052', 'BBVA', 'digital', 'Alimentación', 'Restaurante', false, 5000.00, 'gasto', 'cuenta', '2026-04-19', 'Pago', ''),
  ('demo052', 'Efectivo', 'efectivo', 'Salud', 'Consultas', false, 15000.00, 'gasto', 'efectivo', '2026-04-22', 'Servicio', ''),
  ('demo052', 'Banco de Bogotá', 'ahorros', 'Ocio', 'Cine', true, 5000.00, 'gasto', 'cuenta', '2026-05-01', 'Consumo', '')
) AS v(usuario, banco, tipo_cta, cat, sub, use_cp, monto, tipo, medio_pago, fecha, descripcion, grupo)
JOIN users u ON u.usuario = v.usuario
JOIN accounts a ON a.user_id = u.id AND a.banco = v.banco AND a.tipo = v.tipo_cta
JOIN categories c ON c.nombre = v.cat
JOIN sub_categories s ON s.category_id = c.id AND s.nombre = v.sub
LEFT JOIN LATERAL (
  SELECT id FROM counterparties WHERE user_id = u.id ORDER BY id LIMIT 1
) cp ON v.use_cp;

INSERT INTO transactions (account_id, category_id, sub_category_id, contraparte_id, monto, tipo, medio_pago, fecha, descripcion, activo, grupo_transferencia)
SELECT a.id, c.id, s.id, CASE WHEN v.use_cp THEN cp.id ELSE NULL END, v.monto::numeric, v.tipo, v.medio_pago, v.fecha::date, v.descripcion, true, NULLIF(v.grupo, '')
FROM (VALUES
  ('demo052', 'BBVA', 'digital', 'Vivienda', 'Mantenimiento', false, 13000.00, 'gasto', 'cuenta', '2026-05-04', 'Compra', ''),
  ('demo052', 'Efectivo', 'efectivo', 'Vivienda', 'Mantenimiento', true, 40000.00, 'gasto', 'efectivo', '2026-05-16', 'Pago', ''),
  ('demo053', 'Nequi', 'corriente', 'Ingresos', 'Freelance', false, 2200000.00, 'ingreso', 'cuenta', '2026-01-19', 'Pago cliente', ''),
  ('demo053', 'Nequi', 'corriente', 'Vivienda', 'Arriendo', true, 25000.00, 'gasto', 'cuenta', '2026-02-03', 'Compra', ''),
  ('demo053', 'BBVA', 'ahorros', 'Vivienda', 'Servicios', true, 78000.00, 'gasto', 'cuenta', '2026-02-16', 'Pago', ''),
  ('demo053', 'BBVA', 'ahorros', 'Alimentación', 'Café', true, 120000.00, 'gasto', 'cuenta', '2026-02-23', 'Servicio', ''),
  ('demo053', 'Nequi', 'corriente', 'Transporte', 'Taxi / apps', false, 120000.00, 'gasto', 'cuenta', '2026-03-05', 'Servicio', ''),
  ('demo053', 'BBVA', 'ahorros', 'Vivienda', 'Arriendo', true, 25000.00, 'gasto', 'cuenta', '2026-04-08', 'Pago', ''),
  ('demo053', 'BBVA', 'ahorros', 'Ocio', 'Salidas', false, 78000.00, 'gasto', 'cuenta', '2026-04-08', 'Pago', ''),
  ('demo053', 'BBVA', 'ahorros', 'Alimentación', 'Café', false, 45000.00, 'gasto', 'cuenta', '2026-06-02', 'Pago', ''),
  ('demo053', 'Nequi', 'corriente', 'Salud', 'Consultas', false, 250000.00, 'gasto', 'cuenta', '2026-06-08', 'Servicio', ''),
  ('demo054', 'BBVA', 'digital', 'Ingresos', 'Salario', false, 2800000.00, 'ingreso', 'cuenta', '2026-01-16', 'Pago cliente', ''),
  ('demo054', 'Davivienda', 'digital', 'Ingresos', 'Salario', false, 800000.00, 'ingreso', 'cuenta', '2026-01-17', 'Pago cliente', ''),
  ('demo054', 'BBVA', 'digital', 'Educación', 'Cursos', true, 45000.00, 'gasto', 'cuenta', '2026-01-31', 'Compra', ''),
  ('demo054', 'Daviplata', 'digital', 'Transferencias', 'Entre mis cuentas', false, 300000.00, 'transferencia_salida', 'cuenta', '2026-02-16', 'Retiro a efectivo (salida)', '7ca4b8cf-ddcb-48d9-aa88-49ff5b65b176'),
  ('demo054', 'Efectivo', 'efectivo', 'Transferencias', 'Entre mis cuentas', false, 300000.00, 'transferencia_entrada', 'cuenta', '2026-02-16', 'Retiro a efectivo (entrada)', '7ca4b8cf-ddcb-48d9-aa88-49ff5b65b176'),
  ('demo054', 'BBVA', 'digital', 'Transporte', 'Combustible', true, 25000.00, 'gasto', 'cuenta', '2026-02-23', 'Compra', ''),
  ('demo054', 'Davivienda', 'digital', 'Alimentación', 'Café', false, 120000.00, 'gasto', 'cuenta', '2026-03-01', 'Servicio', ''),
  ('demo054', 'Efectivo', 'efectivo', 'Transporte', 'Taxi / apps', false, 40000.00, 'gasto', 'efectivo', '2026-03-12', 'Servicio', ''),
  ('demo054', 'Daviplata', 'digital', 'Salud', 'Consultas', true, 25000.00, 'gasto', 'cuenta', '2026-04-03', 'Pago', ''),
  ('demo054', 'Daviplata', 'digital', 'Alimentación', 'Restaurante', true, 25000.00, 'gasto', 'cuenta', '2026-05-06', 'Servicio', ''),
  ('demo054', 'BBVA', 'digital', 'Salud', 'Medicamentos', true, 250000.00, 'gasto', 'cuenta', '2026-05-16', 'Pago', ''),
  ('demo054', 'Davivienda', 'digital', 'Alimentación', 'Supermercado', true, 250000.00, 'gasto', 'cuenta', '2026-07-02', 'Servicio', ''),
  ('demo055', 'Banco de Bogotá', 'ahorros', 'Ingresos', 'Freelance', false, 1800000.00, 'ingreso', 'cuenta', '2026-01-11', 'Pago cliente', ''),
  ('demo055', 'Banco de Bogotá', 'ahorros', 'Ingresos', 'Otros ingresos', false, 2200000.00, 'ingreso', 'cuenta', '2026-01-16', 'Nomina', ''),
  ('demo055', 'Banco de Bogotá', 'ahorros', 'Vivienda', 'Mantenimiento', false, 12000.00, 'gasto', 'cuenta', '2026-01-31', 'Consumo', ''),
  ('demo055', 'Banco de Bogotá', 'ahorros', 'Alimentación', 'Restaurante', false, 45000.00, 'gasto', 'cuenta', '2026-02-10', 'Compra', ''),
  ('demo055', 'Banco de Bogotá', 'ahorros', 'Transferencias', 'Entre mis cuentas', false, 300000.00, 'transferencia_salida', 'cuenta', '2026-02-14', 'Transferencia entre cuentas (salida)', '1e5ad324-5370-4cc4-94b8-4f9eeb747f54'),
  ('demo055', 'Efectivo', 'efectivo', 'Transferencias', 'Entre mis cuentas', false, 300000.00, 'transferencia_entrada', 'cuenta', '2026-02-14', 'Transferencia entre cuentas (entrada)', '1e5ad324-5370-4cc4-94b8-4f9eeb747f54'),
  ('demo055', 'Daviplata', 'corriente', 'Salud', 'Consultas', false, 180000.00, 'gasto', 'cuenta', '2026-02-15', 'Consumo', ''),
  ('demo055', 'Daviplata', 'corriente', 'Educación', 'Libros', false, 25000.00, 'gasto', 'cuenta', '2026-03-01', 'Servicio', ''),
  ('demo055', 'Banco de Bogotá', 'ahorros', 'Salud', 'Medicamentos', true, 45000.00, 'gasto', 'cuenta', '2026-03-05', 'Pago', ''),
  ('demo055', 'Banco de Bogotá', 'ahorros', 'Transporte', 'Combustible', false, 250000.00, 'gasto', 'cuenta', '2026-04-01', 'Pago', ''),
  ('demo055', 'Daviplata', 'corriente', 'Alimentación', 'Restaurante', true, 145000.00, 'gasto', 'cuenta', '2026-04-13', 'Consumo', ''),
  ('demo055', 'Banco de Bogotá', 'ahorros', 'Vivienda', 'Arriendo', true, 5000.00, 'gasto', 'cuenta', '2026-05-05', 'Consumo', ''),
  ('demo055', 'Efectivo', 'efectivo', 'Salud', 'Medicamentos', false, 5000.00, 'gasto', 'efectivo', '2026-05-22', 'Consumo', ''),
  ('demo055', 'Efectivo', 'efectivo', 'Salud', 'Consultas', false, 5000.00, 'gasto', 'efectivo', '2026-06-23', 'Consumo', ''),
  ('demo055', 'Banco de Bogotá', 'ahorros', 'Vivienda', 'Arriendo', false, 25000.00, 'gasto', 'cuenta', '2026-06-24', 'Consumo', ''),
  ('demo056', 'Nequi', 'corriente', 'Ingresos', 'Salario', false, 3500000.00, 'ingreso', 'cuenta', '2026-01-06', 'Pago cliente', ''),
  ('demo056', 'Nequi', 'corriente', 'Ingresos', 'Freelance', false, 1200000.00, 'ingreso', 'cuenta', '2026-01-10', 'Pago cliente', '')
) AS v(usuario, banco, tipo_cta, cat, sub, use_cp, monto, tipo, medio_pago, fecha, descripcion, grupo)
JOIN users u ON u.usuario = v.usuario
JOIN accounts a ON a.user_id = u.id AND a.banco = v.banco AND a.tipo = v.tipo_cta
JOIN categories c ON c.nombre = v.cat
JOIN sub_categories s ON s.category_id = c.id AND s.nombre = v.sub
LEFT JOIN LATERAL (
  SELECT id FROM counterparties WHERE user_id = u.id ORDER BY id LIMIT 1
) cp ON v.use_cp;

INSERT INTO transactions (account_id, category_id, sub_category_id, contraparte_id, monto, tipo, medio_pago, fecha, descripcion, activo, grupo_transferencia)
SELECT a.id, c.id, s.id, CASE WHEN v.use_cp THEN cp.id ELSE NULL END, v.monto::numeric, v.tipo, v.medio_pago, v.fecha::date, v.descripcion, true, NULLIF(v.grupo, '')
FROM (VALUES
  ('demo056', 'Nequi', 'corriente', 'Salud', 'Medicamentos', true, 45000.00, 'gasto', 'cuenta', '2026-02-11', 'Pago', ''),
  ('demo056', 'BBVA', 'digital', 'Ingresos', 'Salario', false, 1200000.00, 'ingreso', 'cuenta', '2026-02-17', 'Pago cliente', ''),
  ('demo056', 'Nequi', 'corriente', 'Vivienda', 'Arriendo', false, 25000.00, 'gasto', 'cuenta', '2026-02-24', 'Consumo', ''),
  ('demo056', 'Nequi', 'corriente', 'Transporte', 'Transporte público', false, 120000.00, 'gasto', 'cuenta', '2026-03-01', 'Compra', ''),
  ('demo056', 'BBVA', 'digital', 'Alimentación', 'Restaurante', true, 45000.00, 'gasto', 'cuenta', '2026-04-01', 'Servicio', ''),
  ('demo056', 'BBVA', 'digital', 'Salud', 'Medicamentos', false, 5000.00, 'gasto', 'cuenta', '2026-04-19', 'Compra', ''),
  ('demo056', 'BBVA', 'digital', 'Educación', 'Cursos', true, 120000.00, 'gasto', 'cuenta', '2026-04-22', 'Compra', ''),
  ('demo056', 'Nequi', 'corriente', 'Salud', 'Medicamentos', true, 5000.00, 'gasto', 'cuenta', '2026-05-29', 'Pago', ''),
  ('demo056', 'BBVA', 'digital', 'Vivienda', 'Mantenimiento', false, 78000.00, 'gasto', 'cuenta', '2026-06-08', 'Consumo', ''),
  ('demo056', 'BBVA', 'digital', 'Transporte', 'Transporte público', true, 78000.00, 'gasto', 'cuenta', '2026-06-14', 'Pago', ''),
  ('demo056', 'BBVA', 'digital', 'Vivienda', 'Arriendo', false, 12000.00, 'gasto', 'cuenta', '2026-06-17', 'Consumo', ''),
  ('demo056', 'Nequi', 'corriente', 'Salud', 'Medicamentos', true, 25000.00, 'gasto', 'cuenta', '2026-06-22', 'Pago', ''),
  ('demo057', 'BBVA', 'ahorros', 'Ingresos', 'Freelance', true, 2200000.00, 'ingreso', 'cuenta', '2026-01-10', 'Nomina', ''),
  ('demo057', 'Bancolombia', 'ahorros', 'Ingresos', 'Freelance', false, 1800000.00, 'ingreso', 'cuenta', '2026-01-14', 'Pago cliente', ''),
  ('demo057', 'Bancolombia', 'ahorros', 'Transferencias', 'Entre mis cuentas', false, 100000.00, 'transferencia_salida', 'cuenta', '2026-01-27', 'Retiro a efectivo (salida)', 'ba826bb8-8392-45ec-b9c8-c87591ccc91c'),
  ('demo057', 'Efectivo', 'efectivo', 'Transferencias', 'Entre mis cuentas', false, 100000.00, 'transferencia_entrada', 'cuenta', '2026-01-27', 'Retiro a efectivo (entrada)', 'ba826bb8-8392-45ec-b9c8-c87591ccc91c'),
  ('demo057', 'BBVA', 'ahorros', 'Transporte', 'Combustible', false, 25000.00, 'gasto', 'cuenta', '2026-02-03', 'Servicio', ''),
  ('demo057', 'Bancolombia', 'ahorros', 'Alimentación', 'Café', false, 120000.00, 'gasto', 'cuenta', '2026-02-06', 'Consumo', ''),
  ('demo057', 'BBVA', 'ahorros', 'Vivienda', 'Servicios', false, 180000.00, 'gasto', 'cuenta', '2026-02-07', 'Pago', ''),
  ('demo057', 'BBVA', 'ahorros', 'Alimentación', 'Café', true, 180000.00, 'gasto', 'cuenta', '2026-02-16', 'Consumo', ''),
  ('demo057', 'Efectivo', 'efectivo', 'Ocio', 'Salidas', false, 55000.00, 'gasto', 'efectivo', '2026-03-08', 'Servicio', ''),
  ('demo057', 'BBVA', 'ahorros', 'Transporte', 'Taxi / apps', false, 45000.00, 'gasto', 'cuenta', '2026-03-12', 'Compra', ''),
  ('demo057', 'BBVA', 'ahorros', 'Educación', 'Cursos', false, 12000.00, 'gasto', 'cuenta', '2026-03-14', 'Consumo', ''),
  ('demo057', 'BBVA', 'ahorros', 'Salud', 'Medicamentos', true, 25000.00, 'gasto', 'cuenta', '2026-04-03', 'Servicio', ''),
  ('demo057', 'Efectivo', 'efectivo', 'Ocio', 'Suscripciones', false, 5000.00, 'gasto', 'efectivo', '2026-04-15', 'Consumo', ''),
  ('demo057', 'Efectivo', 'efectivo', 'Alimentación', 'Restaurante', true, 55000.00, 'gasto', 'efectivo', '2026-05-01', 'Compra', ''),
  ('demo057', 'Bancolombia', 'ahorros', 'Transporte', 'Transporte público', false, 5000.00, 'gasto', 'cuenta', '2026-05-10', 'Pago', ''),
  ('demo057', 'BBVA', 'ahorros', 'Educación', 'Cursos', true, 180000.00, 'gasto', 'cuenta', '2026-05-13', 'Pago', ''),
  ('demo057', 'BBVA', 'ahorros', 'Salud', 'Medicamentos', false, 78000.00, 'gasto', 'cuenta', '2026-05-13', 'Servicio', ''),
  ('demo057', 'BBVA', 'ahorros', 'Alimentación', 'Supermercado', false, 12000.00, 'gasto', 'cuenta', '2026-05-13', 'Servicio', ''),
  ('demo057', 'BBVA', 'ahorros', 'Ocio', 'Cine', true, 5000.00, 'gasto', 'cuenta', '2026-05-14', 'Compra', ''),
  ('demo057', 'BBVA', 'ahorros', 'Salud', 'Medicamentos', true, 12000.00, 'gasto', 'cuenta', '2026-06-08', 'Compra', ''),
  ('demo057', 'BBVA', 'ahorros', 'Ocio', 'Suscripciones', true, 120000.00, 'gasto', 'cuenta', '2026-06-27', 'Servicio', ''),
  ('demo058', 'BBVA', 'corriente', 'Ingresos', 'Salario', false, 3500000.00, 'ingreso', 'cuenta', '2026-01-19', 'Ingreso extra', ''),
  ('demo058', 'BBVA', 'corriente', 'Ingresos', 'Otros ingresos', true, 2800000.00, 'ingreso', 'cuenta', '2026-01-21', 'Pago cliente', ''),
  ('demo058', 'Banco de Bogotá', 'corriente', 'Ocio', 'Cine', false, 150000.00, 'gasto', 'cuenta', '2026-03-02', 'Compra', ''),
  ('demo058', 'BBVA', 'corriente', 'Alimentación', 'Café', true, 250000.00, 'gasto', 'cuenta', '2026-03-13', 'Compra', ''),
  ('demo058', 'BBVA', 'corriente', 'Salud', 'Consultas', true, 250000.00, 'gasto', 'cuenta', '2026-05-03', 'Servicio', ''),
  ('demo058', 'BBVA', 'corriente', 'Transporte', 'Taxi / apps', false, 78000.00, 'gasto', 'cuenta', '2026-05-10', 'Compra', ''),
  ('demo058', 'BBVA', 'corriente', 'Alimentación', 'Restaurante', false, 78000.00, 'gasto', 'cuenta', '2026-05-11', 'Servicio', '')
) AS v(usuario, banco, tipo_cta, cat, sub, use_cp, monto, tipo, medio_pago, fecha, descripcion, grupo)
JOIN users u ON u.usuario = v.usuario
JOIN accounts a ON a.user_id = u.id AND a.banco = v.banco AND a.tipo = v.tipo_cta
JOIN categories c ON c.nombre = v.cat
JOIN sub_categories s ON s.category_id = c.id AND s.nombre = v.sub
LEFT JOIN LATERAL (
  SELECT id FROM counterparties WHERE user_id = u.id ORDER BY id LIMIT 1
) cp ON v.use_cp;

INSERT INTO transactions (account_id, category_id, sub_category_id, contraparte_id, monto, tipo, medio_pago, fecha, descripcion, activo, grupo_transferencia)
SELECT a.id, c.id, s.id, CASE WHEN v.use_cp THEN cp.id ELSE NULL END, v.monto::numeric, v.tipo, v.medio_pago, v.fecha::date, v.descripcion, true, NULLIF(v.grupo, '')
FROM (VALUES
  ('demo058', 'BBVA', 'corriente', 'Transporte', 'Transporte público', false, 12000.00, 'gasto', 'cuenta', '2026-06-23', 'Compra', ''),
  ('demo059', 'Daviplata', 'digital', 'Ingresos', 'Otros ingresos', false, 800000.00, 'ingreso', 'cuenta', '2026-01-17', 'Pago cliente', ''),
  ('demo059', 'Bancolombia', 'digital', 'Transporte', 'Taxi / apps', true, 5000.00, 'gasto', 'cuenta', '2026-02-27', 'Servicio', ''),
  ('demo059', 'Daviplata', 'digital', 'Vivienda', 'Servicios', false, 250000.00, 'gasto', 'cuenta', '2026-03-10', 'Servicio', ''),
  ('demo059', 'Daviplata', 'digital', 'Vivienda', 'Mantenimiento', false, 250000.00, 'gasto', 'cuenta', '2026-03-17', 'Pago', ''),
  ('demo059', 'Daviplata', 'digital', 'Salud', 'Medicamentos', true, 5000.00, 'gasto', 'cuenta', '2026-04-24', 'Servicio', ''),
  ('demo059', 'Daviplata', 'digital', 'Transporte', 'Combustible', false, 5000.00, 'gasto', 'cuenta', '2026-05-01', 'Consumo', ''),
  ('demo059', 'Daviplata', 'digital', 'Salud', 'Consultas', true, 78000.00, 'gasto', 'cuenta', '2026-05-08', 'Consumo', ''),
  ('demo059', 'Bancolombia', 'digital', 'Ocio', 'Suscripciones', false, 78000.00, 'gasto', 'cuenta', '2026-05-22', 'Servicio', ''),
  ('demo059', 'Nequi', 'corriente', 'Vivienda', 'Arriendo', false, 45000.00, 'gasto', 'cuenta', '2026-06-28', 'Consumo', ''),
  ('demo060', 'BBVA', 'digital', 'Ingresos', 'Salario', true, 1800000.00, 'ingreso', 'cuenta', '2026-01-10', 'Pago cliente', ''),
  ('demo060', 'Bancolombia', 'digital', 'Transporte', 'Taxi / apps', true, 50000.00, 'gasto', 'cuenta', '2026-02-05', 'Servicio', ''),
  ('demo060', 'Efectivo', 'efectivo', 'Ocio', 'Salidas', false, 40000.00, 'gasto', 'efectivo', '2026-02-08', 'Pago', ''),
  ('demo060', 'BBVA', 'digital', 'Alimentación', 'Restaurante', true, 12000.00, 'gasto', 'cuenta', '2026-02-27', 'Compra', ''),
  ('demo060', 'BBVA', 'digital', 'Alimentación', 'Supermercado', true, 250000.00, 'gasto', 'cuenta', '2026-03-23', 'Servicio', ''),
  ('demo060', 'BBVA', 'digital', 'Transporte', 'Transporte público', false, 78000.00, 'gasto', 'cuenta', '2026-04-02', 'Consumo', ''),
  ('demo060', 'Efectivo', 'efectivo', 'Ocio', 'Salidas', false, 25000.00, 'gasto', 'efectivo', '2026-05-01', 'Servicio', ''),
  ('demo060', 'Efectivo', 'efectivo', 'Alimentación', 'Café', true, 80000.00, 'gasto', 'efectivo', '2026-05-03', 'Pago', ''),
  ('demo060', 'BBVA', 'digital', 'Ocio', 'Cine', false, 12000.00, 'gasto', 'cuenta', '2026-05-06', 'Consumo', ''),
  ('demo060', 'BBVA', 'digital', 'Alimentación', 'Café', false, 5000.00, 'gasto', 'cuenta', '2026-05-13', 'Consumo', ''),
  ('demo060', 'BBVA', 'digital', 'Educación', 'Cursos', false, 12000.00, 'gasto', 'cuenta', '2026-05-16', 'Consumo', ''),
  ('demo061', 'Daviplata', 'ahorros', 'Ingresos', 'Salario', false, 3500000.00, 'ingreso', 'cuenta', '2026-01-22', 'Pago cliente', ''),
  ('demo061', 'Davivienda', 'digital', 'Vivienda', 'Servicios', true, 5000.00, 'gasto', 'cuenta', '2026-01-22', 'Pago', ''),
  ('demo061', 'Daviplata', 'ahorros', 'Transporte', 'Combustible', false, 78000.00, 'gasto', 'cuenta', '2026-01-27', 'Servicio', ''),
  ('demo061', 'Daviplata', 'ahorros', 'Transporte', 'Combustible', false, 12000.00, 'gasto', 'cuenta', '2026-01-28', 'Servicio', ''),
  ('demo061', 'Daviplata', 'ahorros', 'Vivienda', 'Arriendo', true, 12000.00, 'gasto', 'cuenta', '2026-02-01', 'Servicio', ''),
  ('demo061', 'Daviplata', 'ahorros', 'Transferencias', 'Entre mis cuentas', false, 300000.00, 'transferencia_salida', 'cuenta', '2026-02-17', 'Retiro a efectivo (salida)', '3e16b093-61de-413b-99b2-de2bc6ffc094'),
  ('demo061', 'Efectivo', 'efectivo', 'Transferencias', 'Entre mis cuentas', false, 300000.00, 'transferencia_entrada', 'cuenta', '2026-02-17', 'Retiro a efectivo (entrada)', '3e16b093-61de-413b-99b2-de2bc6ffc094'),
  ('demo061', 'Efectivo', 'efectivo', 'Ocio', 'Suscripciones', true, 55000.00, 'gasto', 'efectivo', '2026-03-04', 'Consumo', ''),
  ('demo061', 'Efectivo', 'efectivo', 'Transporte', 'Transporte público', false, 55000.00, 'gasto', 'efectivo', '2026-03-25', 'Consumo', ''),
  ('demo061', 'Daviplata', 'ahorros', 'Transporte', 'Taxi / apps', true, 5000.00, 'gasto', 'cuenta', '2026-04-14', 'Consumo', ''),
  ('demo061', 'Davivienda', 'digital', 'Ocio', 'Salidas', false, 25000.00, 'gasto', 'cuenta', '2026-04-14', 'Pago', ''),
  ('demo061', 'Daviplata', 'ahorros', 'Vivienda', 'Servicios', true, 250000.00, 'gasto', 'cuenta', '2026-05-01', 'Compra', ''),
  ('demo061', 'Davivienda', 'digital', 'Alimentación', 'Supermercado', true, 25000.00, 'gasto', 'cuenta', '2026-05-13', 'Servicio', ''),
  ('demo061', 'Daviplata', 'ahorros', 'Alimentación', 'Café', false, 25000.00, 'gasto', 'cuenta', '2026-05-25', 'Consumo', ''),
  ('demo061', 'Davivienda', 'digital', 'Vivienda', 'Arriendo', false, 25000.00, 'gasto', 'cuenta', '2026-06-03', 'Pago', ''),
  ('demo061', 'Efectivo', 'efectivo', 'Educación', 'Cursos', true, 40000.00, 'gasto', 'efectivo', '2026-06-11', 'Servicio', ''),
  ('demo061', 'Efectivo', 'efectivo', 'Alimentación', 'Restaurante', false, 10000.00, 'gasto', 'efectivo', '2026-06-22', 'Pago', ''),
  ('demo062', 'Banco de Bogotá', 'ahorros', 'Ingresos', 'Salario', false, 1200000.00, 'ingreso', 'cuenta', '2026-01-13', 'Pago cliente', ''),
  ('demo062', 'Banco de Bogotá', 'ahorros', 'Educación', 'Cursos', false, 45000.00, 'gasto', 'cuenta', '2026-02-01', 'Consumo', '')
) AS v(usuario, banco, tipo_cta, cat, sub, use_cp, monto, tipo, medio_pago, fecha, descripcion, grupo)
JOIN users u ON u.usuario = v.usuario
JOIN accounts a ON a.user_id = u.id AND a.banco = v.banco AND a.tipo = v.tipo_cta
JOIN categories c ON c.nombre = v.cat
JOIN sub_categories s ON s.category_id = c.id AND s.nombre = v.sub
LEFT JOIN LATERAL (
  SELECT id FROM counterparties WHERE user_id = u.id ORDER BY id LIMIT 1
) cp ON v.use_cp;

INSERT INTO transactions (account_id, category_id, sub_category_id, contraparte_id, monto, tipo, medio_pago, fecha, descripcion, activo, grupo_transferencia)
SELECT a.id, c.id, s.id, CASE WHEN v.use_cp THEN cp.id ELSE NULL END, v.monto::numeric, v.tipo, v.medio_pago, v.fecha::date, v.descripcion, true, NULLIF(v.grupo, '')
FROM (VALUES
  ('demo062', 'Banco de Bogotá', 'ahorros', 'Transferencias', 'Entre mis cuentas', false, 300000.00, 'transferencia_salida', 'cuenta', '2026-02-14', 'Retiro a efectivo (salida)', 'ce8c10e6-c8c8-43a9-be28-e87040367249'),
  ('demo062', 'Efectivo', 'efectivo', 'Transferencias', 'Entre mis cuentas', false, 300000.00, 'transferencia_entrada', 'cuenta', '2026-02-14', 'Retiro a efectivo (entrada)', 'ce8c10e6-c8c8-43a9-be28-e87040367249'),
  ('demo062', 'Efectivo', 'efectivo', 'Salud', 'Consultas', false, 55000.00, 'gasto', 'efectivo', '2026-02-21', 'Pago', ''),
  ('demo062', 'Nequi', 'ahorros', 'Transporte', 'Combustible', false, 45000.00, 'gasto', 'cuenta', '2026-03-13', 'Pago', ''),
  ('demo062', 'Banco de Bogotá', 'ahorros', 'Vivienda', 'Servicios', false, 180000.00, 'gasto', 'cuenta', '2026-04-01', 'Compra', ''),
  ('demo062', 'Nequi', 'ahorros', 'Ocio', 'Salidas', true, 5000.00, 'gasto', 'cuenta', '2026-04-22', 'Pago', ''),
  ('demo062', 'Nequi', 'ahorros', 'Ocio', 'Suscripciones', true, 25000.00, 'gasto', 'cuenta', '2026-05-10', 'Consumo', ''),
  ('demo062', 'Banco de Bogotá', 'ahorros', 'Vivienda', 'Mantenimiento', true, 120000.00, 'gasto', 'cuenta', '2026-07-03', 'Pago', ''),
  ('demo063', 'BBVA', 'ahorros', 'Ingresos', 'Otros ingresos', true, 2200000.00, 'ingreso', 'cuenta', '2026-01-05', 'Ingreso extra', ''),
  ('demo063', 'Daviplata', 'ahorros', 'Transporte', 'Combustible', false, 150000.00, 'gasto', 'cuenta', '2026-01-14', 'Servicio', ''),
  ('demo063', 'BBVA', 'ahorros', 'Ingresos', 'Salario', false, 2800000.00, 'ingreso', 'cuenta', '2026-01-19', 'Ingreso extra', ''),
  ('demo063', 'BBVA', 'ahorros', 'Transferencias', 'Entre mis cuentas', false, 100000.00, 'transferencia_salida', 'cuenta', '2026-02-10', 'Transferencia entre cuentas (salida)', '8c590942-7d31-441b-813e-2f8526898ee6'),
  ('demo063', 'Daviplata', 'ahorros', 'Transferencias', 'Entre mis cuentas', false, 100000.00, 'transferencia_entrada', 'cuenta', '2026-02-10', 'Transferencia entre cuentas (entrada)', '8c590942-7d31-441b-813e-2f8526898ee6'),
  ('demo063', 'Daviplata', 'ahorros', 'Alimentación', 'Café', false, 45000.00, 'gasto', 'cuenta', '2026-02-20', 'Compra', ''),
  ('demo063', 'Daviplata', 'ahorros', 'Educación', 'Cursos', false, 25000.00, 'gasto', 'cuenta', '2026-03-10', 'Compra', ''),
  ('demo063', 'Daviplata', 'ahorros', 'Ocio', 'Suscripciones', false, 25000.00, 'gasto', 'cuenta', '2026-03-17', 'Pago', ''),
  ('demo063', 'Daviplata', 'ahorros', 'Alimentación', 'Supermercado', true, 5000.00, 'gasto', 'cuenta', '2026-04-06', 'Compra', ''),
  ('demo063', 'BBVA', 'ahorros', 'Alimentación', 'Restaurante', false, 120000.00, 'gasto', 'cuenta', '2026-06-13', 'Consumo', ''),
  ('demo064', 'Nequi', 'ahorros', 'Ingresos', 'Salario', false, 1200000.00, 'ingreso', 'cuenta', '2026-01-14', 'Ingreso extra', ''),
  ('demo064', 'Davivienda', 'digital', 'Transferencias', 'Entre mis cuentas', false, 50000.00, 'transferencia_salida', 'cuenta', '2026-01-15', 'Retiro a efectivo (salida)', '03be3fd2-bc3e-4cdf-bf5d-ffc9ac7bfc77'),
  ('demo064', 'Efectivo', 'efectivo', 'Transferencias', 'Entre mis cuentas', false, 50000.00, 'transferencia_entrada', 'cuenta', '2026-01-15', 'Retiro a efectivo (entrada)', '03be3fd2-bc3e-4cdf-bf5d-ffc9ac7bfc77'),
  ('demo064', 'Nequi', 'ahorros', 'Ingresos', 'Otros ingresos', false, 2200000.00, 'ingreso', 'cuenta', '2026-01-17', 'Ingreso extra', ''),
  ('demo064', 'Nequi', 'ahorros', 'Ocio', 'Salidas', false, 120000.00, 'gasto', 'cuenta', '2026-01-30', 'Servicio', ''),
  ('demo064', 'Davivienda', 'digital', 'Vivienda', 'Arriendo', true, 78000.00, 'gasto', 'cuenta', '2026-02-03', 'Compra', ''),
  ('demo064', 'Davivienda', 'digital', 'Ocio', 'Salidas', false, 120000.00, 'gasto', 'cuenta', '2026-02-05', 'Consumo', ''),
  ('demo064', 'Nequi', 'ahorros', 'Educación', 'Cursos', true, 250000.00, 'gasto', 'cuenta', '2026-02-28', 'Servicio', ''),
  ('demo064', 'Davivienda', 'digital', 'Transporte', 'Taxi / apps', true, 78000.00, 'gasto', 'cuenta', '2026-03-03', 'Consumo', ''),
  ('demo064', 'Efectivo', 'efectivo', 'Salud', 'Medicamentos', true, 15000.00, 'gasto', 'efectivo', '2026-03-04', 'Compra', ''),
  ('demo064', 'Nequi', 'ahorros', 'Transferencias', 'Entre mis cuentas', false, 80000.00, 'transferencia_salida', 'cuenta', '2026-03-09', 'Transferencia entre cuentas (salida)', '507176a4-5a3e-44ff-93be-9b513af6318e'),
  ('demo064', 'Bancolombia', 'ahorros', 'Transferencias', 'Entre mis cuentas', false, 80000.00, 'transferencia_entrada', 'cuenta', '2026-03-09', 'Transferencia entre cuentas (entrada)', '507176a4-5a3e-44ff-93be-9b513af6318e'),
  ('demo064', 'Bancolombia', 'ahorros', 'Salud', 'Medicamentos', false, 25000.00, 'gasto', 'cuenta', '2026-03-29', 'Pago', ''),
  ('demo064', 'Bancolombia', 'ahorros', 'Transporte', 'Taxi / apps', true, 25000.00, 'gasto', 'cuenta', '2026-04-18', 'Pago', ''),
  ('demo064', 'Nequi', 'ahorros', 'Educación', 'Cursos', true, 25000.00, 'gasto', 'cuenta', '2026-04-24', 'Consumo', ''),
  ('demo064', 'Davivienda', 'digital', 'Salud', 'Consultas', true, 5000.00, 'gasto', 'cuenta', '2026-05-09', 'Consumo', ''),
  ('demo064', 'Nequi', 'ahorros', 'Salud', 'Medicamentos', false, 25000.00, 'gasto', 'cuenta', '2026-05-11', 'Compra', ''),
  ('demo064', 'Nequi', 'ahorros', 'Transporte', 'Transporte público', false, 250000.00, 'gasto', 'cuenta', '2026-05-30', 'Servicio', ''),
  ('demo064', 'Davivienda', 'digital', 'Salud', 'Consultas', false, 5000.00, 'gasto', 'cuenta', '2026-05-30', 'Consumo', ''),
  ('demo064', 'Nequi', 'ahorros', 'Educación', 'Cursos', false, 25000.00, 'gasto', 'cuenta', '2026-06-21', 'Consumo', ''),
  ('demo065', 'Bancolombia', 'corriente', 'Ingresos', 'Otros ingresos', true, 2200000.00, 'ingreso', 'cuenta', '2026-01-08', 'Nomina', ''),
  ('demo065', 'Efectivo', 'efectivo', 'Ocio', 'Salidas', true, 25000.00, 'gasto', 'efectivo', '2026-01-25', 'Servicio', '')
) AS v(usuario, banco, tipo_cta, cat, sub, use_cp, monto, tipo, medio_pago, fecha, descripcion, grupo)
JOIN users u ON u.usuario = v.usuario
JOIN accounts a ON a.user_id = u.id AND a.banco = v.banco AND a.tipo = v.tipo_cta
JOIN categories c ON c.nombre = v.cat
JOIN sub_categories s ON s.category_id = c.id AND s.nombre = v.sub
LEFT JOIN LATERAL (
  SELECT id FROM counterparties WHERE user_id = u.id ORDER BY id LIMIT 1
) cp ON v.use_cp;

INSERT INTO transactions (account_id, category_id, sub_category_id, contraparte_id, monto, tipo, medio_pago, fecha, descripcion, activo, grupo_transferencia)
SELECT a.id, c.id, s.id, CASE WHEN v.use_cp THEN cp.id ELSE NULL END, v.monto::numeric, v.tipo, v.medio_pago, v.fecha::date, v.descripcion, true, NULLIF(v.grupo, '')
FROM (VALUES
  ('demo065', 'Bancolombia', 'corriente', 'Transporte', 'Transporte público', true, 180000.00, 'gasto', 'cuenta', '2026-01-29', 'Compra', ''),
  ('demo065', 'Bancolombia', 'corriente', 'Salud', 'Consultas', false, 250000.00, 'gasto', 'cuenta', '2026-02-06', 'Compra', ''),
  ('demo065', 'Bancolombia', 'corriente', 'Alimentación', 'Supermercado', false, 12000.00, 'gasto', 'cuenta', '2026-02-21', 'Servicio', ''),
  ('demo065', 'Bancolombia', 'corriente', 'Transporte', 'Taxi / apps', false, 180000.00, 'gasto', 'cuenta', '2026-03-05', 'Servicio', ''),
  ('demo065', 'Davivienda', 'digital', 'Transporte', 'Taxi / apps', true, 45000.00, 'gasto', 'cuenta', '2026-04-06', 'Servicio', ''),
  ('demo065', 'Bancolombia', 'corriente', 'Salud', 'Medicamentos', false, 5000.00, 'gasto', 'cuenta', '2026-04-17', 'Consumo', ''),
  ('demo065', 'Bancolombia', 'corriente', 'Alimentación', 'Supermercado', true, 45000.00, 'gasto', 'cuenta', '2026-04-25', 'Compra', ''),
  ('demo065', 'Bancolombia', 'corriente', 'Transporte', 'Combustible', false, 250000.00, 'gasto', 'cuenta', '2026-04-26', 'Consumo', ''),
  ('demo065', 'Efectivo', 'efectivo', 'Vivienda', 'Servicios', true, 25000.00, 'gasto', 'efectivo', '2026-04-26', 'Compra', ''),
  ('demo065', 'Efectivo', 'efectivo', 'Educación', 'Libros', false, 15000.00, 'gasto', 'efectivo', '2026-04-27', 'Compra', ''),
  ('demo065', 'Efectivo', 'efectivo', 'Educación', 'Libros', false, 15000.00, 'gasto', 'efectivo', '2026-04-30', 'Servicio', ''),
  ('demo065', 'Bancolombia', 'corriente', 'Transferencias', 'Entre mis cuentas', false, 100000.00, 'transferencia_salida', 'cuenta', '2026-05-01', 'Transferencia entre cuentas (salida)', '464c2b5d-f2e4-4fcd-b6c6-44d54563f5ad'),
  ('demo065', 'Davivienda', 'digital', 'Transferencias', 'Entre mis cuentas', false, 100000.00, 'transferencia_entrada', 'cuenta', '2026-05-01', 'Transferencia entre cuentas (entrada)', '464c2b5d-f2e4-4fcd-b6c6-44d54563f5ad'),
  ('demo065', 'Davivienda', 'digital', 'Transporte', 'Taxi / apps', true, 78000.00, 'gasto', 'cuenta', '2026-05-20', 'Compra', ''),
  ('demo065', 'Bancolombia', 'corriente', 'Ocio', 'Cine', true, 25000.00, 'gasto', 'cuenta', '2026-05-25', 'Pago', ''),
  ('demo065', 'Bancolombia', 'corriente', 'Ocio', 'Cine', true, 180000.00, 'gasto', 'cuenta', '2026-05-26', 'Compra', ''),
  ('demo065', 'Davivienda', 'digital', 'Transporte', 'Taxi / apps', false, 45000.00, 'gasto', 'cuenta', '2026-06-18', 'Compra', ''),
  ('demo065', 'Davivienda', 'digital', 'Salud', 'Consultas', true, 120000.00, 'gasto', 'cuenta', '2026-06-18', 'Consumo', ''),
  ('demo066', 'Daviplata', 'corriente', 'Ingresos', 'Freelance', false, 2800000.00, 'ingreso', 'cuenta', '2026-01-09', 'Nomina', ''),
  ('demo066', 'Nequi', 'corriente', 'Ingresos', 'Salario', true, 3500000.00, 'ingreso', 'cuenta', '2026-01-12', 'Nomina', ''),
  ('demo066', 'Daviplata', 'corriente', 'Vivienda', 'Servicios', true, 25000.00, 'gasto', 'cuenta', '2026-02-20', 'Consumo', ''),
  ('demo066', 'Nequi', 'corriente', 'Ocio', 'Salidas', true, 12000.00, 'gasto', 'cuenta', '2026-04-05', 'Compra', ''),
  ('demo066', 'Bancolombia', 'corriente', 'Alimentación', 'Restaurante', true, 150000.00, 'gasto', 'cuenta', '2026-04-15', 'Pago', ''),
  ('demo066', 'Daviplata', 'corriente', 'Educación', 'Libros', false, 5000.00, 'gasto', 'cuenta', '2026-04-18', 'Compra', ''),
  ('demo066', 'Nequi', 'corriente', 'Salud', 'Medicamentos', false, 12000.00, 'gasto', 'cuenta', '2026-05-09', 'Compra', ''),
  ('demo066', 'Nequi', 'corriente', 'Vivienda', 'Arriendo', false, 45000.00, 'gasto', 'cuenta', '2026-05-18', 'Pago', ''),
  ('demo067', 'Nequi', 'ahorros', 'Ingresos', 'Freelance', false, 1800000.00, 'ingreso', 'cuenta', '2026-01-11', 'Ingreso extra', ''),
  ('demo067', 'Efectivo', 'efectivo', 'Educación', 'Cursos', false, 55000.00, 'gasto', 'efectivo', '2026-02-03', 'Pago', ''),
  ('demo067', 'Davivienda', 'digital', 'Transferencias', 'Entre mis cuentas', false, 100000.00, 'transferencia_salida', 'cuenta', '2026-02-06', 'Retiro a efectivo (salida)', 'e67df437-615a-4078-9c68-5404448d394b'),
  ('demo067', 'Efectivo', 'efectivo', 'Transferencias', 'Entre mis cuentas', false, 100000.00, 'transferencia_entrada', 'cuenta', '2026-02-06', 'Retiro a efectivo (entrada)', 'e67df437-615a-4078-9c68-5404448d394b'),
  ('demo067', 'Nequi', 'ahorros', 'Alimentación', 'Café', false, 45000.00, 'gasto', 'cuenta', '2026-02-14', 'Servicio', ''),
  ('demo067', 'Nequi', 'ahorros', 'Alimentación', 'Supermercado', false, 25000.00, 'gasto', 'cuenta', '2026-02-14', 'Servicio', ''),
  ('demo067', 'Efectivo', 'efectivo', 'Educación', 'Cursos', true, 25000.00, 'gasto', 'efectivo', '2026-02-14', 'Compra', ''),
  ('demo067', 'Nequi', 'ahorros', 'Transporte', 'Combustible', true, 180000.00, 'gasto', 'cuenta', '2026-02-17', 'Pago', ''),
  ('demo067', 'Davivienda', 'digital', 'Vivienda', 'Arriendo', true, 120000.00, 'gasto', 'cuenta', '2026-02-20', 'Servicio', ''),
  ('demo067', 'Nequi', 'ahorros', 'Transferencias', 'Entre mis cuentas', false, 150000.00, 'transferencia_salida', 'cuenta', '2026-03-04', 'Transferencia entre cuentas (salida)', 'e999b01f-8f24-473d-81f4-ade76b1fd83a'),
  ('demo067', 'Efectivo', 'efectivo', 'Transferencias', 'Entre mis cuentas', false, 150000.00, 'transferencia_entrada', 'cuenta', '2026-03-04', 'Transferencia entre cuentas (entrada)', 'e999b01f-8f24-473d-81f4-ade76b1fd83a'),
  ('demo067', 'Nequi', 'ahorros', 'Ocio', 'Suscripciones', false, 78000.00, 'gasto', 'cuenta', '2026-03-12', 'Consumo', ''),
  ('demo067', 'Banco de Bogotá', 'ahorros', 'Educación', 'Libros', true, 180000.00, 'gasto', 'cuenta', '2026-03-16', 'Consumo', ''),
  ('demo067', 'Nequi', 'ahorros', 'Transporte', 'Combustible', false, 12000.00, 'gasto', 'cuenta', '2026-04-07', 'Consumo', '')
) AS v(usuario, banco, tipo_cta, cat, sub, use_cp, monto, tipo, medio_pago, fecha, descripcion, grupo)
JOIN users u ON u.usuario = v.usuario
JOIN accounts a ON a.user_id = u.id AND a.banco = v.banco AND a.tipo = v.tipo_cta
JOIN categories c ON c.nombre = v.cat
JOIN sub_categories s ON s.category_id = c.id AND s.nombre = v.sub
LEFT JOIN LATERAL (
  SELECT id FROM counterparties WHERE user_id = u.id ORDER BY id LIMIT 1
) cp ON v.use_cp;

INSERT INTO transactions (account_id, category_id, sub_category_id, contraparte_id, monto, tipo, medio_pago, fecha, descripcion, activo, grupo_transferencia)
SELECT a.id, c.id, s.id, CASE WHEN v.use_cp THEN cp.id ELSE NULL END, v.monto::numeric, v.tipo, v.medio_pago, v.fecha::date, v.descripcion, true, NULLIF(v.grupo, '')
FROM (VALUES
  ('demo067', 'Davivienda', 'digital', 'Alimentación', 'Supermercado', false, 25000.00, 'gasto', 'cuenta', '2026-05-01', 'Compra', ''),
  ('demo067', 'Davivienda', 'digital', 'Alimentación', 'Supermercado', true, 105000.00, 'gasto', 'cuenta', '2026-05-05', 'Pago', ''),
  ('demo067', 'Banco de Bogotá', 'ahorros', 'Transporte', 'Transporte público', false, 120000.00, 'gasto', 'cuenta', '2026-05-16', 'Consumo', ''),
  ('demo067', 'Banco de Bogotá', 'ahorros', 'Educación', 'Cursos', true, 50000.00, 'gasto', 'cuenta', '2026-05-30', 'Pago', ''),
  ('demo067', 'Efectivo', 'efectivo', 'Educación', 'Libros', false, 25000.00, 'gasto', 'efectivo', '2026-06-15', 'Consumo', ''),
  ('demo068', 'Banco de Bogotá', 'ahorros', 'Ingresos', 'Salario', false, 1200000.00, 'ingreso', 'cuenta', '2026-01-14', 'Nomina', ''),
  ('demo068', 'Banco de Bogotá', 'ahorros', 'Ingresos', 'Otros ingresos', false, 800000.00, 'ingreso', 'cuenta', '2026-01-20', 'Nomina', ''),
  ('demo068', 'Bancolombia', 'corriente', 'Transporte', 'Taxi / apps', false, 120000.00, 'gasto', 'cuenta', '2026-01-25', 'Compra', ''),
  ('demo068', 'Bancolombia', 'corriente', 'Ocio', 'Salidas', true, 30000.00, 'gasto', 'cuenta', '2026-01-29', 'Servicio', ''),
  ('demo068', 'Banco de Bogotá', 'ahorros', 'Alimentación', 'Supermercado', true, 250000.00, 'gasto', 'cuenta', '2026-02-02', 'Consumo', ''),
  ('demo068', 'Efectivo', 'efectivo', 'Transporte', 'Combustible', true, 15000.00, 'gasto', 'efectivo', '2026-02-18', 'Servicio', ''),
  ('demo068', 'Banco de Bogotá', 'ahorros', 'Transferencias', 'Entre mis cuentas', false, 100000.00, 'transferencia_salida', 'cuenta', '2026-02-18', 'Transferencia entre cuentas (salida)', '67e2053e-dd0c-4d2e-a9df-d6d27f25110e'),
  ('demo068', 'Bancolombia', 'corriente', 'Transferencias', 'Entre mis cuentas', false, 100000.00, 'transferencia_entrada', 'cuenta', '2026-02-18', 'Transferencia entre cuentas (entrada)', '67e2053e-dd0c-4d2e-a9df-d6d27f25110e'),
  ('demo068', 'BBVA', 'corriente', 'Transporte', 'Taxi / apps', true, 120000.00, 'gasto', 'cuenta', '2026-02-19', 'Consumo', ''),
  ('demo068', 'BBVA', 'corriente', 'Educación', 'Libros', false, 45000.00, 'gasto', 'cuenta', '2026-03-31', 'Compra', ''),
  ('demo068', 'Banco de Bogotá', 'ahorros', 'Salud', 'Medicamentos', true, 45000.00, 'gasto', 'cuenta', '2026-04-10', 'Consumo', ''),
  ('demo068', 'Banco de Bogotá', 'ahorros', 'Vivienda', 'Servicios', false, 180000.00, 'gasto', 'cuenta', '2026-04-17', 'Compra', ''),
  ('demo068', 'Banco de Bogotá', 'ahorros', 'Salud', 'Consultas', true, 12000.00, 'gasto', 'cuenta', '2026-04-18', 'Consumo', ''),
  ('demo068', 'Banco de Bogotá', 'ahorros', 'Ocio', 'Salidas', true, 250000.00, 'gasto', 'cuenta', '2026-04-21', 'Pago', ''),
  ('demo068', 'Efectivo', 'efectivo', 'Salud', 'Medicamentos', false, 5000.00, 'gasto', 'efectivo', '2026-04-23', 'Consumo', ''),
  ('demo068', 'Efectivo', 'efectivo', 'Salud', 'Consultas', false, 40000.00, 'gasto', 'efectivo', '2026-04-26', 'Pago', ''),
  ('demo068', 'Efectivo', 'efectivo', 'Educación', 'Cursos', false, 15000.00, 'gasto', 'efectivo', '2026-05-14', 'Pago', ''),
  ('demo068', 'Banco de Bogotá', 'ahorros', 'Educación', 'Libros', false, 25000.00, 'gasto', 'cuenta', '2026-06-16', 'Pago', ''),
  ('demo068', 'Banco de Bogotá', 'ahorros', 'Vivienda', 'Mantenimiento', false, 250000.00, 'gasto', 'cuenta', '2026-06-18', 'Servicio', ''),
  ('demo068', 'Banco de Bogotá', 'ahorros', 'Vivienda', 'Arriendo', false, 5000.00, 'gasto', 'cuenta', '2026-06-24', 'Consumo', ''),
  ('demo069', 'Davivienda', 'corriente', 'Ingresos', 'Salario', false, 800000.00, 'ingreso', 'cuenta', '2026-01-19', 'Nomina', ''),
  ('demo069', 'Davivienda', 'corriente', 'Ingresos', 'Freelance', false, 800000.00, 'ingreso', 'cuenta', '2026-01-20', 'Pago cliente', ''),
  ('demo069', 'BBVA', 'corriente', 'Transporte', 'Transporte público', true, 100000.00, 'gasto', 'cuenta', '2026-01-26', 'Pago', ''),
  ('demo069', 'Efectivo', 'efectivo', 'Transporte', 'Combustible', false, 55000.00, 'gasto', 'efectivo', '2026-02-05', 'Consumo', ''),
  ('demo069', 'Bancolombia', 'corriente', 'Salud', 'Consultas', false, 12000.00, 'gasto', 'cuenta', '2026-02-28', 'Consumo', ''),
  ('demo069', 'Bancolombia', 'corriente', 'Vivienda', 'Servicios', true, 88000.00, 'gasto', 'cuenta', '2026-03-11', 'Servicio', ''),
  ('demo069', 'Efectivo', 'efectivo', 'Transporte', 'Taxi / apps', false, 5000.00, 'gasto', 'efectivo', '2026-03-12', 'Pago', ''),
  ('demo069', 'Davivienda', 'corriente', 'Vivienda', 'Mantenimiento', false, 180000.00, 'gasto', 'cuenta', '2026-03-26', 'Compra', ''),
  ('demo069', 'Davivienda', 'corriente', 'Salud', 'Consultas', false, 12000.00, 'gasto', 'cuenta', '2026-03-29', 'Servicio', ''),
  ('demo069', 'Efectivo', 'efectivo', 'Vivienda', 'Mantenimiento', false, 10000.00, 'gasto', 'efectivo', '2026-06-15', 'Pago', ''),
  ('demo070', 'Daviplata', 'corriente', 'Ingresos', 'Otros ingresos', false, 1200000.00, 'ingreso', 'cuenta', '2026-01-17', 'Pago cliente', ''),
  ('demo070', 'Bancolombia', 'corriente', 'Salud', 'Consultas', false, 180000.00, 'gasto', 'cuenta', '2026-01-21', 'Servicio', ''),
  ('demo070', 'Daviplata', 'corriente', 'Educación', 'Cursos', true, 25000.00, 'gasto', 'cuenta', '2026-02-02', 'Pago', ''),
  ('demo070', 'Daviplata', 'corriente', 'Ingresos', 'Freelance', false, 3500000.00, 'ingreso', 'cuenta', '2026-03-12', 'Pago cliente', ''),
  ('demo070', 'Daviplata', 'corriente', 'Vivienda', 'Servicios', false, 25000.00, 'gasto', 'cuenta', '2026-03-24', 'Pago', '')
) AS v(usuario, banco, tipo_cta, cat, sub, use_cp, monto, tipo, medio_pago, fecha, descripcion, grupo)
JOIN users u ON u.usuario = v.usuario
JOIN accounts a ON a.user_id = u.id AND a.banco = v.banco AND a.tipo = v.tipo_cta
JOIN categories c ON c.nombre = v.cat
JOIN sub_categories s ON s.category_id = c.id AND s.nombre = v.sub
LEFT JOIN LATERAL (
  SELECT id FROM counterparties WHERE user_id = u.id ORDER BY id LIMIT 1
) cp ON v.use_cp;

INSERT INTO transactions (account_id, category_id, sub_category_id, contraparte_id, monto, tipo, medio_pago, fecha, descripcion, activo, grupo_transferencia)
SELECT a.id, c.id, s.id, CASE WHEN v.use_cp THEN cp.id ELSE NULL END, v.monto::numeric, v.tipo, v.medio_pago, v.fecha::date, v.descripcion, true, NULLIF(v.grupo, '')
FROM (VALUES
  ('demo070', 'Bancolombia', 'corriente', 'Educación', 'Cursos', false, 120000.00, 'gasto', 'cuenta', '2026-04-04', 'Servicio', ''),
  ('demo070', 'Efectivo', 'efectivo', 'Vivienda', 'Mantenimiento', false, 10000.00, 'gasto', 'efectivo', '2026-04-15', 'Pago', ''),
  ('demo070', 'Bancolombia', 'corriente', 'Vivienda', 'Arriendo', false, 50000.00, 'gasto', 'cuenta', '2026-04-27', 'Compra', ''),
  ('demo070', 'Daviplata', 'corriente', 'Ocio', 'Suscripciones', true, 180000.00, 'gasto', 'cuenta', '2026-05-05', 'Pago', ''),
  ('demo070', 'Efectivo', 'efectivo', 'Vivienda', 'Servicios', false, 5000.00, 'gasto', 'efectivo', '2026-05-05', 'Compra', ''),
  ('demo070', 'Efectivo', 'efectivo', 'Vivienda', 'Mantenimiento', true, 10000.00, 'gasto', 'efectivo', '2026-05-08', 'Pago', ''),
  ('demo070', 'Efectivo', 'efectivo', 'Ocio', 'Salidas', true, 40000.00, 'gasto', 'efectivo', '2026-05-20', 'Consumo', ''),
  ('demo070', 'Daviplata', 'corriente', 'Ocio', 'Salidas', false, 5000.00, 'gasto', 'cuenta', '2026-06-26', 'Servicio', ''),
  ('demo071', 'BBVA', 'digital', 'Ingresos', 'Salario', false, 3500000.00, 'ingreso', 'cuenta', '2026-01-10', 'Ingreso extra', ''),
  ('demo071', 'BBVA', 'digital', 'Ingresos', 'Otros ingresos', true, 3500000.00, 'ingreso', 'cuenta', '2026-01-12', 'Pago cliente', ''),
  ('demo071', 'Banco de Bogotá', 'corriente', 'Alimentación', 'Restaurante', false, 5000.00, 'gasto', 'cuenta', '2026-01-16', 'Consumo', ''),
  ('demo071', 'BBVA', 'digital', 'Alimentación', 'Restaurante', true, 120000.00, 'gasto', 'cuenta', '2026-02-04', 'Compra', ''),
  ('demo071', 'Banco de Bogotá', 'corriente', 'Salud', 'Medicamentos', false, 95000.00, 'gasto', 'cuenta', '2026-02-17', 'Servicio', ''),
  ('demo071', 'Davivienda', 'corriente', 'Transporte', 'Taxi / apps', true, 5000.00, 'gasto', 'cuenta', '2026-04-06', 'Consumo', ''),
  ('demo071', 'BBVA', 'digital', 'Educación', 'Cursos', true, 120000.00, 'gasto', 'cuenta', '2026-04-18', 'Pago', ''),
  ('demo071', 'Davivienda', 'corriente', 'Transporte', 'Combustible', true, 78000.00, 'gasto', 'cuenta', '2026-05-14', 'Consumo', ''),
  ('demo071', 'Davivienda', 'corriente', 'Vivienda', 'Mantenimiento', false, 17000.00, 'gasto', 'cuenta', '2026-06-12', 'Consumo', ''),
  ('demo071', 'BBVA', 'digital', 'Vivienda', 'Mantenimiento', false, 78000.00, 'gasto', 'cuenta', '2026-06-28', 'Consumo', ''),
  ('demo072', 'Nequi', 'ahorros', 'Ingresos', 'Salario', false, 800000.00, 'ingreso', 'cuenta', '2026-01-11', 'Pago cliente', ''),
  ('demo072', 'Nequi', 'ahorros', 'Ingresos', 'Freelance', false, 800000.00, 'ingreso', 'cuenta', '2026-01-14', 'Ingreso extra', ''),
  ('demo072', 'Efectivo', 'efectivo', 'Ocio', 'Suscripciones', false, 5000.00, 'gasto', 'efectivo', '2026-01-23', 'Consumo', ''),
  ('demo072', 'Bancolombia', 'ahorros', 'Transporte', 'Transporte público', true, 50000.00, 'gasto', 'cuenta', '2026-02-07', 'Compra', ''),
  ('demo072', 'Banco de Bogotá', 'corriente', 'Educación', 'Cursos', false, 200000.00, 'gasto', 'cuenta', '2026-02-15', 'Consumo', ''),
  ('demo072', 'Nequi', 'ahorros', 'Vivienda', 'Arriendo', false, 25000.00, 'gasto', 'cuenta', '2026-03-08', 'Compra', ''),
  ('demo072', 'Nequi', 'ahorros', 'Transferencias', 'Entre mis cuentas', false, 50000.00, 'transferencia_salida', 'cuenta', '2026-03-19', 'Transferencia entre cuentas (salida)', 'ead43d08-3e9a-4ce4-b528-bdfb1c3ffd67'),
  ('demo072', 'Banco de Bogotá', 'corriente', 'Transferencias', 'Entre mis cuentas', false, 50000.00, 'transferencia_entrada', 'cuenta', '2026-03-19', 'Transferencia entre cuentas (entrada)', 'ead43d08-3e9a-4ce4-b528-bdfb1c3ffd67'),
  ('demo072', 'Banco de Bogotá', 'corriente', 'Ocio', 'Suscripciones', true, 12000.00, 'gasto', 'cuenta', '2026-03-28', 'Compra', ''),
  ('demo072', 'Nequi', 'ahorros', 'Alimentación', 'Supermercado', true, 12000.00, 'gasto', 'cuenta', '2026-05-25', 'Pago', ''),
  ('demo072', 'Efectivo', 'efectivo', 'Ocio', 'Suscripciones', false, 80000.00, 'gasto', 'efectivo', '2026-06-20', 'Consumo', ''),
  ('demo073', 'Nequi', 'ahorros', 'Ingresos', 'Freelance', true, 2200000.00, 'ingreso', 'cuenta', '2026-01-17', 'Ingreso extra', ''),
  ('demo073', 'Daviplata', 'digital', 'Ingresos', 'Otros ingresos', false, 800000.00, 'ingreso', 'cuenta', '2026-01-18', 'Nomina', ''),
  ('demo073', 'Daviplata', 'digital', 'Transferencias', 'Entre mis cuentas', false, 150000.00, 'transferencia_salida', 'cuenta', '2026-01-18', 'Retiro a efectivo (salida)', '79f7ed1a-85ad-47cb-928c-6db01f5a456b'),
  ('demo073', 'Efectivo', 'efectivo', 'Transferencias', 'Entre mis cuentas', false, 150000.00, 'transferencia_entrada', 'cuenta', '2026-01-18', 'Retiro a efectivo (entrada)', '79f7ed1a-85ad-47cb-928c-6db01f5a456b'),
  ('demo073', 'Daviplata', 'digital', 'Vivienda', 'Mantenimiento', true, 250000.00, 'gasto', 'cuenta', '2026-02-06', 'Consumo', ''),
  ('demo073', 'Daviplata', 'digital', 'Transporte', 'Combustible', true, 5000.00, 'gasto', 'cuenta', '2026-02-24', 'Servicio', ''),
  ('demo073', 'Efectivo', 'efectivo', 'Ocio', 'Suscripciones', true, 10000.00, 'gasto', 'efectivo', '2026-02-24', 'Compra', ''),
  ('demo073', 'Efectivo', 'efectivo', 'Salud', 'Medicamentos', false, 55000.00, 'gasto', 'efectivo', '2026-03-02', 'Consumo', ''),
  ('demo073', 'Banco de Bogotá', 'corriente', 'Vivienda', 'Mantenimiento', false, 50000.00, 'gasto', 'cuenta', '2026-03-14', 'Consumo', ''),
  ('demo073', 'Daviplata', 'digital', 'Transporte', 'Taxi / apps', false, 45000.00, 'gasto', 'cuenta', '2026-03-31', 'Compra', ''),
  ('demo073', 'Efectivo', 'efectivo', 'Vivienda', 'Mantenimiento', false, 40000.00, 'gasto', 'efectivo', '2026-04-09', 'Compra', '')
) AS v(usuario, banco, tipo_cta, cat, sub, use_cp, monto, tipo, medio_pago, fecha, descripcion, grupo)
JOIN users u ON u.usuario = v.usuario
JOIN accounts a ON a.user_id = u.id AND a.banco = v.banco AND a.tipo = v.tipo_cta
JOIN categories c ON c.nombre = v.cat
JOIN sub_categories s ON s.category_id = c.id AND s.nombre = v.sub
LEFT JOIN LATERAL (
  SELECT id FROM counterparties WHERE user_id = u.id ORDER BY id LIMIT 1
) cp ON v.use_cp;

INSERT INTO transactions (account_id, category_id, sub_category_id, contraparte_id, monto, tipo, medio_pago, fecha, descripcion, activo, grupo_transferencia)
SELECT a.id, c.id, s.id, CASE WHEN v.use_cp THEN cp.id ELSE NULL END, v.monto::numeric, v.tipo, v.medio_pago, v.fecha::date, v.descripcion, true, NULLIF(v.grupo, '')
FROM (VALUES
  ('demo073', 'Efectivo', 'efectivo', 'Alimentación', 'Supermercado', true, 5000.00, 'gasto', 'efectivo', '2026-04-09', 'Servicio', ''),
  ('demo073', 'Daviplata', 'digital', 'Ingresos', 'Freelance', false, 3500000.00, 'ingreso', 'cuenta', '2026-04-23', 'Pago cliente', ''),
  ('demo073', 'Nequi', 'ahorros', 'Salud', 'Medicamentos', false, 250000.00, 'gasto', 'cuenta', '2026-05-14', 'Consumo', ''),
  ('demo073', 'Nequi', 'ahorros', 'Salud', 'Medicamentos', true, 180000.00, 'gasto', 'cuenta', '2026-05-22', 'Compra', ''),
  ('demo073', 'Daviplata', 'digital', 'Transporte', 'Combustible', false, 45000.00, 'gasto', 'cuenta', '2026-05-30', 'Compra', ''),
  ('demo073', 'Daviplata', 'digital', 'Vivienda', 'Arriendo', false, 5000.00, 'gasto', 'cuenta', '2026-05-30', 'Servicio', ''),
  ('demo073', 'Nequi', 'ahorros', 'Ocio', 'Salidas', true, 45000.00, 'gasto', 'cuenta', '2026-06-26', 'Pago', ''),
  ('demo074', 'Daviplata', 'ahorros', 'Ingresos', 'Freelance', true, 3500000.00, 'ingreso', 'cuenta', '2026-01-17', 'Nomina', ''),
  ('demo074', 'Bancolombia', 'digital', 'Ingresos', 'Freelance', false, 1200000.00, 'ingreso', 'cuenta', '2026-01-21', 'Pago cliente', ''),
  ('demo074', 'Bancolombia', 'digital', 'Salud', 'Consultas', true, 45000.00, 'gasto', 'cuenta', '2026-01-21', 'Servicio', ''),
  ('demo074', 'Daviplata', 'ahorros', 'Ocio', 'Salidas', false, 180000.00, 'gasto', 'cuenta', '2026-02-01', 'Consumo', ''),
  ('demo074', 'BBVA', 'digital', 'Salud', 'Medicamentos', false, 45000.00, 'gasto', 'cuenta', '2026-02-02', 'Compra', ''),
  ('demo074', 'BBVA', 'digital', 'Vivienda', 'Arriendo', false, 25000.00, 'gasto', 'cuenta', '2026-03-17', 'Pago', ''),
  ('demo074', 'BBVA', 'digital', 'Educación', 'Libros', true, 130000.00, 'gasto', 'cuenta', '2026-03-26', 'Consumo', ''),
  ('demo074', 'Bancolombia', 'digital', 'Alimentación', 'Supermercado', false, 5000.00, 'gasto', 'cuenta', '2026-04-07', 'Consumo', ''),
  ('demo074', 'Daviplata', 'ahorros', 'Transferencias', 'Entre mis cuentas', false, 80000.00, 'transferencia_salida', 'cuenta', '2026-05-02', 'Transferencia entre cuentas (salida)', 'decc4530-255c-4b02-b2b5-ae3e1e9e7156'),
  ('demo074', 'BBVA', 'digital', 'Transferencias', 'Entre mis cuentas', false, 80000.00, 'transferencia_entrada', 'cuenta', '2026-05-02', 'Transferencia entre cuentas (entrada)', 'decc4530-255c-4b02-b2b5-ae3e1e9e7156'),
  ('demo074', 'Bancolombia', 'digital', 'Alimentación', 'Café', false, 5000.00, 'gasto', 'cuenta', '2026-05-03', 'Consumo', ''),
  ('demo074', 'Bancolombia', 'digital', 'Transporte', 'Combustible', false, 45000.00, 'gasto', 'cuenta', '2026-05-05', 'Pago', ''),
  ('demo074', 'Daviplata', 'ahorros', 'Alimentación', 'Restaurante', false, 120000.00, 'gasto', 'cuenta', '2026-05-18', 'Consumo', ''),
  ('demo074', 'Bancolombia', 'digital', 'Alimentación', 'Restaurante', false, 12000.00, 'gasto', 'cuenta', '2026-06-01', 'Servicio', ''),
  ('demo074', 'BBVA', 'digital', 'Transporte', 'Combustible', false, 12000.00, 'gasto', 'cuenta', '2026-06-07', 'Compra', ''),
  ('demo074', 'BBVA', 'digital', 'Vivienda', 'Arriendo', true, 12000.00, 'gasto', 'cuenta', '2026-06-13', 'Consumo', ''),
  ('demo074', 'Daviplata', 'ahorros', 'Educación', 'Libros', true, 250000.00, 'gasto', 'cuenta', '2026-07-01', 'Compra', ''),
  ('demo075', 'BBVA', 'corriente', 'Ingresos', 'Otros ingresos', false, 3500000.00, 'ingreso', 'cuenta', '2026-01-17', 'Ingreso extra', ''),
  ('demo075', 'Bancolombia', 'digital', 'Ocio', 'Suscripciones', false, 150000.00, 'gasto', 'cuenta', '2026-01-20', 'Consumo', ''),
  ('demo075', 'Bancolombia', 'digital', 'Ingresos', 'Salario', false, 1800000.00, 'ingreso', 'cuenta', '2026-01-21', 'Pago cliente', ''),
  ('demo075', 'Nequi', 'ahorros', 'Ocio', 'Suscripciones', false, 25000.00, 'gasto', 'cuenta', '2026-01-25', 'Servicio', ''),
  ('demo075', 'Nequi', 'ahorros', 'Ocio', 'Cine', false, 75000.00, 'gasto', 'cuenta', '2026-02-04', 'Servicio', ''),
  ('demo075', 'Bancolombia', 'digital', 'Alimentación', 'Restaurante', true, 12000.00, 'gasto', 'cuenta', '2026-02-08', 'Consumo', ''),
  ('demo075', 'BBVA', 'corriente', 'Transferencias', 'Entre mis cuentas', false, 300000.00, 'transferencia_salida', 'cuenta', '2026-02-09', 'Retiro a efectivo (salida)', '86a623af-c841-4cd2-a317-d2af1b15f4d2'),
  ('demo075', 'Efectivo', 'efectivo', 'Transferencias', 'Entre mis cuentas', false, 300000.00, 'transferencia_entrada', 'cuenta', '2026-02-09', 'Retiro a efectivo (entrada)', '86a623af-c841-4cd2-a317-d2af1b15f4d2'),
  ('demo075', 'Efectivo', 'efectivo', 'Alimentación', 'Café', false, 10000.00, 'gasto', 'efectivo', '2026-03-04', 'Consumo', ''),
  ('demo075', 'BBVA', 'corriente', 'Vivienda', 'Mantenimiento', false, 5000.00, 'gasto', 'cuenta', '2026-04-14', 'Pago', ''),
  ('demo075', 'Bancolombia', 'digital', 'Transporte', 'Combustible', false, 180000.00, 'gasto', 'cuenta', '2026-04-30', 'Compra', ''),
  ('demo075', 'Bancolombia', 'digital', 'Transporte', 'Combustible', false, 120000.00, 'gasto', 'cuenta', '2026-05-11', 'Compra', ''),
  ('demo075', 'BBVA', 'corriente', 'Salud', 'Medicamentos', false, 250000.00, 'gasto', 'cuenta', '2026-05-30', 'Compra', ''),
  ('demo076', 'Davivienda', 'digital', 'Ingresos', 'Otros ingresos', true, 3500000.00, 'ingreso', 'cuenta', '2026-01-18', 'Ingreso extra', ''),
  ('demo076', 'Davivienda', 'digital', 'Ingresos', 'Freelance', false, 2200000.00, 'ingreso', 'cuenta', '2026-03-01', 'Nomina', ''),
  ('demo076', 'Efectivo', 'efectivo', 'Ocio', 'Cine', false, 40000.00, 'gasto', 'efectivo', '2026-03-03', 'Compra', '')
) AS v(usuario, banco, tipo_cta, cat, sub, use_cp, monto, tipo, medio_pago, fecha, descripcion, grupo)
JOIN users u ON u.usuario = v.usuario
JOIN accounts a ON a.user_id = u.id AND a.banco = v.banco AND a.tipo = v.tipo_cta
JOIN categories c ON c.nombre = v.cat
JOIN sub_categories s ON s.category_id = c.id AND s.nombre = v.sub
LEFT JOIN LATERAL (
  SELECT id FROM counterparties WHERE user_id = u.id ORDER BY id LIMIT 1
) cp ON v.use_cp;

INSERT INTO transactions (account_id, category_id, sub_category_id, contraparte_id, monto, tipo, medio_pago, fecha, descripcion, activo, grupo_transferencia)
SELECT a.id, c.id, s.id, CASE WHEN v.use_cp THEN cp.id ELSE NULL END, v.monto::numeric, v.tipo, v.medio_pago, v.fecha::date, v.descripcion, true, NULLIF(v.grupo, '')
FROM (VALUES
  ('demo076', 'Efectivo', 'efectivo', 'Transporte', 'Combustible', false, 25000.00, 'gasto', 'efectivo', '2026-03-08', 'Compra', ''),
  ('demo076', 'Daviplata', 'digital', 'Transporte', 'Transporte público', true, 5000.00, 'gasto', 'cuenta', '2026-03-27', 'Compra', ''),
  ('demo076', 'Daviplata', 'digital', 'Salud', 'Medicamentos', true, 78000.00, 'gasto', 'cuenta', '2026-04-30', 'Servicio', ''),
  ('demo076', 'Davivienda', 'digital', 'Ocio', 'Salidas', false, 25000.00, 'gasto', 'cuenta', '2026-05-02', 'Compra', ''),
  ('demo076', 'Daviplata', 'digital', 'Vivienda', 'Arriendo', false, 78000.00, 'gasto', 'cuenta', '2026-05-07', 'Pago', ''),
  ('demo076', 'Efectivo', 'efectivo', 'Alimentación', 'Supermercado', false, 25000.00, 'gasto', 'efectivo', '2026-05-12', 'Compra', ''),
  ('demo076', 'Davivienda', 'digital', 'Ocio', 'Salidas', false, 5000.00, 'gasto', 'cuenta', '2026-05-26', 'Servicio', ''),
  ('demo076', 'Daviplata', 'digital', 'Ocio', 'Suscripciones', false, 120000.00, 'gasto', 'cuenta', '2026-05-31', 'Servicio', ''),
  ('demo076', 'Davivienda', 'digital', 'Educación', 'Cursos', false, 25000.00, 'gasto', 'cuenta', '2026-06-02', 'Servicio', ''),
  ('demo076', 'Davivienda', 'digital', 'Transferencias', 'Entre mis cuentas', false, 50000.00, 'transferencia_salida', 'cuenta', '2026-06-02', 'Transferencia entre cuentas (salida)', 'be4261a6-700d-4311-a032-b9c17002ecae'),
  ('demo076', 'Efectivo', 'efectivo', 'Transferencias', 'Entre mis cuentas', false, 50000.00, 'transferencia_entrada', 'cuenta', '2026-06-02', 'Transferencia entre cuentas (entrada)', 'be4261a6-700d-4311-a032-b9c17002ecae'),
  ('demo076', 'Efectivo', 'efectivo', 'Ocio', 'Salidas', true, 80000.00, 'gasto', 'efectivo', '2026-06-04', 'Servicio', ''),
  ('demo076', 'Daviplata', 'digital', 'Alimentación', 'Restaurante', false, 69000.00, 'gasto', 'cuenta', '2026-06-11', 'Servicio', ''),
  ('demo076', 'Davivienda', 'digital', 'Alimentación', 'Supermercado', false, 25000.00, 'gasto', 'cuenta', '2026-06-17', 'Consumo', ''),
  ('demo076', 'Davivienda', 'digital', 'Vivienda', 'Arriendo', false, 12000.00, 'gasto', 'cuenta', '2026-06-18', 'Compra', ''),
  ('demo076', 'Davivienda', 'digital', 'Alimentación', 'Supermercado', false, 250000.00, 'gasto', 'cuenta', '2026-06-30', 'Compra', ''),
  ('demo077', 'Banco de Bogotá', 'digital', 'Ingresos', 'Salario', true, 2200000.00, 'ingreso', 'cuenta', '2026-01-11', 'Nomina', ''),
  ('demo077', 'Daviplata', 'ahorros', 'Ingresos', 'Otros ingresos', false, 2200000.00, 'ingreso', 'cuenta', '2026-01-12', 'Ingreso extra', ''),
  ('demo077', 'Daviplata', 'ahorros', 'Transferencias', 'Entre mis cuentas', false, 50000.00, 'transferencia_salida', 'cuenta', '2026-01-13', 'Retiro a efectivo (salida)', '3c9a7f0e-010e-464d-ab7d-fe2eaceb6675'),
  ('demo077', 'Efectivo', 'efectivo', 'Transferencias', 'Entre mis cuentas', false, 50000.00, 'transferencia_entrada', 'cuenta', '2026-01-13', 'Retiro a efectivo (entrada)', '3c9a7f0e-010e-464d-ab7d-fe2eaceb6675'),
  ('demo077', 'Banco de Bogotá', 'digital', 'Salud', 'Consultas', false, 5000.00, 'gasto', 'cuenta', '2026-01-28', 'Servicio', ''),
  ('demo077', 'Daviplata', 'ahorros', 'Alimentación', 'Supermercado', false, 250000.00, 'gasto', 'cuenta', '2026-02-04', 'Servicio', ''),
  ('demo077', 'Efectivo', 'efectivo', 'Vivienda', 'Mantenimiento', true, 5000.00, 'gasto', 'efectivo', '2026-02-14', 'Compra', ''),
  ('demo077', 'Daviplata', 'ahorros', 'Ocio', 'Salidas', true, 78000.00, 'gasto', 'cuenta', '2026-02-18', 'Servicio', ''),
  ('demo077', 'Daviplata', 'ahorros', 'Ocio', 'Cine', false, 25000.00, 'gasto', 'cuenta', '2026-02-21', 'Pago', ''),
  ('demo077', 'Banco de Bogotá', 'digital', 'Alimentación', 'Restaurante', false, 250000.00, 'gasto', 'cuenta', '2026-02-25', 'Compra', ''),
  ('demo077', 'Banco de Bogotá', 'digital', 'Alimentación', 'Supermercado', false, 25000.00, 'gasto', 'cuenta', '2026-02-25', 'Compra', ''),
  ('demo077', 'Banco de Bogotá', 'digital', 'Ingresos', 'Otros ingresos', false, 1800000.00, 'ingreso', 'cuenta', '2026-02-26', 'Pago cliente', ''),
  ('demo077', 'Banco de Bogotá', 'digital', 'Vivienda', 'Arriendo', true, 120000.00, 'gasto', 'cuenta', '2026-02-28', 'Consumo', ''),
  ('demo077', 'Daviplata', 'ahorros', 'Alimentación', 'Café', false, 78000.00, 'gasto', 'cuenta', '2026-02-28', 'Servicio', ''),
  ('demo077', 'Daviplata', 'ahorros', 'Ocio', 'Salidas', false, 78000.00, 'gasto', 'cuenta', '2026-03-19', 'Pago', ''),
  ('demo077', 'Banco de Bogotá', 'digital', 'Vivienda', 'Mantenimiento', true, 120000.00, 'gasto', 'cuenta', '2026-03-27', 'Servicio', ''),
  ('demo077', 'Banco de Bogotá', 'digital', 'Vivienda', 'Arriendo', false, 120000.00, 'gasto', 'cuenta', '2026-04-01', 'Servicio', ''),
  ('demo077', 'Banco de Bogotá', 'digital', 'Transporte', 'Transporte público', false, 5000.00, 'gasto', 'cuenta', '2026-04-06', 'Compra', ''),
  ('demo077', 'Efectivo', 'efectivo', 'Alimentación', 'Supermercado', false, 5000.00, 'gasto', 'efectivo', '2026-04-11', 'Pago', ''),
  ('demo077', 'Banco de Bogotá', 'digital', 'Transferencias', 'Entre mis cuentas', false, 200000.00, 'transferencia_salida', 'cuenta', '2026-04-22', 'Transferencia entre cuentas (salida)', 'd65f5030-26ed-4464-a1ef-049641afb983'),
  ('demo077', 'Efectivo', 'efectivo', 'Transferencias', 'Entre mis cuentas', false, 200000.00, 'transferencia_entrada', 'cuenta', '2026-04-22', 'Transferencia entre cuentas (entrada)', 'd65f5030-26ed-4464-a1ef-049641afb983'),
  ('demo077', 'Daviplata', 'ahorros', 'Alimentación', 'Supermercado', false, 12000.00, 'gasto', 'cuenta', '2026-04-27', 'Servicio', ''),
  ('demo077', 'Efectivo', 'efectivo', 'Ocio', 'Suscripciones', false, 15000.00, 'gasto', 'efectivo', '2026-04-29', 'Consumo', ''),
  ('demo077', 'Daviplata', 'ahorros', 'Educación', 'Cursos', false, 12000.00, 'gasto', 'cuenta', '2026-06-19', 'Consumo', '')
) AS v(usuario, banco, tipo_cta, cat, sub, use_cp, monto, tipo, medio_pago, fecha, descripcion, grupo)
JOIN users u ON u.usuario = v.usuario
JOIN accounts a ON a.user_id = u.id AND a.banco = v.banco AND a.tipo = v.tipo_cta
JOIN categories c ON c.nombre = v.cat
JOIN sub_categories s ON s.category_id = c.id AND s.nombre = v.sub
LEFT JOIN LATERAL (
  SELECT id FROM counterparties WHERE user_id = u.id ORDER BY id LIMIT 1
) cp ON v.use_cp;

INSERT INTO transactions (account_id, category_id, sub_category_id, contraparte_id, monto, tipo, medio_pago, fecha, descripcion, activo, grupo_transferencia)
SELECT a.id, c.id, s.id, CASE WHEN v.use_cp THEN cp.id ELSE NULL END, v.monto::numeric, v.tipo, v.medio_pago, v.fecha::date, v.descripcion, true, NULLIF(v.grupo, '')
FROM (VALUES
  ('demo078', 'Davivienda', 'corriente', 'Ingresos', 'Otros ingresos', false, 3500000.00, 'ingreso', 'cuenta', '2026-01-10', 'Ingreso extra', ''),
  ('demo078', 'Davivienda', 'corriente', 'Alimentación', 'Supermercado', false, 250000.00, 'gasto', 'cuenta', '2026-01-30', 'Servicio', ''),
  ('demo078', 'Davivienda', 'corriente', 'Salud', 'Consultas', false, 5000.00, 'gasto', 'cuenta', '2026-01-30', 'Servicio', ''),
  ('demo078', 'Bancolombia', 'corriente', 'Transferencias', 'Entre mis cuentas', false, 50000.00, 'transferencia_salida', 'cuenta', '2026-02-05', 'Transferencia entre cuentas (salida)', '17e2957a-705d-418e-b8b9-a1c923549ffc'),
  ('demo078', 'Davivienda', 'corriente', 'Transferencias', 'Entre mis cuentas', false, 50000.00, 'transferencia_entrada', 'cuenta', '2026-02-05', 'Transferencia entre cuentas (entrada)', '17e2957a-705d-418e-b8b9-a1c923549ffc'),
  ('demo078', 'Davivienda', 'corriente', 'Educación', 'Libros', false, 250000.00, 'gasto', 'cuenta', '2026-02-15', 'Consumo', ''),
  ('demo078', 'Nequi', 'ahorros', 'Alimentación', 'Restaurante', false, 45000.00, 'gasto', 'cuenta', '2026-02-15', 'Consumo', ''),
  ('demo078', 'Davivienda', 'corriente', 'Salud', 'Consultas', true, 250000.00, 'gasto', 'cuenta', '2026-02-26', 'Compra', ''),
  ('demo078', 'Bancolombia', 'corriente', 'Alimentación', 'Supermercado', false, 12000.00, 'gasto', 'cuenta', '2026-02-27', 'Pago', ''),
  ('demo078', 'Bancolombia', 'corriente', 'Vivienda', 'Servicios', true, 12000.00, 'gasto', 'cuenta', '2026-03-04', 'Pago', ''),
  ('demo078', 'Bancolombia', 'corriente', 'Transporte', 'Combustible', false, 12000.00, 'gasto', 'cuenta', '2026-03-21', 'Compra', ''),
  ('demo078', 'Efectivo', 'efectivo', 'Alimentación', 'Supermercado', false, 80000.00, 'gasto', 'efectivo', '2026-04-01', 'Consumo', ''),
  ('demo078', 'Efectivo', 'efectivo', 'Transporte', 'Combustible', true, 10000.00, 'gasto', 'efectivo', '2026-06-03', 'Servicio', ''),
  ('demo078', 'Bancolombia', 'corriente', 'Salud', 'Consultas', false, 5000.00, 'gasto', 'cuenta', '2026-06-04', 'Pago', ''),
  ('demo078', 'Davivienda', 'corriente', 'Transporte', 'Combustible', false, 250000.00, 'gasto', 'cuenta', '2026-06-07', 'Servicio', ''),
  ('demo078', 'Nequi', 'ahorros', 'Alimentación', 'Restaurante', true, 5000.00, 'gasto', 'cuenta', '2026-06-07', 'Servicio', ''),
  ('demo078', 'Davivienda', 'corriente', 'Transporte', 'Transporte público', false, 12000.00, 'gasto', 'cuenta', '2026-06-13', 'Compra', ''),
  ('demo078', 'Bancolombia', 'corriente', 'Salud', 'Medicamentos', true, 5000.00, 'gasto', 'cuenta', '2026-06-17', 'Servicio', ''),
  ('demo079', 'Bancolombia', 'digital', 'Ingresos', 'Freelance', false, 2200000.00, 'ingreso', 'cuenta', '2026-01-17', 'Ingreso extra', ''),
  ('demo079', 'Banco de Bogotá', 'ahorros', 'Transporte', 'Transporte público', true, 5000.00, 'gasto', 'cuenta', '2026-01-26', 'Compra', ''),
  ('demo079', 'BBVA', 'corriente', 'Ocio', 'Salidas', true, 5000.00, 'gasto', 'cuenta', '2026-01-30', 'Consumo', ''),
  ('demo079', 'Bancolombia', 'digital', 'Alimentación', 'Café', true, 45000.00, 'gasto', 'cuenta', '2026-02-16', 'Consumo', ''),
  ('demo079', 'Banco de Bogotá', 'ahorros', 'Salud', 'Consultas', false, 250000.00, 'gasto', 'cuenta', '2026-02-19', 'Consumo', ''),
  ('demo079', 'Banco de Bogotá', 'ahorros', 'Transporte', 'Taxi / apps', false, 95000.00, 'gasto', 'cuenta', '2026-03-03', 'Compra', ''),
  ('demo079', 'Bancolombia', 'digital', 'Vivienda', 'Servicios', false, 250000.00, 'gasto', 'cuenta', '2026-03-18', 'Compra', ''),
  ('demo079', 'BBVA', 'corriente', 'Educación', 'Cursos', true, 45000.00, 'gasto', 'cuenta', '2026-04-04', 'Pago', ''),
  ('demo079', 'Efectivo', 'efectivo', 'Salud', 'Consultas', true, 55000.00, 'gasto', 'efectivo', '2026-04-11', 'Servicio', ''),
  ('demo079', 'Bancolombia', 'digital', 'Ocio', 'Cine', true, 5000.00, 'gasto', 'cuenta', '2026-05-02', 'Compra', ''),
  ('demo079', 'Bancolombia', 'digital', 'Transporte', 'Transporte público', false, 12000.00, 'gasto', 'cuenta', '2026-05-08', 'Consumo', ''),
  ('demo079', 'BBVA', 'corriente', 'Alimentación', 'Restaurante', true, 120000.00, 'gasto', 'cuenta', '2026-05-18', 'Compra', ''),
  ('demo079', 'Efectivo', 'efectivo', 'Transporte', 'Taxi / apps', false, 15000.00, 'gasto', 'efectivo', '2026-06-09', 'Pago', ''),
  ('demo079', 'Efectivo', 'efectivo', 'Transporte', 'Taxi / apps', false, 55000.00, 'gasto', 'efectivo', '2026-06-20', 'Consumo', ''),
  ('demo079', 'Bancolombia', 'digital', 'Vivienda', 'Arriendo', true, 25000.00, 'gasto', 'cuenta', '2026-06-22', 'Compra', ''),
  ('demo080', 'BBVA', 'ahorros', 'Ingresos', 'Salario', false, 3500000.00, 'ingreso', 'cuenta', '2026-01-13', 'Pago cliente', ''),
  ('demo080', 'BBVA', 'ahorros', 'Ingresos', 'Otros ingresos', false, 1200000.00, 'ingreso', 'cuenta', '2026-01-20', 'Pago cliente', ''),
  ('demo080', 'Bancolombia', 'corriente', 'Educación', 'Cursos', true, 150000.00, 'gasto', 'cuenta', '2026-01-27', 'Pago', ''),
  ('demo080', 'BBVA', 'ahorros', 'Transferencias', 'Entre mis cuentas', false, 100000.00, 'transferencia_salida', 'cuenta', '2026-01-30', 'Retiro a efectivo (salida)', '214b89c0-1399-4a15-8ce2-782cae45b336'),
  ('demo080', 'Efectivo', 'efectivo', 'Transferencias', 'Entre mis cuentas', false, 100000.00, 'transferencia_entrada', 'cuenta', '2026-01-30', 'Retiro a efectivo (entrada)', '214b89c0-1399-4a15-8ce2-782cae45b336'),
  ('demo080', 'BBVA', 'ahorros', 'Vivienda', 'Arriendo', false, 45000.00, 'gasto', 'cuenta', '2026-04-01', 'Servicio', ''),
  ('demo080', 'Efectivo', 'efectivo', 'Transporte', 'Taxi / apps', true, 25000.00, 'gasto', 'efectivo', '2026-06-02', 'Consumo', '')
) AS v(usuario, banco, tipo_cta, cat, sub, use_cp, monto, tipo, medio_pago, fecha, descripcion, grupo)
JOIN users u ON u.usuario = v.usuario
JOIN accounts a ON a.user_id = u.id AND a.banco = v.banco AND a.tipo = v.tipo_cta
JOIN categories c ON c.nombre = v.cat
JOIN sub_categories s ON s.category_id = c.id AND s.nombre = v.sub
LEFT JOIN LATERAL (
  SELECT id FROM counterparties WHERE user_id = u.id ORDER BY id LIMIT 1
) cp ON v.use_cp;

INSERT INTO transactions (account_id, category_id, sub_category_id, contraparte_id, monto, tipo, medio_pago, fecha, descripcion, activo, grupo_transferencia)
SELECT a.id, c.id, s.id, CASE WHEN v.use_cp THEN cp.id ELSE NULL END, v.monto::numeric, v.tipo, v.medio_pago, v.fecha::date, v.descripcion, true, NULLIF(v.grupo, '')
FROM (VALUES
  ('demo080', 'BBVA', 'ahorros', 'Alimentación', 'Café', false, 25000.00, 'gasto', 'cuenta', '2026-06-15', 'Consumo', ''),
  ('demo080', 'Efectivo', 'efectivo', 'Vivienda', 'Servicios', false, 15000.00, 'gasto', 'efectivo', '2026-06-21', 'Compra', ''),
  ('demo081', 'BBVA', 'corriente', 'Ingresos', 'Freelance', false, 1800000.00, 'ingreso', 'cuenta', '2026-01-14', 'Pago cliente', ''),
  ('demo081', 'Bancolombia', 'corriente', 'Educación', 'Libros', false, 5000.00, 'gasto', 'cuenta', '2026-01-19', 'Pago', ''),
  ('demo081', 'Davivienda', 'corriente', 'Vivienda', 'Arriendo', true, 45000.00, 'gasto', 'cuenta', '2026-02-21', 'Servicio', ''),
  ('demo081', 'Bancolombia', 'corriente', 'Educación', 'Cursos', false, 45000.00, 'gasto', 'cuenta', '2026-03-06', 'Consumo', ''),
  ('demo081', 'BBVA', 'corriente', 'Ocio', 'Salidas', true, 45000.00, 'gasto', 'cuenta', '2026-03-08', 'Servicio', ''),
  ('demo081', 'BBVA', 'corriente', 'Ingresos', 'Salario', true, 2800000.00, 'ingreso', 'cuenta', '2026-03-15', 'Pago cliente', ''),
  ('demo081', 'Davivienda', 'corriente', 'Alimentación', 'Supermercado', false, 55000.00, 'gasto', 'cuenta', '2026-03-22', 'Servicio', ''),
  ('demo081', 'BBVA', 'corriente', 'Vivienda', 'Servicios', false, 120000.00, 'gasto', 'cuenta', '2026-03-24', 'Servicio', ''),
  ('demo081', 'BBVA', 'corriente', 'Salud', 'Consultas', false, 78000.00, 'gasto', 'cuenta', '2026-03-28', 'Compra', ''),
  ('demo081', 'BBVA', 'corriente', 'Ocio', 'Suscripciones', false, 45000.00, 'gasto', 'cuenta', '2026-06-20', 'Compra', ''),
  ('demo082', 'Bancolombia', 'ahorros', 'Transferencias', 'Entre mis cuentas', false, 80000.00, 'transferencia_salida', 'cuenta', '2026-01-19', 'Retiro a efectivo (salida)', 'de8c04ef-e395-4c60-a31a-1adf7f892b57'),
  ('demo082', 'Efectivo', 'efectivo', 'Transferencias', 'Entre mis cuentas', false, 80000.00, 'transferencia_entrada', 'cuenta', '2026-01-19', 'Retiro a efectivo (entrada)', 'de8c04ef-e395-4c60-a31a-1adf7f892b57'),
  ('demo082', 'Daviplata', 'corriente', 'Ingresos', 'Freelance', true, 2800000.00, 'ingreso', 'cuenta', '2026-01-20', 'Ingreso extra', ''),
  ('demo082', 'Daviplata', 'corriente', 'Vivienda', 'Mantenimiento', true, 250000.00, 'gasto', 'cuenta', '2026-01-20', 'Pago', ''),
  ('demo082', 'Bancolombia', 'ahorros', 'Ingresos', 'Salario', false, 2200000.00, 'ingreso', 'cuenta', '2026-01-21', 'Pago cliente', ''),
  ('demo082', 'Bancolombia', 'ahorros', 'Educación', 'Libros', false, 120000.00, 'gasto', 'cuenta', '2026-02-15', 'Servicio', ''),
  ('demo082', 'Bancolombia', 'ahorros', 'Salud', 'Medicamentos', true, 12000.00, 'gasto', 'cuenta', '2026-02-20', 'Servicio', ''),
  ('demo082', 'Daviplata', 'corriente', 'Ingresos', 'Freelance', false, 1800000.00, 'ingreso', 'cuenta', '2026-02-26', 'Ingreso extra', ''),
  ('demo082', 'Bancolombia', 'ahorros', 'Vivienda', 'Servicios', false, 180000.00, 'gasto', 'cuenta', '2026-02-27', 'Pago', ''),
  ('demo082', 'Efectivo', 'efectivo', 'Ocio', 'Salidas', false, 55000.00, 'gasto', 'efectivo', '2026-02-27', 'Servicio', ''),
  ('demo082', 'Daviplata', 'corriente', 'Transporte', 'Combustible', false, 25000.00, 'gasto', 'cuenta', '2026-03-02', 'Servicio', ''),
  ('demo082', 'Efectivo', 'efectivo', 'Vivienda', 'Servicios', true, 5000.00, 'gasto', 'efectivo', '2026-03-18', 'Pago', ''),
  ('demo082', 'Efectivo', 'efectivo', 'Salud', 'Medicamentos', false, 55000.00, 'gasto', 'efectivo', '2026-03-18', 'Compra', ''),
  ('demo082', 'Daviplata', 'corriente', 'Educación', 'Libros', false, 45000.00, 'gasto', 'cuenta', '2026-04-11', 'Servicio', ''),
  ('demo082', 'Efectivo', 'efectivo', 'Transporte', 'Combustible', true, 40000.00, 'gasto', 'efectivo', '2026-04-14', 'Consumo', ''),
  ('demo082', 'Bancolombia', 'ahorros', 'Ocio', 'Salidas', true, 120000.00, 'gasto', 'cuenta', '2026-04-28', 'Servicio', ''),
  ('demo082', 'Bancolombia', 'ahorros', 'Educación', 'Cursos', true, 5000.00, 'gasto', 'cuenta', '2026-05-03', 'Compra', ''),
  ('demo082', 'Daviplata', 'corriente', 'Ocio', 'Suscripciones', false, 250000.00, 'gasto', 'cuenta', '2026-05-05', 'Consumo', ''),
  ('demo082', 'Bancolombia', 'ahorros', 'Alimentación', 'Restaurante', true, 180000.00, 'gasto', 'cuenta', '2026-05-30', 'Compra', ''),
  ('demo082', 'Daviplata', 'corriente', 'Salud', 'Consultas', false, 25000.00, 'gasto', 'cuenta', '2026-06-04', 'Servicio', ''),
  ('demo082', 'Bancolombia', 'ahorros', 'Transferencias', 'Entre mis cuentas', false, 200000.00, 'transferencia_salida', 'cuenta', '2026-06-05', 'Transferencia entre cuentas (salida)', 'fc12e3e2-b99d-44d5-981c-e3834efe0efc'),
  ('demo082', 'Nequi', 'digital', 'Transferencias', 'Entre mis cuentas', false, 200000.00, 'transferencia_entrada', 'cuenta', '2026-06-05', 'Transferencia entre cuentas (entrada)', 'fc12e3e2-b99d-44d5-981c-e3834efe0efc'),
  ('demo083', 'Daviplata', 'corriente', 'Ingresos', 'Otros ingresos', true, 800000.00, 'ingreso', 'cuenta', '2026-01-18', 'Nomina', ''),
  ('demo083', 'Daviplata', 'corriente', 'Vivienda', 'Servicios', false, 45000.00, 'gasto', 'cuenta', '2026-01-27', 'Consumo', ''),
  ('demo083', 'Nequi', 'ahorros', 'Alimentación', 'Supermercado', true, 12000.00, 'gasto', 'cuenta', '2026-01-31', 'Servicio', ''),
  ('demo083', 'Nequi', 'ahorros', 'Vivienda', 'Arriendo', true, 120000.00, 'gasto', 'cuenta', '2026-02-14', 'Compra', ''),
  ('demo083', 'Nequi', 'ahorros', 'Transporte', 'Taxi / apps', false, 25000.00, 'gasto', 'cuenta', '2026-03-15', 'Compra', ''),
  ('demo083', 'Nequi', 'ahorros', 'Transferencias', 'Entre mis cuentas', false, 100000.00, 'transferencia_salida', 'cuenta', '2026-04-24', 'Transferencia entre cuentas (salida)', '6b79eeff-c36c-4e1b-a9b9-d32c7ef289e0')
) AS v(usuario, banco, tipo_cta, cat, sub, use_cp, monto, tipo, medio_pago, fecha, descripcion, grupo)
JOIN users u ON u.usuario = v.usuario
JOIN accounts a ON a.user_id = u.id AND a.banco = v.banco AND a.tipo = v.tipo_cta
JOIN categories c ON c.nombre = v.cat
JOIN sub_categories s ON s.category_id = c.id AND s.nombre = v.sub
LEFT JOIN LATERAL (
  SELECT id FROM counterparties WHERE user_id = u.id ORDER BY id LIMIT 1
) cp ON v.use_cp;

INSERT INTO transactions (account_id, category_id, sub_category_id, contraparte_id, monto, tipo, medio_pago, fecha, descripcion, activo, grupo_transferencia)
SELECT a.id, c.id, s.id, CASE WHEN v.use_cp THEN cp.id ELSE NULL END, v.monto::numeric, v.tipo, v.medio_pago, v.fecha::date, v.descripcion, true, NULLIF(v.grupo, '')
FROM (VALUES
  ('demo083', 'Bancolombia', 'digital', 'Transferencias', 'Entre mis cuentas', false, 100000.00, 'transferencia_entrada', 'cuenta', '2026-04-24', 'Transferencia entre cuentas (entrada)', '6b79eeff-c36c-4e1b-a9b9-d32c7ef289e0'),
  ('demo083', 'Bancolombia', 'digital', 'Vivienda', 'Arriendo', false, 45000.00, 'gasto', 'cuenta', '2026-05-12', 'Servicio', ''),
  ('demo083', 'Nequi', 'ahorros', 'Vivienda', 'Arriendo', true, 45000.00, 'gasto', 'cuenta', '2026-06-01', 'Compra', ''),
  ('demo083', 'Nequi', 'ahorros', 'Ocio', 'Suscripciones', true, 5000.00, 'gasto', 'cuenta', '2026-06-04', 'Consumo', ''),
  ('demo083', 'Nequi', 'ahorros', 'Vivienda', 'Servicios', false, 43000.00, 'gasto', 'cuenta', '2026-06-30', 'Compra', ''),
  ('demo083', 'Daviplata', 'corriente', 'Alimentación', 'Restaurante', false, 120000.00, 'gasto', 'cuenta', '2026-07-02', 'Compra', ''),
  ('demo084', 'Davivienda', 'corriente', 'Ingresos', 'Freelance', false, 1200000.00, 'ingreso', 'cuenta', '2026-01-13', 'Nomina', ''),
  ('demo084', 'Davivienda', 'corriente', 'Salud', 'Consultas', true, 250000.00, 'gasto', 'cuenta', '2026-01-16', 'Pago', ''),
  ('demo084', 'Davivienda', 'corriente', 'Ingresos', 'Freelance', false, 2800000.00, 'ingreso', 'cuenta', '2026-01-18', 'Ingreso extra', ''),
  ('demo084', 'Davivienda', 'corriente', 'Salud', 'Consultas', true, 45000.00, 'gasto', 'cuenta', '2026-01-18', 'Consumo', ''),
  ('demo084', 'Davivienda', 'corriente', 'Vivienda', 'Servicios', false, 45000.00, 'gasto', 'cuenta', '2026-01-28', 'Servicio', ''),
  ('demo084', 'Davivienda', 'corriente', 'Alimentación', 'Supermercado', false, 250000.00, 'gasto', 'cuenta', '2026-02-02', 'Compra', ''),
  ('demo084', 'Davivienda', 'corriente', 'Alimentación', 'Restaurante', false, 45000.00, 'gasto', 'cuenta', '2026-02-13', 'Pago', ''),
  ('demo084', 'Davivienda', 'corriente', 'Transporte', 'Taxi / apps', true, 12000.00, 'gasto', 'cuenta', '2026-02-17', 'Pago', ''),
  ('demo084', 'Davivienda', 'corriente', 'Educación', 'Cursos', true, 180000.00, 'gasto', 'cuenta', '2026-03-13', 'Consumo', ''),
  ('demo084', 'Davivienda', 'corriente', 'Ocio', 'Salidas', false, 45000.00, 'gasto', 'cuenta', '2026-03-14', 'Pago', ''),
  ('demo084', 'Bancolombia', 'digital', 'Educación', 'Cursos', true, 78000.00, 'gasto', 'cuenta', '2026-03-16', 'Pago', ''),
  ('demo084', 'Bancolombia', 'digital', 'Ocio', 'Cine', true, 12000.00, 'gasto', 'cuenta', '2026-04-02', 'Servicio', ''),
  ('demo084', 'Bancolombia', 'digital', 'Educación', 'Libros', false, 25000.00, 'gasto', 'cuenta', '2026-05-02', 'Compra', ''),
  ('demo084', 'Bancolombia', 'digital', 'Salud', 'Medicamentos', false, 12000.00, 'gasto', 'cuenta', '2026-06-12', 'Pago', ''),
  ('demo084', 'Davivienda', 'corriente', 'Ocio', 'Suscripciones', true, 78000.00, 'gasto', 'cuenta', '2026-06-19', 'Servicio', ''),
  ('demo084', 'Bancolombia', 'digital', 'Educación', 'Libros', true, 73000.00, 'gasto', 'cuenta', '2026-06-20', 'Compra', ''),
  ('demo085', 'Davivienda', 'corriente', 'Ingresos', 'Otros ingresos', true, 2200000.00, 'ingreso', 'cuenta', '2026-01-07', 'Nomina', ''),
  ('demo085', 'Banco de Bogotá', 'corriente', 'Alimentación', 'Supermercado', true, 120000.00, 'gasto', 'cuenta', '2026-03-04', 'Pago', ''),
  ('demo085', 'Davivienda', 'corriente', 'Vivienda', 'Mantenimiento', false, 25000.00, 'gasto', 'cuenta', '2026-03-20', 'Pago', ''),
  ('demo085', 'Banco de Bogotá', 'corriente', 'Transporte', 'Combustible', false, 5000.00, 'gasto', 'cuenta', '2026-04-13', 'Compra', ''),
  ('demo085', 'Davivienda', 'corriente', 'Alimentación', 'Café', false, 180000.00, 'gasto', 'cuenta', '2026-04-18', 'Pago', ''),
  ('demo085', 'Banco de Bogotá', 'corriente', 'Vivienda', 'Mantenimiento', false, 75000.00, 'gasto', 'cuenta', '2026-05-05', 'Consumo', ''),
  ('demo085', 'Davivienda', 'corriente', 'Ocio', 'Salidas', true, 78000.00, 'gasto', 'cuenta', '2026-05-19', 'Compra', ''),
  ('demo085', 'Davivienda', 'corriente', 'Vivienda', 'Mantenimiento', false, 25000.00, 'gasto', 'cuenta', '2026-05-24', 'Pago', ''),
  ('demo085', 'Davivienda', 'corriente', 'Alimentación', 'Supermercado', false, 78000.00, 'gasto', 'cuenta', '2026-06-25', 'Pago', ''),
  ('demo086', 'BBVA', 'ahorros', 'Ingresos', 'Salario', false, 800000.00, 'ingreso', 'cuenta', '2026-01-14', 'Nomina', ''),
  ('demo086', 'Daviplata', 'ahorros', 'Ingresos', 'Otros ingresos', true, 3500000.00, 'ingreso', 'cuenta', '2026-01-20', 'Nomina', ''),
  ('demo086', 'Daviplata', 'ahorros', 'Transferencias', 'Entre mis cuentas', false, 200000.00, 'transferencia_salida', 'cuenta', '2026-02-02', 'Retiro a efectivo (salida)', '1180899c-5fae-4802-ae67-09c7ab087e9a'),
  ('demo086', 'Efectivo', 'efectivo', 'Transferencias', 'Entre mis cuentas', false, 200000.00, 'transferencia_entrada', 'cuenta', '2026-02-02', 'Retiro a efectivo (entrada)', '1180899c-5fae-4802-ae67-09c7ab087e9a'),
  ('demo086', 'Daviplata', 'ahorros', 'Vivienda', 'Mantenimiento', false, 180000.00, 'gasto', 'cuenta', '2026-02-04', 'Servicio', ''),
  ('demo086', 'Davivienda', 'ahorros', 'Salud', 'Consultas', false, 150000.00, 'gasto', 'cuenta', '2026-02-05', 'Consumo', ''),
  ('demo086', 'Daviplata', 'ahorros', 'Ocio', 'Suscripciones', false, 120000.00, 'gasto', 'cuenta', '2026-02-26', 'Servicio', ''),
  ('demo086', 'Daviplata', 'ahorros', 'Educación', 'Cursos', false, 5000.00, 'gasto', 'cuenta', '2026-04-21', 'Servicio', ''),
  ('demo086', 'Daviplata', 'ahorros', 'Transferencias', 'Entre mis cuentas', false, 200000.00, 'transferencia_salida', 'cuenta', '2026-06-05', 'Transferencia entre cuentas (salida)', 'a2fa2e8e-6546-4f49-bd2d-a513c0e40bec')
) AS v(usuario, banco, tipo_cta, cat, sub, use_cp, monto, tipo, medio_pago, fecha, descripcion, grupo)
JOIN users u ON u.usuario = v.usuario
JOIN accounts a ON a.user_id = u.id AND a.banco = v.banco AND a.tipo = v.tipo_cta
JOIN categories c ON c.nombre = v.cat
JOIN sub_categories s ON s.category_id = c.id AND s.nombre = v.sub
LEFT JOIN LATERAL (
  SELECT id FROM counterparties WHERE user_id = u.id ORDER BY id LIMIT 1
) cp ON v.use_cp;

INSERT INTO transactions (account_id, category_id, sub_category_id, contraparte_id, monto, tipo, medio_pago, fecha, descripcion, activo, grupo_transferencia)
SELECT a.id, c.id, s.id, CASE WHEN v.use_cp THEN cp.id ELSE NULL END, v.monto::numeric, v.tipo, v.medio_pago, v.fecha::date, v.descripcion, true, NULLIF(v.grupo, '')
FROM (VALUES
  ('demo086', 'Davivienda', 'ahorros', 'Transferencias', 'Entre mis cuentas', false, 200000.00, 'transferencia_entrada', 'cuenta', '2026-06-05', 'Transferencia entre cuentas (entrada)', 'a2fa2e8e-6546-4f49-bd2d-a513c0e40bec'),
  ('demo086', 'Efectivo', 'efectivo', 'Vivienda', 'Mantenimiento', false, 5000.00, 'gasto', 'efectivo', '2026-06-20', 'Pago', ''),
  ('demo086', 'BBVA', 'ahorros', 'Ocio', 'Salidas', true, 250000.00, 'gasto', 'cuenta', '2026-06-26', 'Pago', ''),
  ('demo087', 'Daviplata', 'ahorros', 'Ingresos', 'Freelance', false, 1200000.00, 'ingreso', 'cuenta', '2026-01-16', 'Pago cliente', ''),
  ('demo087', 'Daviplata', 'ahorros', 'Transferencias', 'Entre mis cuentas', false, 80000.00, 'transferencia_salida', 'cuenta', '2026-01-18', 'Retiro a efectivo (salida)', 'd509409f-3474-4fef-a4b8-e37fd905a9ae'),
  ('demo087', 'Efectivo', 'efectivo', 'Transferencias', 'Entre mis cuentas', false, 80000.00, 'transferencia_entrada', 'cuenta', '2026-01-18', 'Retiro a efectivo (entrada)', 'd509409f-3474-4fef-a4b8-e37fd905a9ae'),
  ('demo087', 'Davivienda', 'corriente', 'Transporte', 'Combustible', false, 250000.00, 'gasto', 'cuenta', '2026-01-24', 'Pago', ''),
  ('demo087', 'Davivienda', 'corriente', 'Salud', 'Consultas', false, 12000.00, 'gasto', 'cuenta', '2026-02-07', 'Pago', ''),
  ('demo087', 'Daviplata', 'ahorros', 'Ocio', 'Suscripciones', false, 120000.00, 'gasto', 'cuenta', '2026-02-14', 'Servicio', ''),
  ('demo087', 'Davivienda', 'corriente', 'Vivienda', 'Servicios', true, 45000.00, 'gasto', 'cuenta', '2026-02-17', 'Consumo', ''),
  ('demo087', 'Daviplata', 'ahorros', 'Alimentación', 'Café', false, 12000.00, 'gasto', 'cuenta', '2026-02-28', 'Consumo', ''),
  ('demo087', 'Daviplata', 'ahorros', 'Ocio', 'Cine', false, 12000.00, 'gasto', 'cuenta', '2026-03-18', 'Pago', ''),
  ('demo087', 'Davivienda', 'corriente', 'Salud', 'Medicamentos', false, 5000.00, 'gasto', 'cuenta', '2026-03-19', 'Compra', ''),
  ('demo087', 'Daviplata', 'ahorros', 'Ocio', 'Salidas', false, 180000.00, 'gasto', 'cuenta', '2026-04-03', 'Consumo', ''),
  ('demo087', 'Daviplata', 'ahorros', 'Transporte', 'Combustible', true, 45000.00, 'gasto', 'cuenta', '2026-05-10', 'Servicio', ''),
  ('demo087', 'Efectivo', 'efectivo', 'Educación', 'Cursos', true, 80000.00, 'gasto', 'efectivo', '2026-05-14', 'Consumo', ''),
  ('demo087', 'Davivienda', 'corriente', 'Educación', 'Libros', true, 38000.00, 'gasto', 'cuenta', '2026-05-15', 'Servicio', ''),
  ('demo087', 'Daviplata', 'ahorros', 'Salud', 'Medicamentos', true, 120000.00, 'gasto', 'cuenta', '2026-05-23', 'Compra', ''),
  ('demo088', 'Nequi', 'digital', 'Ingresos', 'Salario', false, 1200000.00, 'ingreso', 'cuenta', '2026-01-15', 'Nomina', ''),
  ('demo088', 'Daviplata', 'ahorros', 'Transferencias', 'Entre mis cuentas', false, 50000.00, 'transferencia_salida', 'cuenta', '2026-01-17', 'Retiro a efectivo (salida)', 'f33e2b3f-ed7b-40ff-880e-abbd40016772'),
  ('demo088', 'Efectivo', 'efectivo', 'Transferencias', 'Entre mis cuentas', false, 50000.00, 'transferencia_entrada', 'cuenta', '2026-01-17', 'Retiro a efectivo (entrada)', 'f33e2b3f-ed7b-40ff-880e-abbd40016772'),
  ('demo088', 'Daviplata', 'ahorros', 'Ingresos', 'Otros ingresos', true, 1800000.00, 'ingreso', 'cuenta', '2026-01-22', 'Ingreso extra', ''),
  ('demo088', 'Daviplata', 'ahorros', 'Ocio', 'Salidas', false, 180000.00, 'gasto', 'cuenta', '2026-02-04', 'Pago', ''),
  ('demo088', 'Daviplata', 'ahorros', 'Educación', 'Libros', false, 120000.00, 'gasto', 'cuenta', '2026-02-10', 'Pago', ''),
  ('demo088', 'Daviplata', 'ahorros', 'Ocio', 'Salidas', false, 120000.00, 'gasto', 'cuenta', '2026-02-19', 'Pago', ''),
  ('demo088', 'Efectivo', 'efectivo', 'Vivienda', 'Servicios', true, 25000.00, 'gasto', 'efectivo', '2026-03-06', 'Compra', ''),
  ('demo088', 'Nequi', 'digital', 'Salud', 'Medicamentos', false, 250000.00, 'gasto', 'cuenta', '2026-03-07', 'Pago', ''),
  ('demo088', 'Nequi', 'digital', 'Educación', 'Cursos', true, 12000.00, 'gasto', 'cuenta', '2026-03-30', 'Servicio', ''),
  ('demo088', 'Nequi', 'digital', 'Alimentación', 'Supermercado', true, 120000.00, 'gasto', 'cuenta', '2026-03-30', 'Compra', ''),
  ('demo088', 'Daviplata', 'ahorros', 'Vivienda', 'Servicios', false, 250000.00, 'gasto', 'cuenta', '2026-04-27', 'Compra', ''),
  ('demo088', 'Nequi', 'digital', 'Transporte', 'Combustible', true, 78000.00, 'gasto', 'cuenta', '2026-04-27', 'Pago', ''),
  ('demo088', 'Nequi', 'digital', 'Transporte', 'Transporte público', true, 78000.00, 'gasto', 'cuenta', '2026-04-27', 'Compra', ''),
  ('demo088', 'Efectivo', 'efectivo', 'Transporte', 'Taxi / apps', false, 55000.00, 'gasto', 'efectivo', '2026-05-21', 'Servicio', ''),
  ('demo088', 'Daviplata', 'ahorros', 'Educación', 'Libros', false, 180000.00, 'gasto', 'cuenta', '2026-06-01', 'Compra', ''),
  ('demo088', 'Daviplata', 'ahorros', 'Transporte', 'Combustible', false, 45000.00, 'gasto', 'cuenta', '2026-06-06', 'Pago', ''),
  ('demo088', 'Daviplata', 'ahorros', 'Transferencias', 'Entre mis cuentas', false, 200000.00, 'transferencia_salida', 'cuenta', '2026-06-06', 'Transferencia entre cuentas (salida)', 'af22c8db-ac9b-41f2-8fe1-2b5c7da831b0'),
  ('demo088', 'Nequi', 'digital', 'Transferencias', 'Entre mis cuentas', false, 200000.00, 'transferencia_entrada', 'cuenta', '2026-06-06', 'Transferencia entre cuentas (entrada)', 'af22c8db-ac9b-41f2-8fe1-2b5c7da831b0'),
  ('demo088', 'Efectivo', 'efectivo', 'Salud', 'Consultas', true, 25000.00, 'gasto', 'efectivo', '2026-06-20', 'Compra', ''),
  ('demo089', 'Banco de Bogotá', 'corriente', 'Ingresos', 'Freelance', false, 2800000.00, 'ingreso', 'cuenta', '2026-01-18', 'Nomina', ''),
  ('demo089', 'Daviplata', 'digital', 'Ingresos', 'Otros ingresos', false, 2200000.00, 'ingreso', 'cuenta', '2026-01-18', 'Nomina', '')
) AS v(usuario, banco, tipo_cta, cat, sub, use_cp, monto, tipo, medio_pago, fecha, descripcion, grupo)
JOIN users u ON u.usuario = v.usuario
JOIN accounts a ON a.user_id = u.id AND a.banco = v.banco AND a.tipo = v.tipo_cta
JOIN categories c ON c.nombre = v.cat
JOIN sub_categories s ON s.category_id = c.id AND s.nombre = v.sub
LEFT JOIN LATERAL (
  SELECT id FROM counterparties WHERE user_id = u.id ORDER BY id LIMIT 1
) cp ON v.use_cp;

INSERT INTO transactions (account_id, category_id, sub_category_id, contraparte_id, monto, tipo, medio_pago, fecha, descripcion, activo, grupo_transferencia)
SELECT a.id, c.id, s.id, CASE WHEN v.use_cp THEN cp.id ELSE NULL END, v.monto::numeric, v.tipo, v.medio_pago, v.fecha::date, v.descripcion, true, NULLIF(v.grupo, '')
FROM (VALUES
  ('demo089', 'Bancolombia', 'corriente', 'Ocio', 'Salidas', false, 78000.00, 'gasto', 'cuenta', '2026-01-27', 'Pago', ''),
  ('demo089', 'Bancolombia', 'corriente', 'Vivienda', 'Arriendo', false, 78000.00, 'gasto', 'cuenta', '2026-01-29', 'Consumo', ''),
  ('demo089', 'Banco de Bogotá', 'corriente', 'Ocio', 'Salidas', true, 25000.00, 'gasto', 'cuenta', '2026-02-12', 'Pago', ''),
  ('demo089', 'Daviplata', 'digital', 'Alimentación', 'Supermercado', true, 180000.00, 'gasto', 'cuenta', '2026-02-21', 'Pago', ''),
  ('demo089', 'Bancolombia', 'corriente', 'Ocio', 'Salidas', true, 12000.00, 'gasto', 'cuenta', '2026-02-23', 'Compra', ''),
  ('demo089', 'Bancolombia', 'corriente', 'Salud', 'Consultas', true, 120000.00, 'gasto', 'cuenta', '2026-03-07', 'Consumo', ''),
  ('demo089', 'Bancolombia', 'corriente', 'Transferencias', 'Entre mis cuentas', false, 50000.00, 'transferencia_salida', 'cuenta', '2026-03-08', 'Transferencia entre cuentas (salida)', '5b7147a9-7a65-42db-a472-a07ceb88ac60'),
  ('demo089', 'Banco de Bogotá', 'corriente', 'Transferencias', 'Entre mis cuentas', false, 50000.00, 'transferencia_entrada', 'cuenta', '2026-03-08', 'Transferencia entre cuentas (entrada)', '5b7147a9-7a65-42db-a472-a07ceb88ac60'),
  ('demo089', 'Bancolombia', 'corriente', 'Vivienda', 'Servicios', false, 12000.00, 'gasto', 'cuenta', '2026-03-12', 'Servicio', ''),
  ('demo089', 'Banco de Bogotá', 'corriente', 'Educación', 'Libros', false, 78000.00, 'gasto', 'cuenta', '2026-03-14', 'Compra', ''),
  ('demo089', 'Banco de Bogotá', 'corriente', 'Vivienda', 'Mantenimiento', false, 78000.00, 'gasto', 'cuenta', '2026-03-19', 'Compra', ''),
  ('demo089', 'Daviplata', 'digital', 'Ocio', 'Cine', false, 25000.00, 'gasto', 'cuenta', '2026-06-08', 'Servicio', ''),
  ('demo090', 'Nequi', 'corriente', 'Ingresos', 'Otros ingresos', true, 3500000.00, 'ingreso', 'cuenta', '2026-01-12', 'Ingreso extra', ''),
  ('demo090', 'Bancolombia', 'corriente', 'Alimentación', 'Supermercado', false, 45000.00, 'gasto', 'cuenta', '2026-01-21', 'Servicio', ''),
  ('demo090', 'Nequi', 'corriente', 'Vivienda', 'Servicios', false, 120000.00, 'gasto', 'cuenta', '2026-02-22', 'Compra', ''),
  ('demo090', 'Bancolombia', 'corriente', 'Ingresos', 'Otros ingresos', true, 3500000.00, 'ingreso', 'cuenta', '2026-02-27', 'Nomina', ''),
  ('demo090', 'Davivienda', 'ahorros', 'Ocio', 'Cine', false, 25000.00, 'gasto', 'cuenta', '2026-04-02', 'Compra', ''),
  ('demo090', 'Davivienda', 'ahorros', 'Ocio', 'Cine', true, 25000.00, 'gasto', 'cuenta', '2026-05-07', 'Compra', ''),
  ('demo090', 'Nequi', 'corriente', 'Transporte', 'Combustible', true, 45000.00, 'gasto', 'cuenta', '2026-05-25', 'Consumo', ''),
  ('demo090', 'Davivienda', 'ahorros', 'Vivienda', 'Arriendo', false, 78000.00, 'gasto', 'cuenta', '2026-05-29', 'Compra', ''),
  ('demo090', 'Nequi', 'corriente', 'Vivienda', 'Arriendo', false, 180000.00, 'gasto', 'cuenta', '2026-06-09', 'Consumo', ''),
  ('demo090', 'Nequi', 'corriente', 'Transferencias', 'Entre mis cuentas', false, 150000.00, 'transferencia_salida', 'cuenta', '2026-06-16', 'Transferencia entre cuentas (salida)', 'a241a70c-5c5d-4519-809f-bd0b56567f8a'),
  ('demo090', 'Bancolombia', 'corriente', 'Transferencias', 'Entre mis cuentas', false, 150000.00, 'transferencia_entrada', 'cuenta', '2026-06-16', 'Transferencia entre cuentas (entrada)', 'a241a70c-5c5d-4519-809f-bd0b56567f8a'),
  ('demo091', 'BBVA', 'ahorros', 'Ingresos', 'Salario', false, 1200000.00, 'ingreso', 'cuenta', '2026-01-11', 'Pago cliente', ''),
  ('demo091', 'Banco de Bogotá', 'corriente', 'Transferencias', 'Entre mis cuentas', false, 50000.00, 'transferencia_salida', 'cuenta', '2026-02-06', 'Retiro a efectivo (salida)', '2fca772b-0b0b-49a1-9561-7a0886fc6bbb'),
  ('demo091', 'Efectivo', 'efectivo', 'Transferencias', 'Entre mis cuentas', false, 50000.00, 'transferencia_entrada', 'cuenta', '2026-02-06', 'Retiro a efectivo (entrada)', '2fca772b-0b0b-49a1-9561-7a0886fc6bbb'),
  ('demo091', 'BBVA', 'ahorros', 'Transporte', 'Combustible', true, 45000.00, 'gasto', 'cuenta', '2026-02-21', 'Pago', ''),
  ('demo091', 'Banco de Bogotá', 'corriente', 'Ocio', 'Salidas', false, 100000.00, 'gasto', 'cuenta', '2026-03-11', 'Consumo', ''),
  ('demo091', 'Efectivo', 'efectivo', 'Vivienda', 'Mantenimiento', false, 25000.00, 'gasto', 'efectivo', '2026-03-29', 'Compra', ''),
  ('demo091', 'BBVA', 'ahorros', 'Ingresos', 'Otros ingresos', false, 3500000.00, 'ingreso', 'cuenta', '2026-04-17', 'Nomina', ''),
  ('demo091', 'BBVA', 'ahorros', 'Transporte', 'Transporte público', false, 180000.00, 'gasto', 'cuenta', '2026-04-18', 'Compra', ''),
  ('demo091', 'Efectivo', 'efectivo', 'Salud', 'Consultas', false, 55000.00, 'gasto', 'efectivo', '2026-06-06', 'Servicio', ''),
  ('demo092', 'Bancolombia', 'ahorros', 'Ingresos', 'Freelance', true, 1800000.00, 'ingreso', 'cuenta', '2026-01-07', 'Pago cliente', ''),
  ('demo092', 'BBVA', 'ahorros', 'Salud', 'Medicamentos', true, 5000.00, 'gasto', 'cuenta', '2026-01-18', 'Compra', ''),
  ('demo092', 'BBVA', 'ahorros', 'Ocio', 'Salidas', true, 120000.00, 'gasto', 'cuenta', '2026-01-27', 'Pago', ''),
  ('demo092', 'Bancolombia', 'ahorros', 'Alimentación', 'Restaurante', true, 25000.00, 'gasto', 'cuenta', '2026-02-06', 'Compra', ''),
  ('demo092', 'Nequi', 'corriente', 'Ingresos', 'Salario', false, 1800000.00, 'ingreso', 'cuenta', '2026-02-19', 'Pago cliente', ''),
  ('demo092', 'Nequi', 'corriente', 'Ocio', 'Salidas', true, 12000.00, 'gasto', 'cuenta', '2026-02-20', 'Pago', ''),
  ('demo092', 'BBVA', 'ahorros', 'Salud', 'Consultas', true, 120000.00, 'gasto', 'cuenta', '2026-03-04', 'Consumo', ''),
  ('demo092', 'Nequi', 'corriente', 'Transporte', 'Transporte público', true, 5000.00, 'gasto', 'cuenta', '2026-03-06', 'Consumo', '')
) AS v(usuario, banco, tipo_cta, cat, sub, use_cp, monto, tipo, medio_pago, fecha, descripcion, grupo)
JOIN users u ON u.usuario = v.usuario
JOIN accounts a ON a.user_id = u.id AND a.banco = v.banco AND a.tipo = v.tipo_cta
JOIN categories c ON c.nombre = v.cat
JOIN sub_categories s ON s.category_id = c.id AND s.nombre = v.sub
LEFT JOIN LATERAL (
  SELECT id FROM counterparties WHERE user_id = u.id ORDER BY id LIMIT 1
) cp ON v.use_cp;

INSERT INTO transactions (account_id, category_id, sub_category_id, contraparte_id, monto, tipo, medio_pago, fecha, descripcion, activo, grupo_transferencia)
SELECT a.id, c.id, s.id, CASE WHEN v.use_cp THEN cp.id ELSE NULL END, v.monto::numeric, v.tipo, v.medio_pago, v.fecha::date, v.descripcion, true, NULLIF(v.grupo, '')
FROM (VALUES
  ('demo092', 'BBVA', 'ahorros', 'Transferencias', 'Entre mis cuentas', false, 80000.00, 'transferencia_salida', 'cuenta', '2026-03-31', 'Transferencia entre cuentas (salida)', '9bb9da7f-a4d1-43be-8ade-0d7f18750118'),
  ('demo092', 'Nequi', 'corriente', 'Transferencias', 'Entre mis cuentas', false, 80000.00, 'transferencia_entrada', 'cuenta', '2026-03-31', 'Transferencia entre cuentas (entrada)', '9bb9da7f-a4d1-43be-8ade-0d7f18750118'),
  ('demo092', 'Nequi', 'corriente', 'Vivienda', 'Arriendo', true, 78000.00, 'gasto', 'cuenta', '2026-04-21', 'Servicio', ''),
  ('demo092', 'Bancolombia', 'ahorros', 'Transporte', 'Combustible', false, 25000.00, 'gasto', 'cuenta', '2026-04-28', 'Compra', ''),
  ('demo092', 'Nequi', 'corriente', 'Vivienda', 'Arriendo', false, 45000.00, 'gasto', 'cuenta', '2026-05-03', 'Servicio', ''),
  ('demo092', 'Bancolombia', 'ahorros', 'Salud', 'Medicamentos', false, 120000.00, 'gasto', 'cuenta', '2026-06-20', 'Servicio', ''),
  ('demo093', 'BBVA', 'digital', 'Ingresos', 'Freelance', false, 2800000.00, 'ingreso', 'cuenta', '2026-01-07', 'Ingreso extra', ''),
  ('demo093', 'Banco de Bogotá', 'corriente', 'Ingresos', 'Salario', false, 1800000.00, 'ingreso', 'cuenta', '2026-01-19', 'Pago cliente', ''),
  ('demo093', 'BBVA', 'digital', 'Transferencias', 'Entre mis cuentas', false, 200000.00, 'transferencia_salida', 'cuenta', '2026-01-23', 'Retiro a efectivo (salida)', '0df81b76-e123-4130-9ca4-198c6d5d1c45'),
  ('demo093', 'Efectivo', 'efectivo', 'Transferencias', 'Entre mis cuentas', false, 200000.00, 'transferencia_entrada', 'cuenta', '2026-01-23', 'Retiro a efectivo (entrada)', '0df81b76-e123-4130-9ca4-198c6d5d1c45'),
  ('demo093', 'BBVA', 'digital', 'Vivienda', 'Servicios', false, 25000.00, 'gasto', 'cuenta', '2026-02-03', 'Compra', ''),
  ('demo093', 'Banco de Bogotá', 'corriente', 'Transporte', 'Transporte público', false, 5000.00, 'gasto', 'cuenta', '2026-02-26', 'Consumo', ''),
  ('demo093', 'Efectivo', 'efectivo', 'Alimentación', 'Restaurante', false, 15000.00, 'gasto', 'efectivo', '2026-03-03', 'Pago', ''),
  ('demo093', 'BBVA', 'digital', 'Ingresos', 'Salario', false, 2800000.00, 'ingreso', 'cuenta', '2026-03-12', 'Nomina', ''),
  ('demo093', 'Banco de Bogotá', 'corriente', 'Alimentación', 'Café', false, 120000.00, 'gasto', 'cuenta', '2026-04-23', 'Consumo', ''),
  ('demo093', 'Banco de Bogotá', 'corriente', 'Salud', 'Consultas', false, 78000.00, 'gasto', 'cuenta', '2026-04-24', 'Compra', ''),
  ('demo093', 'BBVA', 'digital', 'Vivienda', 'Servicios', true, 120000.00, 'gasto', 'cuenta', '2026-04-27', 'Consumo', ''),
  ('demo093', 'BBVA', 'digital', 'Ocio', 'Suscripciones', false, 12000.00, 'gasto', 'cuenta', '2026-05-07', 'Consumo', ''),
  ('demo093', 'BBVA', 'digital', 'Vivienda', 'Servicios', true, 250000.00, 'gasto', 'cuenta', '2026-05-21', 'Consumo', ''),
  ('demo093', 'Banco de Bogotá', 'corriente', 'Educación', 'Cursos', false, 25000.00, 'gasto', 'cuenta', '2026-05-25', 'Pago', ''),
  ('demo093', 'Banco de Bogotá', 'corriente', 'Transporte', 'Transporte público', true, 120000.00, 'gasto', 'cuenta', '2026-05-26', 'Servicio', ''),
  ('demo093', 'BBVA', 'digital', 'Transporte', 'Taxi / apps', true, 250000.00, 'gasto', 'cuenta', '2026-05-31', 'Pago', ''),
  ('demo093', 'Banco de Bogotá', 'corriente', 'Salud', 'Medicamentos', true, 25000.00, 'gasto', 'cuenta', '2026-06-07', 'Compra', ''),
  ('demo093', 'BBVA', 'digital', 'Vivienda', 'Arriendo', true, 180000.00, 'gasto', 'cuenta', '2026-06-19', 'Compra', ''),
  ('demo094', 'Bancolombia', 'corriente', 'Ingresos', 'Salario', true, 1200000.00, 'ingreso', 'cuenta', '2026-01-15', 'Nomina', ''),
  ('demo094', 'Bancolombia', 'corriente', 'Transporte', 'Transporte público', false, 180000.00, 'gasto', 'cuenta', '2026-01-21', 'Consumo', ''),
  ('demo094', 'Daviplata', 'ahorros', 'Transporte', 'Combustible', true, 180000.00, 'gasto', 'cuenta', '2026-01-30', 'Servicio', ''),
  ('demo094', 'Daviplata', 'ahorros', 'Transporte', 'Combustible', true, 45000.00, 'gasto', 'cuenta', '2026-02-16', 'Consumo', ''),
  ('demo094', 'Bancolombia', 'corriente', 'Ocio', 'Cine', false, 12000.00, 'gasto', 'cuenta', '2026-02-24', 'Compra', ''),
  ('demo094', 'Daviplata', 'ahorros', 'Ocio', 'Salidas', false, 25000.00, 'gasto', 'cuenta', '2026-02-26', 'Consumo', ''),
  ('demo094', 'Bancolombia', 'corriente', 'Salud', 'Medicamentos', true, 25000.00, 'gasto', 'cuenta', '2026-03-19', 'Consumo', ''),
  ('demo094', 'Daviplata', 'ahorros', 'Educación', 'Libros', false, 78000.00, 'gasto', 'cuenta', '2026-03-25', 'Consumo', ''),
  ('demo094', 'Daviplata', 'ahorros', 'Transporte', 'Transporte público', true, 5000.00, 'gasto', 'cuenta', '2026-04-04', 'Pago', ''),
  ('demo094', 'Bancolombia', 'corriente', 'Educación', 'Libros', true, 250000.00, 'gasto', 'cuenta', '2026-04-10', 'Compra', ''),
  ('demo094', 'Bancolombia', 'corriente', 'Transporte', 'Transporte público', true, 78000.00, 'gasto', 'cuenta', '2026-05-18', 'Compra', ''),
  ('demo094', 'Daviplata', 'ahorros', 'Ocio', 'Suscripciones', true, 17000.00, 'gasto', 'cuenta', '2026-06-04', 'Consumo', ''),
  ('demo094', 'Bancolombia', 'corriente', 'Ocio', 'Salidas', true, 250000.00, 'gasto', 'cuenta', '2026-06-04', 'Consumo', ''),
  ('demo094', 'Efectivo', 'efectivo', 'Vivienda', 'Servicios', false, 55000.00, 'gasto', 'efectivo', '2026-06-11', 'Servicio', ''),
  ('demo094', 'Bancolombia', 'corriente', 'Transferencias', 'Entre mis cuentas', false, 200000.00, 'transferencia_salida', 'cuenta', '2026-06-12', 'Transferencia entre cuentas (salida)', '0f882f6a-84c2-4629-80df-b3f45de87dd4'),
  ('demo094', 'Efectivo', 'efectivo', 'Transferencias', 'Entre mis cuentas', false, 200000.00, 'transferencia_entrada', 'cuenta', '2026-06-12', 'Transferencia entre cuentas (entrada)', '0f882f6a-84c2-4629-80df-b3f45de87dd4')
) AS v(usuario, banco, tipo_cta, cat, sub, use_cp, monto, tipo, medio_pago, fecha, descripcion, grupo)
JOIN users u ON u.usuario = v.usuario
JOIN accounts a ON a.user_id = u.id AND a.banco = v.banco AND a.tipo = v.tipo_cta
JOIN categories c ON c.nombre = v.cat
JOIN sub_categories s ON s.category_id = c.id AND s.nombre = v.sub
LEFT JOIN LATERAL (
  SELECT id FROM counterparties WHERE user_id = u.id ORDER BY id LIMIT 1
) cp ON v.use_cp;

INSERT INTO transactions (account_id, category_id, sub_category_id, contraparte_id, monto, tipo, medio_pago, fecha, descripcion, activo, grupo_transferencia)
SELECT a.id, c.id, s.id, CASE WHEN v.use_cp THEN cp.id ELSE NULL END, v.monto::numeric, v.tipo, v.medio_pago, v.fecha::date, v.descripcion, true, NULLIF(v.grupo, '')
FROM (VALUES
  ('demo095', 'Bancolombia', 'ahorros', 'Ingresos', 'Salario', false, 3500000.00, 'ingreso', 'cuenta', '2026-01-10', 'Ingreso extra', ''),
  ('demo095', 'Bancolombia', 'ahorros', 'Transporte', 'Combustible', false, 5000.00, 'gasto', 'cuenta', '2026-01-31', 'Compra', ''),
  ('demo095', 'Daviplata', 'corriente', 'Transporte', 'Transporte público', true, 5000.00, 'gasto', 'cuenta', '2026-02-21', 'Consumo', ''),
  ('demo095', 'Daviplata', 'corriente', 'Alimentación', 'Supermercado', true, 12000.00, 'gasto', 'cuenta', '2026-02-21', 'Servicio', ''),
  ('demo095', 'Daviplata', 'corriente', 'Transporte', 'Transporte público', false, 83000.00, 'gasto', 'cuenta', '2026-02-22', 'Consumo', ''),
  ('demo095', 'Bancolombia', 'ahorros', 'Alimentación', 'Supermercado', true, 250000.00, 'gasto', 'cuenta', '2026-03-11', 'Consumo', ''),
  ('demo095', 'Bancolombia', 'ahorros', 'Vivienda', 'Mantenimiento', false, 250000.00, 'gasto', 'cuenta', '2026-04-02', 'Consumo', ''),
  ('demo095', 'Bancolombia', 'ahorros', 'Ingresos', 'Freelance', false, 1200000.00, 'ingreso', 'cuenta', '2026-04-03', 'Nomina', ''),
  ('demo095', 'Bancolombia', 'ahorros', 'Vivienda', 'Servicios', true, 5000.00, 'gasto', 'cuenta', '2026-05-14', 'Servicio', ''),
  ('demo096', 'Davivienda', 'ahorros', 'Ingresos', 'Salario', false, 2800000.00, 'ingreso', 'cuenta', '2026-01-14', 'Pago cliente', ''),
  ('demo096', 'Davivienda', 'ahorros', 'Transporte', 'Combustible', false, 25000.00, 'gasto', 'cuenta', '2026-01-29', 'Consumo', ''),
  ('demo096', 'Bancolombia', 'ahorros', 'Alimentación', 'Supermercado', false, 25000.00, 'gasto', 'cuenta', '2026-01-30', 'Servicio', ''),
  ('demo096', 'Bancolombia', 'ahorros', 'Transporte', 'Taxi / apps', false, 78000.00, 'gasto', 'cuenta', '2026-02-10', 'Pago', ''),
  ('demo096', 'Bancolombia', 'ahorros', 'Vivienda', 'Servicios', false, 12000.00, 'gasto', 'cuenta', '2026-04-08', 'Pago', ''),
  ('demo096', 'Efectivo', 'efectivo', 'Transporte', 'Transporte público', false, 55000.00, 'gasto', 'efectivo', '2026-04-26', 'Pago', ''),
  ('demo096', 'Davivienda', 'ahorros', 'Ingresos', 'Salario', false, 2200000.00, 'ingreso', 'cuenta', '2026-05-02', 'Pago cliente', ''),
  ('demo096', 'Davivienda', 'ahorros', 'Ocio', 'Suscripciones', true, 5000.00, 'gasto', 'cuenta', '2026-05-21', 'Pago', ''),
  ('demo096', 'Bancolombia', 'ahorros', 'Educación', 'Libros', false, 25000.00, 'gasto', 'cuenta', '2026-06-11', 'Compra', ''),
  ('demo097', 'Davivienda', 'digital', 'Ingresos', 'Salario', false, 3500000.00, 'ingreso', 'cuenta', '2026-01-18', 'Ingreso extra', ''),
  ('demo097', 'Davivienda', 'digital', 'Ingresos', 'Salario', false, 2800000.00, 'ingreso', 'cuenta', '2026-01-18', 'Nomina', ''),
  ('demo097', 'BBVA', 'ahorros', 'Transporte', 'Taxi / apps', false, 100000.00, 'gasto', 'cuenta', '2026-01-29', 'Servicio', ''),
  ('demo097', 'Bancolombia', 'corriente', 'Transferencias', 'Entre mis cuentas', false, 80000.00, 'transferencia_salida', 'cuenta', '2026-02-05', 'Retiro a efectivo (salida)', '6d3bed74-f20a-4cc0-b4f9-50f477a0b415'),
  ('demo097', 'Efectivo', 'efectivo', 'Transferencias', 'Entre mis cuentas', false, 80000.00, 'transferencia_entrada', 'cuenta', '2026-02-05', 'Retiro a efectivo (entrada)', '6d3bed74-f20a-4cc0-b4f9-50f477a0b415'),
  ('demo097', 'Efectivo', 'efectivo', 'Ocio', 'Cine', false, 5000.00, 'gasto', 'efectivo', '2026-02-16', 'Servicio', ''),
  ('demo097', 'Davivienda', 'digital', 'Transporte', 'Combustible', true, 250000.00, 'gasto', 'cuenta', '2026-02-19', 'Compra', ''),
  ('demo097', 'Bancolombia', 'corriente', 'Ocio', 'Salidas', false, 20000.00, 'gasto', 'cuenta', '2026-02-21', 'Pago', ''),
  ('demo097', 'Davivienda', 'digital', 'Educación', 'Libros', false, 25000.00, 'gasto', 'cuenta', '2026-05-11', 'Pago', ''),
  ('demo097', 'Efectivo', 'efectivo', 'Alimentación', 'Restaurante', true, 15000.00, 'gasto', 'efectivo', '2026-05-11', 'Servicio', ''),
  ('demo097', 'Efectivo', 'efectivo', 'Vivienda', 'Arriendo', true, 25000.00, 'gasto', 'efectivo', '2026-06-04', 'Compra', ''),
  ('demo097', 'Davivienda', 'digital', 'Alimentación', 'Café', true, 25000.00, 'gasto', 'cuenta', '2026-07-04', 'Pago', ''),
  ('demo098', 'Daviplata', 'ahorros', 'Ingresos', 'Freelance', false, 2200000.00, 'ingreso', 'cuenta', '2026-01-12', 'Nomina', ''),
  ('demo098', 'Davivienda', 'corriente', 'Alimentación', 'Supermercado', false, 50000.00, 'gasto', 'cuenta', '2026-01-15', 'Servicio', ''),
  ('demo098', 'Daviplata', 'ahorros', 'Ingresos', 'Freelance', false, 3500000.00, 'ingreso', 'cuenta', '2026-01-16', 'Ingreso extra', ''),
  ('demo098', 'Daviplata', 'ahorros', 'Transferencias', 'Entre mis cuentas', false, 50000.00, 'transferencia_salida', 'cuenta', '2026-01-19', 'Retiro a efectivo (salida)', 'b9eb5167-a33a-44fa-9981-dc53d70ceef6'),
  ('demo098', 'Efectivo', 'efectivo', 'Transferencias', 'Entre mis cuentas', false, 50000.00, 'transferencia_entrada', 'cuenta', '2026-01-19', 'Retiro a efectivo (entrada)', 'b9eb5167-a33a-44fa-9981-dc53d70ceef6'),
  ('demo098', 'Efectivo', 'efectivo', 'Vivienda', 'Arriendo', false, 5000.00, 'gasto', 'efectivo', '2026-01-23', 'Pago', ''),
  ('demo098', 'Efectivo', 'efectivo', 'Transporte', 'Taxi / apps', true, 40000.00, 'gasto', 'efectivo', '2026-02-27', 'Servicio', ''),
  ('demo098', 'Daviplata', 'ahorros', 'Alimentación', 'Supermercado', false, 45000.00, 'gasto', 'cuenta', '2026-03-04', 'Consumo', ''),
  ('demo098', 'Efectivo', 'efectivo', 'Salud', 'Medicamentos', false, 5000.00, 'gasto', 'efectivo', '2026-04-11', 'Consumo', ''),
  ('demo098', 'Daviplata', 'ahorros', 'Educación', 'Cursos', false, 250000.00, 'gasto', 'cuenta', '2026-04-13', 'Servicio', '')
) AS v(usuario, banco, tipo_cta, cat, sub, use_cp, monto, tipo, medio_pago, fecha, descripcion, grupo)
JOIN users u ON u.usuario = v.usuario
JOIN accounts a ON a.user_id = u.id AND a.banco = v.banco AND a.tipo = v.tipo_cta
JOIN categories c ON c.nombre = v.cat
JOIN sub_categories s ON s.category_id = c.id AND s.nombre = v.sub
LEFT JOIN LATERAL (
  SELECT id FROM counterparties WHERE user_id = u.id ORDER BY id LIMIT 1
) cp ON v.use_cp;

INSERT INTO transactions (account_id, category_id, sub_category_id, contraparte_id, monto, tipo, medio_pago, fecha, descripcion, activo, grupo_transferencia)
SELECT a.id, c.id, s.id, CASE WHEN v.use_cp THEN cp.id ELSE NULL END, v.monto::numeric, v.tipo, v.medio_pago, v.fecha::date, v.descripcion, true, NULLIF(v.grupo, '')
FROM (VALUES
  ('demo098', 'Daviplata', 'ahorros', 'Ocio', 'Salidas', true, 250000.00, 'gasto', 'cuenta', '2026-06-05', 'Consumo', ''),
  ('demo098', 'Daviplata', 'ahorros', 'Ocio', 'Suscripciones', false, 180000.00, 'gasto', 'cuenta', '2026-06-08', 'Consumo', ''),
  ('demo099', 'Daviplata', 'corriente', 'Ingresos', 'Freelance', true, 800000.00, 'ingreso', 'cuenta', '2026-01-13', 'Nomina', ''),
  ('demo099', 'Daviplata', 'corriente', 'Salud', 'Consultas', true, 120000.00, 'gasto', 'cuenta', '2026-01-15', 'Consumo', ''),
  ('demo099', 'Bancolombia', 'corriente', 'Ocio', 'Suscripciones', false, 45000.00, 'gasto', 'cuenta', '2026-03-12', 'Pago', ''),
  ('demo099', 'Bancolombia', 'corriente', 'Ocio', 'Salidas', false, 5000.00, 'gasto', 'cuenta', '2026-03-22', 'Pago', ''),
  ('demo099', 'Daviplata', 'corriente', 'Vivienda', 'Servicios', false, 180000.00, 'gasto', 'cuenta', '2026-04-19', 'Compra', ''),
  ('demo099', 'Daviplata', 'corriente', 'Ocio', 'Suscripciones', false, 12000.00, 'gasto', 'cuenta', '2026-04-25', 'Consumo', ''),
  ('demo099', 'Daviplata', 'corriente', 'Vivienda', 'Arriendo', true, 120000.00, 'gasto', 'cuenta', '2026-04-29', 'Compra', ''),
  ('demo099', 'Daviplata', 'corriente', 'Transferencias', 'Entre mis cuentas', false, 200000.00, 'transferencia_salida', 'cuenta', '2026-05-17', 'Transferencia entre cuentas (salida)', 'f80fd810-3dfc-4215-9285-1bcddb260f83'),
  ('demo099', 'Bancolombia', 'corriente', 'Transferencias', 'Entre mis cuentas', false, 200000.00, 'transferencia_entrada', 'cuenta', '2026-05-17', 'Transferencia entre cuentas (entrada)', 'f80fd810-3dfc-4215-9285-1bcddb260f83'),
  ('demo099', 'Daviplata', 'corriente', 'Alimentación', 'Supermercado', false, 180000.00, 'gasto', 'cuenta', '2026-05-23', 'Pago', ''),
  ('demo099', 'Bancolombia', 'corriente', 'Vivienda', 'Servicios', true, 25000.00, 'gasto', 'cuenta', '2026-06-28', 'Pago', ''),
  ('demo100', 'Davivienda', 'ahorros', 'Ingresos', 'Otros ingresos', false, 2800000.00, 'ingreso', 'cuenta', '2026-01-14', 'Ingreso extra', ''),
  ('demo100', 'Daviplata', 'ahorros', 'Ocio', 'Cine', false, 50000.00, 'gasto', 'cuenta', '2026-01-20', 'Servicio', ''),
  ('demo100', 'Davivienda', 'ahorros', 'Transporte', 'Taxi / apps', false, 5000.00, 'gasto', 'cuenta', '2026-02-02', 'Consumo', ''),
  ('demo100', 'Efectivo', 'efectivo', 'Ocio', 'Cine', false, 10000.00, 'gasto', 'efectivo', '2026-03-04', 'Compra', ''),
  ('demo100', 'Efectivo', 'efectivo', 'Salud', 'Consultas', true, 5000.00, 'gasto', 'efectivo', '2026-03-09', 'Pago', ''),
  ('demo100', 'Davivienda', 'ahorros', 'Transferencias', 'Entre mis cuentas', false, 80000.00, 'transferencia_salida', 'cuenta', '2026-03-18', 'Transferencia entre cuentas (salida)', 'b2d231c0-ad50-49b6-83ed-975000cb10ae'),
  ('demo100', 'Efectivo', 'efectivo', 'Transferencias', 'Entre mis cuentas', false, 80000.00, 'transferencia_entrada', 'cuenta', '2026-03-18', 'Transferencia entre cuentas (entrada)', 'b2d231c0-ad50-49b6-83ed-975000cb10ae'),
  ('demo100', 'Efectivo', 'efectivo', 'Vivienda', 'Mantenimiento', true, 15000.00, 'gasto', 'efectivo', '2026-04-12', 'Servicio', ''),
  ('demo100', 'Davivienda', 'ahorros', 'Educación', 'Cursos', false, 78000.00, 'gasto', 'cuenta', '2026-04-30', 'Servicio', ''),
  ('demo100', 'Efectivo', 'efectivo', 'Vivienda', 'Arriendo', true, 25000.00, 'gasto', 'efectivo', '2026-05-17', 'Consumo', ''),
  ('demo100', 'Davivienda', 'ahorros', 'Ocio', 'Suscripciones', false, 78000.00, 'gasto', 'cuenta', '2026-05-19', 'Compra', ''),
  ('demo100', 'Davivienda', 'ahorros', 'Transporte', 'Taxi / apps', false, 78000.00, 'gasto', 'cuenta', '2026-05-20', 'Pago', ''),
  ('demo100', 'Bancolombia', 'digital', 'Educación', 'Cursos', false, 50000.00, 'gasto', 'cuenta', '2026-06-24', 'Servicio', '')
) AS v(usuario, banco, tipo_cta, cat, sub, use_cp, monto, tipo, medio_pago, fecha, descripcion, grupo)
JOIN users u ON u.usuario = v.usuario
JOIN accounts a ON a.user_id = u.id AND a.banco = v.banco AND a.tipo = v.tipo_cta
JOIN categories c ON c.nombre = v.cat
JOIN sub_categories s ON s.category_id = c.id AND s.nombre = v.sub
LEFT JOIN LATERAL (
  SELECT id FROM counterparties WHERE user_id = u.id ORDER BY id LIMIT 1
) cp ON v.use_cp;

-- Reconcile account balances (multi-row)
UPDATE accounts a SET
  saldo = v.saldo::numeric,
  actualizado_en = now()
FROM (VALUES
  ('demo001', 'Nequi', 'ahorros', 293000.00),
  ('demo001', 'Bancolombia', 'corriente', 1510000.00),
  ('demo001', 'Efectivo', 'efectivo', 450000.00),
  ('demo002', 'Davivienda', 'corriente', 1310000.00),
  ('demo002', 'Nequi', 'ahorros', 70000.00),
  ('demo002', 'Banco de Bogotá', 'ahorros', 0.00),
  ('demo002', 'Efectivo', 'efectivo', 685000.00),
  ('demo003', 'Bancolombia', 'digital', 0.00),
  ('demo003', 'Nequi', 'ahorros', 200000.00),
  ('demo003', 'Banco de Bogotá', 'ahorros', 2450000.00),
  ('demo003', 'Efectivo', 'efectivo', 297000.00),
  ('demo004', 'Nequi', 'digital', 735000.00),
  ('demo004', 'BBVA', 'ahorros', 4345000.00),
  ('demo004', 'Davivienda', 'corriente', 193000.00),
  ('demo005', 'Daviplata', 'ahorros', 0.00),
  ('demo005', 'Banco de Bogotá', 'ahorros', 5730000.00),
  ('demo005', 'Davivienda', 'corriente', 0.00),
  ('demo005', 'Efectivo', 'efectivo', 435000.00),
  ('demo006', 'Daviplata', 'corriente', 2165000.00),
  ('demo006', 'Davivienda', 'corriente', 1708000.00),
  ('demo006', 'Efectivo', 'efectivo', 325000.00),
  ('demo007', 'Daviplata', 'ahorros', 2032000.00),
  ('demo007', 'Banco de Bogotá', 'digital', 0.00),
  ('demo007', 'Bancolombia', 'digital', 0.00),
  ('demo007', 'Efectivo', 'efectivo', 445000.00),
  ('demo008', 'Nequi', 'ahorros', 4060000.00),
  ('demo008', 'Davivienda', 'ahorros', 10000.00),
  ('demo008', 'Daviplata', 'ahorros', 2880000.00),
  ('demo009', 'BBVA', 'digital', 0.00),
  ('demo009', 'Bancolombia', 'corriente', 2222000.00),
  ('demo009', 'Daviplata', 'digital', 100000.00),
  ('demo009', 'Efectivo', 'efectivo', 135000.00),
  ('demo010', 'BBVA', 'ahorros', 4833000.00),
  ('demo010', 'Nequi', 'digital', 270000.00),
  ('demo010', 'Daviplata', 'ahorros', 448000.00),
  ('demo011', 'Banco de Bogotá', 'digital', 665000.00),
  ('demo011', 'Davivienda', 'digital', 1487000.00),
  ('demo011', 'Efectivo', 'efectivo', 335000.00),
  ('demo012', 'Daviplata', 'corriente', 2080000.00),
  ('demo012', 'Bancolombia', 'digital', 663000.00),
  ('demo012', 'Efectivo', 'efectivo', 475000.00),
  ('demo013', 'BBVA', 'corriente', 1008000.00),
  ('demo013', 'Daviplata', 'digital', 3372000.00),
  ('demo013', 'Davivienda', 'digital', 0.00),
  ('demo013', 'Efectivo', 'efectivo', 460000.00),
  ('demo014', 'BBVA', 'ahorros', 3553000.00),
  ('demo014', 'Davivienda', 'digital', 0.00),
  ('demo014', 'Banco de Bogotá', 'corriente', 0.00),
  ('demo014', 'Efectivo', 'efectivo', 195000.00),
  ('demo015', 'Davivienda', 'corriente', 0.00)
) AS v(usuario, banco, tipo, saldo)
JOIN users u ON u.usuario = v.usuario
WHERE a.user_id = u.id AND a.banco = v.banco AND a.tipo = v.tipo;

UPDATE accounts a SET
  saldo = v.saldo::numeric,
  actualizado_en = now()
FROM (VALUES
  ('demo015', 'BBVA', 'corriente', 4338000.00),
  ('demo015', 'Efectivo', 'efectivo', 395000.00),
  ('demo016', 'BBVA', 'digital', 1722000.00),
  ('demo016', 'Daviplata', 'corriente', 2330000.00),
  ('demo016', 'Efectivo', 'efectivo', 170000.00),
  ('demo017', 'Daviplata', 'corriente', 5793000.00),
  ('demo017', 'BBVA', 'ahorros', 150000.00),
  ('demo017', 'Efectivo', 'efectivo', 400000.00),
  ('demo018', 'Bancolombia', 'corriente', 1405000.00),
  ('demo018', 'Davivienda', 'digital', 2040000.00),
  ('demo018', 'Nequi', 'digital', 3130000.00),
  ('demo018', 'Efectivo', 'efectivo', 470000.00),
  ('demo019', 'Daviplata', 'ahorros', 1960000.00),
  ('demo019', 'Banco de Bogotá', 'corriente', 0.00),
  ('demo019', 'Davivienda', 'corriente', 3045000.00),
  ('demo019', 'Efectivo', 'efectivo', 145000.00),
  ('demo020', 'Banco de Bogotá', 'corriente', 1905000.00),
  ('demo020', 'Daviplata', 'digital', 0.00),
  ('demo020', 'Bancolombia', 'digital', 1435000.00),
  ('demo020', 'Efectivo', 'efectivo', 245000.00),
  ('demo021', 'Bancolombia', 'corriente', 3147000.00),
  ('demo021', 'Nequi', 'digital', 2675000.00),
  ('demo021', 'Daviplata', 'digital', 0.00),
  ('demo022', 'Banco de Bogotá', 'digital', 1888000.00),
  ('demo022', 'BBVA', 'digital', 570000.00),
  ('demo022', 'Bancolombia', 'digital', 0.00),
  ('demo022', 'Efectivo', 'efectivo', 255000.00),
  ('demo023', 'Davivienda', 'digital', 666000.00),
  ('demo023', 'Banco de Bogotá', 'corriente', 817000.00),
  ('demo023', 'Efectivo', 'efectivo', 385000.00),
  ('demo024', 'Davivienda', 'corriente', 18000.00),
  ('demo024', 'Bancolombia', 'corriente', 3570000.00),
  ('demo024', 'Daviplata', 'corriente', 75000.00),
  ('demo024', 'Efectivo', 'efectivo', 585000.00),
  ('demo025', 'Banco de Bogotá', 'corriente', 0.00),
  ('demo025', 'Nequi', 'corriente', 0.00),
  ('demo025', 'Davivienda', 'digital', 6325000.00),
  ('demo025', 'Efectivo', 'efectivo', 340000.00),
  ('demo026', 'Daviplata', 'corriente', 3085000.00),
  ('demo026', 'Bancolombia', 'digital', 0.00),
  ('demo027', 'Nequi', 'corriente', 2900000.00),
  ('demo027', 'Bancolombia', 'corriente', 0.00),
  ('demo027', 'Banco de Bogotá', 'digital', 915000.00),
  ('demo027', 'Efectivo', 'efectivo', 405000.00),
  ('demo028', 'Banco de Bogotá', 'digital', 4701000.00),
  ('demo028', 'BBVA', 'ahorros', 0.00),
  ('demo028', 'Efectivo', 'efectivo', 495000.00),
  ('demo029', 'Daviplata', 'corriente', 5875000.00),
  ('demo029', 'Bancolombia', 'ahorros', 300000.00),
  ('demo029', 'Nequi', 'digital', 3388000.00)
) AS v(usuario, banco, tipo, saldo)
JOIN users u ON u.usuario = v.usuario
WHERE a.user_id = u.id AND a.banco = v.banco AND a.tipo = v.tipo;

UPDATE accounts a SET
  saldo = v.saldo::numeric,
  actualizado_en = now()
FROM (VALUES
  ('demo029', 'Efectivo', 'efectivo', 95000.00),
  ('demo030', 'Davivienda', 'digital', 1327000.00),
  ('demo030', 'Bancolombia', 'ahorros', 1656000.00),
  ('demo031', 'BBVA', 'ahorros', 1020000.00),
  ('demo031', 'Bancolombia', 'ahorros', 2725000.00),
  ('demo031', 'Banco de Bogotá', 'digital', 108000.00),
  ('demo031', 'Efectivo', 'efectivo', 575000.00),
  ('demo032', 'BBVA', 'ahorros', 2526000.00),
  ('demo032', 'Daviplata', 'corriente', 5745000.00),
  ('demo032', 'Banco de Bogotá', 'corriente', 100000.00),
  ('demo032', 'Efectivo', 'efectivo', 235000.00),
  ('demo033', 'Nequi', 'digital', 6798000.00),
  ('demo033', 'Daviplata', 'ahorros', 0.00),
  ('demo033', 'BBVA', 'digital', 2075000.00),
  ('demo034', 'Bancolombia', 'corriente', 3321000.00),
  ('demo034', 'Davivienda', 'corriente', 1115000.00),
  ('demo035', 'Nequi', 'corriente', 2742000.00),
  ('demo035', 'Banco de Bogotá', 'digital', 0.00),
  ('demo035', 'BBVA', 'ahorros', 745000.00),
  ('demo036', 'Davivienda', 'corriente', 0.00),
  ('demo036', 'BBVA', 'digital', 3958000.00),
  ('demo036', 'Daviplata', 'digital', 30000.00),
  ('demo036', 'Efectivo', 'efectivo', 80000.00),
  ('demo037', 'Banco de Bogotá', 'ahorros', 195000.00),
  ('demo037', 'Nequi', 'digital', 1965000.00),
  ('demo037', 'Efectivo', 'efectivo', 480000.00),
  ('demo038', 'Daviplata', 'corriente', 1188000.00),
  ('demo038', 'Bancolombia', 'digital', 699000.00),
  ('demo038', 'Efectivo', 'efectivo', 395000.00),
  ('demo039', 'Nequi', 'digital', 0.00),
  ('demo039', 'Banco de Bogotá', 'digital', 5535000.00),
  ('demo039', 'BBVA', 'corriente', 10000.00),
  ('demo040', 'Banco de Bogotá', 'corriente', 105000.00),
  ('demo040', 'Daviplata', 'ahorros', 3440000.00),
  ('demo040', 'Nequi', 'corriente', 0.00),
  ('demo040', 'Efectivo', 'efectivo', 445000.00),
  ('demo041', 'Nequi', 'corriente', 970000.00),
  ('demo041', 'Davivienda', 'ahorros', 3455000.00),
  ('demo042', 'Bancolombia', 'ahorros', 3245000.00),
  ('demo042', 'Davivienda', 'digital', 889000.00),
  ('demo042', 'Efectivo', 'efectivo', 245000.00),
  ('demo043', 'Davivienda', 'corriente', 6062000.00),
  ('demo043', 'Nequi', 'ahorros', 168000.00),
  ('demo043', 'Banco de Bogotá', 'corriente', 2075000.00),
  ('demo043', 'Efectivo', 'efectivo', 375000.00),
  ('demo044', 'Nequi', 'ahorros', 2543000.00),
  ('demo044', 'Banco de Bogotá', 'digital', 0.00),
  ('demo044', 'Efectivo', 'efectivo', 315000.00),
  ('demo045', 'Nequi', 'corriente', 3489000.00),
  ('demo045', 'Davivienda', 'corriente', 0.00)
) AS v(usuario, banco, tipo, saldo)
JOIN users u ON u.usuario = v.usuario
WHERE a.user_id = u.id AND a.banco = v.banco AND a.tipo = v.tipo;

UPDATE accounts a SET
  saldo = v.saldo::numeric,
  actualizado_en = now()
FROM (VALUES
  ('demo045', 'BBVA', 'digital', 990000.00),
  ('demo045', 'Efectivo', 'efectivo', 405000.00),
  ('demo046', 'Daviplata', 'ahorros', 0.00),
  ('demo046', 'Davivienda', 'corriente', 2795000.00),
  ('demo046', 'Bancolombia', 'ahorros', 0.00),
  ('demo047', 'Nequi', 'ahorros', 195000.00),
  ('demo047', 'Banco de Bogotá', 'digital', 2743000.00),
  ('demo047', 'BBVA', 'corriente', 0.00),
  ('demo048', 'Bancolombia', 'digital', 0.00),
  ('demo048', 'Daviplata', 'ahorros', 1742000.00),
  ('demo048', 'Banco de Bogotá', 'digital', 0.00),
  ('demo049', 'Davivienda', 'ahorros', 3100000.00),
  ('demo049', 'Banco de Bogotá', 'ahorros', 0.00),
  ('demo049', 'Daviplata', 'corriente', 0.00),
  ('demo049', 'Efectivo', 'efectivo', 475000.00),
  ('demo050', 'Daviplata', 'digital', 3053000.00),
  ('demo050', 'Bancolombia', 'digital', 2888000.00),
  ('demo050', 'Banco de Bogotá', 'ahorros', 2600000.00),
  ('demo050', 'Efectivo', 'efectivo', 255000.00),
  ('demo051', 'Daviplata', 'ahorros', 1210000.00),
  ('demo051', 'BBVA', 'digital', 0.00),
  ('demo051', 'Davivienda', 'corriente', 1070000.00),
  ('demo052', 'Banco de Bogotá', 'ahorros', 904000.00),
  ('demo052', 'BBVA', 'digital', 0.00),
  ('demo052', 'Efectivo', 'efectivo', 355000.00),
  ('demo053', 'BBVA', 'ahorros', 4000.00),
  ('demo053', 'Nequi', 'corriente', 2005000.00),
  ('demo054', 'Daviplata', 'digital', 0.00),
  ('demo054', 'Davivienda', 'digital', 780000.00),
  ('demo054', 'BBVA', 'digital', 2830000.00),
  ('demo054', 'Efectivo', 'efectivo', 460000.00),
  ('demo055', 'Banco de Bogotá', 'ahorros', 3368000.00),
  ('demo055', 'Daviplata', 'corriente', 0.00),
  ('demo055', 'Efectivo', 'efectivo', 590000.00),
  ('demo056', 'BBVA', 'digital', 1062000.00),
  ('demo056', 'Nequi', 'corriente', 4630000.00),
  ('demo057', 'Bancolombia', 'ahorros', 1625000.00),
  ('demo057', 'BBVA', 'ahorros', 1526000.00),
  ('demo057', 'Efectivo', 'efectivo', 485000.00),
  ('demo058', 'Banco de Bogotá', 'corriente', 0.00),
  ('demo058', 'BBVA', 'corriente', 5732000.00),
  ('demo059', 'Bancolombia', 'digital', 267000.00),
  ('demo059', 'Daviplata', 'digital', 312000.00),
  ('demo059', 'Nequi', 'corriente', 155000.00),
  ('demo060', 'Bancolombia', 'digital', 0.00),
  ('demo060', 'BBVA', 'digital', 1481000.00),
  ('demo060', 'Efectivo', 'efectivo', 155000.00),
  ('demo061', 'Daviplata', 'ahorros', 3018000.00),
  ('demo061', 'Davivienda', 'digital', 120000.00),
  ('demo061', 'Efectivo', 'efectivo', 340000.00)
) AS v(usuario, banco, tipo, saldo)
JOIN users u ON u.usuario = v.usuario
WHERE a.user_id = u.id AND a.banco = v.banco AND a.tipo = v.tipo;

UPDATE accounts a SET
  saldo = v.saldo::numeric,
  actualizado_en = now()
FROM (VALUES
  ('demo062', 'Banco de Bogotá', 'ahorros', 655000.00),
  ('demo062', 'Nequi', 'ahorros', 275000.00),
  ('demo062', 'Efectivo', 'efectivo', 545000.00),
  ('demo063', 'BBVA', 'ahorros', 4980000.00),
  ('demo063', 'Daviplata', 'ahorros', 0.00),
  ('demo064', 'Davivienda', 'digital', 14000.00),
  ('demo064', 'Nequi', 'ahorros', 2725000.00),
  ('demo064', 'Bancolombia', 'ahorros', 180000.00),
  ('demo064', 'Efectivo', 'efectivo', 535000.00),
  ('demo065', 'Davivienda', 'digital', 12000.00),
  ('demo065', 'Bancolombia', 'corriente', 1073000.00),
  ('demo065', 'Efectivo', 'efectivo', 320000.00),
  ('demo066', 'Nequi', 'corriente', 3781000.00),
  ('demo066', 'Bancolombia', 'corriente', 0.00),
  ('demo066', 'Daviplata', 'corriente', 2970000.00),
  ('demo067', 'Davivienda', 'digital', 0.00),
  ('demo067', 'Nequi', 'ahorros', 1360000.00),
  ('demo067', 'Banco de Bogotá', 'ahorros', 0.00),
  ('demo067', 'Efectivo', 'efectivo', 445000.00),
  ('demo068', 'Bancolombia', 'corriente', 100000.00),
  ('demo068', 'BBVA', 'corriente', 35000.00),
  ('demo068', 'Banco de Bogotá', 'ahorros', 933000.00),
  ('demo068', 'Efectivo', 'efectivo', 325000.00),
  ('demo069', 'BBVA', 'corriente', 0.00),
  ('demo069', 'Davivienda', 'corriente', 1558000.00),
  ('demo069', 'Bancolombia', 'corriente', 0.00),
  ('demo069', 'Efectivo', 'efectivo', 230000.00),
  ('demo070', 'Daviplata', 'corriente', 4565000.00),
  ('demo070', 'Bancolombia', 'corriente', 0.00),
  ('demo070', 'Efectivo', 'efectivo', 335000.00),
  ('demo071', 'Davivienda', 'corriente', 0.00),
  ('demo071', 'BBVA', 'digital', 6782000.00),
  ('demo071', 'Banco de Bogotá', 'corriente', 0.00),
  ('demo072', 'Bancolombia', 'ahorros', 0.00),
  ('demo072', 'Nequi', 'ahorros', 1613000.00),
  ('demo072', 'Banco de Bogotá', 'corriente', 38000.00),
  ('demo072', 'Efectivo', 'efectivo', 415000.00),
  ('demo073', 'Daviplata', 'digital', 3950000.00),
  ('demo073', 'Banco de Bogotá', 'corriente', 0.00),
  ('demo073', 'Nequi', 'ahorros', 2075000.00),
  ('demo073', 'Efectivo', 'efectivo', 540000.00),
  ('demo074', 'BBVA', 'digital', 56000.00),
  ('demo074', 'Daviplata', 'ahorros', 2970000.00),
  ('demo074', 'Bancolombia', 'digital', 1238000.00),
  ('demo075', 'BBVA', 'corriente', 3145000.00),
  ('demo075', 'Bancolombia', 'digital', 1488000.00),
  ('demo075', 'Nequi', 'ahorros', 0.00),
  ('demo075', 'Efectivo', 'efectivo', 790000.00),
  ('demo076', 'Davivienda', 'digital', 5458000.00),
  ('demo076', 'Daviplata', 'digital', 0.00)
) AS v(usuario, banco, tipo, saldo)
JOIN users u ON u.usuario = v.usuario
WHERE a.user_id = u.id AND a.banco = v.banco AND a.tipo = v.tipo;

UPDATE accounts a SET
  saldo = v.saldo::numeric,
  actualizado_en = now()
FROM (VALUES
  ('demo076', 'Efectivo', 'efectivo', 380000.00),
  ('demo077', 'Daviplata', 'ahorros', 1817000.00),
  ('demo077', 'Banco de Bogotá', 'digital', 3505000.00),
  ('demo077', 'Efectivo', 'efectivo', 425000.00),
  ('demo078', 'Nequi', 'ahorros', 50000.00),
  ('demo078', 'Bancolombia', 'corriente', 104000.00),
  ('demo078', 'Davivienda', 'corriente', 2583000.00),
  ('demo078', 'Efectivo', 'efectivo', 210000.00),
  ('demo079', 'Bancolombia', 'digital', 1963000.00),
  ('demo079', 'Banco de Bogotá', 'ahorros', 0.00),
  ('demo079', 'BBVA', 'corriente', 30000.00),
  ('demo079', 'Efectivo', 'efectivo', 375000.00),
  ('demo080', 'BBVA', 'ahorros', 4680000.00),
  ('demo080', 'Bancolombia', 'corriente', 0.00),
  ('demo080', 'Efectivo', 'efectivo', 460000.00),
  ('demo081', 'Davivienda', 'corriente', 0.00),
  ('demo081', 'BBVA', 'corriente', 4412000.00),
  ('demo081', 'Bancolombia', 'corriente', 0.00),
  ('demo082', 'Bancolombia', 'ahorros', 1653000.00),
  ('demo082', 'Nequi', 'digital', 250000.00),
  ('demo082', 'Daviplata', 'corriente', 4355000.00),
  ('demo082', 'Efectivo', 'efectivo', 225000.00),
  ('demo083', 'Nequi', 'ahorros', 0.00),
  ('demo083', 'Daviplata', 'corriente', 735000.00),
  ('demo083', 'Bancolombia', 'digital', 105000.00),
  ('demo084', 'Davivienda', 'corriente', 3400000.00),
  ('demo084', 'Bancolombia', 'digital', 0.00),
  ('demo085', 'Banco de Bogotá', 'corriente', 0.00),
  ('demo085', 'Davivienda', 'corriente', 2014000.00),
  ('demo086', 'Daviplata', 'ahorros', 2895000.00),
  ('demo086', 'Davivienda', 'ahorros', 200000.00),
  ('demo086', 'BBVA', 'ahorros', 650000.00),
  ('demo086', 'Efectivo', 'efectivo', 395000.00),
  ('demo087', 'Daviplata', 'ahorros', 831000.00),
  ('demo087', 'Davivienda', 'corriente', 0.00),
  ('demo087', 'Efectivo', 'efectivo', 200000.00),
  ('demo088', 'Daviplata', 'ahorros', 705000.00),
  ('demo088', 'Nequi', 'digital', 1062000.00),
  ('demo088', 'Efectivo', 'efectivo', 245000.00),
  ('demo089', 'Bancolombia', 'corriente', 0.00),
  ('demo089', 'Daviplata', 'digital', 2145000.00),
  ('demo089', 'Banco de Bogotá', 'corriente', 2769000.00),
  ('demo090', 'Bancolombia', 'corriente', 3955000.00),
  ('demo090', 'Davivienda', 'ahorros', 72000.00),
  ('demo090', 'Nequi', 'corriente', 3205000.00),
  ('demo091', 'Banco de Bogotá', 'corriente', 0.00),
  ('demo091', 'BBVA', 'ahorros', 4625000.00),
  ('demo091', 'Efectivo', 'efectivo', 270000.00),
  ('demo092', 'Bancolombia', 'ahorros', 1980000.00),
  ('demo092', 'BBVA', 'ahorros', 25000.00)
) AS v(usuario, banco, tipo, saldo)
JOIN users u ON u.usuario = v.usuario
WHERE a.user_id = u.id AND a.banco = v.banco AND a.tipo = v.tipo;

UPDATE accounts a SET
  saldo = v.saldo::numeric,
  actualizado_en = now()
FROM (VALUES
  ('demo092', 'Nequi', 'corriente', 1840000.00),
  ('demo093', 'BBVA', 'digital', 4713000.00),
  ('demo093', 'Banco de Bogotá', 'corriente', 1577000.00),
  ('demo093', 'Efectivo', 'efectivo', 385000.00),
  ('demo094', 'Daviplata', 'ahorros', 0.00),
  ('demo094', 'Bancolombia', 'corriente', 405000.00),
  ('demo094', 'Efectivo', 'efectivo', 345000.00),
  ('demo095', 'Daviplata', 'corriente', 0.00),
  ('demo095', 'Bancolombia', 'ahorros', 4240000.00),
  ('demo096', 'Bancolombia', 'ahorros', 60000.00),
  ('demo096', 'Davivienda', 'ahorros', 5120000.00),
  ('demo096', 'Efectivo', 'efectivo', 345000.00),
  ('demo097', 'Bancolombia', 'corriente', 0.00),
  ('demo097', 'BBVA', 'ahorros', 0.00),
  ('demo097', 'Davivienda', 'digital', 6150000.00),
  ('demo097', 'Efectivo', 'efectivo', 235000.00),
  ('demo098', 'Daviplata', 'ahorros', 5025000.00),
  ('demo098', 'Davivienda', 'corriente', 0.00),
  ('demo098', 'Efectivo', 'efectivo', 400000.00),
  ('demo099', 'Daviplata', 'corriente', 338000.00),
  ('demo099', 'Bancolombia', 'corriente', 175000.00),
  ('demo100', 'Daviplata', 'ahorros', 0.00),
  ('demo100', 'Bancolombia', 'digital', 0.00),
  ('demo100', 'Davivienda', 'ahorros', 2831000.00),
  ('demo100', 'Efectivo', 'efectivo', 225000.00)
) AS v(usuario, banco, tipo, saldo)
JOIN users u ON u.usuario = v.usuario
WHERE a.user_id = u.id AND a.banco = v.banco AND a.tipo = v.tipo;

SELECT setval(pg_get_serial_sequence('users', 'id'), COALESCE((SELECT MAX(id) FROM users), 1));
SELECT setval(pg_get_serial_sequence('accounts', 'id'), COALESCE((SELECT MAX(id) FROM accounts), 1));
SELECT setval(pg_get_serial_sequence('counterparties', 'id'), COALESCE((SELECT MAX(id) FROM counterparties), 1));
SELECT setval(pg_get_serial_sequence('transactions', 'id'), COALESCE((SELECT MAX(id) FROM transactions), 1));
SELECT setval(pg_get_serial_sequence('categories', 'id'), COALESCE((SELECT MAX(id) FROM categories), 1));
SELECT setval(pg_get_serial_sequence('sub_categories', 'id'), COALESCE((SELECT MAX(id) FROM sub_categories), 1));

COMMIT;

-- Verification:
-- SELECT COUNT(*) FROM users WHERE correo LIKE 'demo%@example.com';
-- SELECT COUNT(*) FROM accounts a JOIN users u ON u.id = a.user_id WHERE u.correo LIKE 'demo%@example.com';
-- SELECT COUNT(*) FROM transactions t JOIN accounts a ON a.id = t.account_id JOIN users u ON u.id = a.user_id WHERE u.correo LIKE 'demo%@example.com';
