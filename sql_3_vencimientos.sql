-- CONTROL DE GASTOS — PARTE 3: día de vencimiento de los gastos fijos (no modifica datos)
alter table gastos_fijos add column if not exists dia_vencimiento int check (dia_vencimiento between 1 and 31);
select nombre, monto, dia_vencimiento from gastos_fijos order by orden;
