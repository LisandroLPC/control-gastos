-- ══════════════════════════════════════════════════════════════
-- CONTROL DE GASTOS v2 — PARTE 1: ESTRUCTURA (correr ANTES de usar la app nueva)
-- No borra ni modifica ningún movimiento cargado. Se puede correr más de una vez.
-- ══════════════════════════════════════════════════════════════
begin;

-- 1) Nuevo tipo de movimiento: "ahorro" = uso de ahorros (ej: vender dólares para pagar algo)
alter table movimientos drop constraint if exists movimientos_tipo_check;
alter table movimientos add constraint movimientos_tipo_check check (tipo in ('gasto','ingreso','ahorro'));
alter table categorias drop constraint if exists categorias_tipo_check;
alter table categorias add constraint categorias_tipo_check check (tipo in ('gasto','ingreso','ahorro'));
insert into categorias (tipo, nombre) values ('ahorro','Dólares'), ('ahorro','Pesos ahorrados'), ('gasto','Préstamo')
  on conflict (tipo, nombre) do nothing;

-- 2) Gastos divididos: las 2 partes comparten el mismo "grupo"
alter table movimientos add column if not exists grupo text;

-- 3) Configuración (tope de sueldo mensual)
create table if not exists config (
  clave text primary key,
  valor jsonb not null,
  updated_at timestamptz default now()
);
insert into config (clave, valor) values ('tope_sueldo', '1350000') on conflict (clave) do nothing;

-- 4) Gastos fijos + vínculo de cada pago con su gasto fijo
create table if not exists gastos_fijos (
  id bigint generated always as identity primary key,
  nombre text not null,
  monto numeric not null default 0,
  categoria text,
  activo boolean default true,
  orden int default 0,
  created_at timestamptz default now()
);
alter table movimientos add column if not exists fijo_id bigint references gastos_fijos(id) on delete set null;

-- Carga inicial (solo si la lista está vacía). Montos aproximados: se editan desde la app.
insert into gastos_fijos (nombre, monto, categoria, orden)
select * from (values
  ('Alquiler depto', 370000, 'Alquiler', 1),
  ('Obra social', 390000, 'Salud y belleza', 2),
  ('Tarjeta Visa', 350000, 'Tarjeta de crédito', 3),
  ('Préstamo Banco Río', 160000, 'Préstamo', 4),
  ('Seguro auto', 90000, 'Transporte', 5),
  ('Servicios (luz, gas, agua)', 39000, 'Servicios', 6),
  ('Internet', 30000, 'Servicios', 7)
) v(nombre, monto, categoria, orden)
where not exists (select 1 from gastos_fijos);

-- Hasta activar la seguridad (Parte 2), las tablas nuevas quedan igual que las viejas
alter table config disable row level security;
alter table gastos_fijos disable row level security;

commit;

-- Control: tiene que devolver 4 filas con "ok"
select 'tipo ahorro' que, case when exists (select 1 from categorias where tipo='ahorro') then 'ok' else 'FALTA' end estado
union all select 'movimientos.grupo / fijo_id', case when (select count(*) from information_schema.columns where table_name='movimientos' and column_name in ('grupo','fijo_id'))=2 then 'ok' else 'FALTA' end
union all select 'tabla config', case when exists (select 1 from config where clave='tope_sueldo') then 'ok' else 'FALTA' end
union all select 'tabla gastos_fijos', case when exists (select 1 from gastos_fijos) then 'ok' else 'FALTA' end;
