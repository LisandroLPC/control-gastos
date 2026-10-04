-- ══════════════════════════════════════════════════════════════
-- CONTROL DE GASTOS — PARTE 2: SEGURIDAD
-- Correr RECIÉN cuando ya iniciaste sesión en la app nueva en tus dispositivos.
-- ══════════════════════════════════════════════════════════════
begin;
do $$
declare t text;
begin
  foreach t in array array['movimientos','categorias','config','gastos_fijos'] loop
    execute format('alter table public.%I enable row level security', t);
    execute format('drop policy if exists solo_yo on public.%I', t);
    execute format('create policy solo_yo on public.%I for all to authenticated using (true) with check (true)', t);
    execute format('revoke all on public.%I from anon', t);
  end loop;
end $$;
commit;

-- Control: 4 filas con rls = true y anon_puede = false
select c.relname tabla, c.relrowsecurity rls, has_table_privilege('anon', c.oid, 'select') anon_puede
from pg_class c join pg_namespace n on n.oid=c.relnamespace
where n.nspname='public' and c.relkind='r' order by 1;

-- MARCHA ATRÁS (solo si algo sale mal):
-- do $$ declare t text; begin foreach t in array array['movimientos','categorias','config','gastos_fijos'] loop
--   execute format('alter table public.%I disable row level security', t); execute format('grant all on public.%I to anon', t);
-- end loop; end $$;
