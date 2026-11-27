-- =====================================================================
-- Nexotik · base de datos en Supabase
-- Pégalo completo en Supabase → SQL Editor → New query → Run.
-- Se puede ejecutar más de una vez sin dañar nada.
-- =====================================================================

-- ---------- tablas ----------
create table if not exists public.ordenes (
  id          text primary key,
  num         text not null unique,
  codigo      text not null,
  data        jsonb not null,
  updated_at  timestamptz not null default now()
);

create table if not exists public.gastos (
  id          text primary key,
  data        jsonb not null,
  updated_at  timestamptz not null default now()
);

create table if not exists public.ajustes (
  id          int primary key default 1 check (id = 1),
  data        jsonb not null,
  updated_at  timestamptz not null default now()
);

-- Quién puede entrar al panel de órdenes (solo tú).
create table if not exists public.admins (
  user_id uuid primary key references auth.users(id) on delete cascade
);

-- ---------- ¿el usuario conectado es administrador? ----------
create or replace function public.es_admin()
returns boolean
language sql stable security definer set search_path = public
as $$
  select exists (select 1 from public.admins where user_id = auth.uid());
$$;

-- ---------- seguridad: nadie ve nada salvo el administrador ----------
alter table public.ordenes enable row level security;
alter table public.gastos  enable row level security;
alter table public.ajustes enable row level security;
alter table public.admins  enable row level security;

drop policy if exists "admin ordenes" on public.ordenes;
create policy "admin ordenes" on public.ordenes
  for all to authenticated using (public.es_admin()) with check (public.es_admin());

drop policy if exists "admin gastos" on public.gastos;
create policy "admin gastos" on public.gastos
  for all to authenticated using (public.es_admin()) with check (public.es_admin());

drop policy if exists "admin ajustes" on public.ajustes;
create policy "admin ajustes" on public.ajustes
  for all to authenticated using (public.es_admin()) with check (public.es_admin());

drop policy if exists "ver mi admin" on public.admins;
create policy "ver mi admin" on public.admins
  for select to authenticated using (user_id = auth.uid());

revoke all on public.ordenes, public.gastos, public.ajustes, public.admins from anon;

-- ---------- consulta pública del cliente ----------
-- El cliente da el número de orden y su código. Solo recibe lo necesario:
-- nunca la contraseña del equipo, documento, teléfono, correo ni notas internas.
create or replace function public.consultar_orden(p_num text, p_codigo text)
returns jsonb
language plpgsql stable security definer set search_path = public
as $$
declare
  o   jsonb;
  s   jsonb;
  tot numeric;
  pag numeric;
begin
  if p_num is null or p_codigo is null or length(p_codigo) < 4 then
    return null;
  end if;

  select data into o from public.ordenes
   where upper(num) = upper(trim(p_num))
     and upper(codigo) = upper(trim(p_codigo));
  if o is null then
    return null;
  end if;

  select data into s from public.ajustes where id = 1;

  select coalesce(sum(nullif(i->>'valor','')::numeric), 0) into tot
    from jsonb_array_elements(coalesce(o->'items','[]'::jsonb)) i;
  select coalesce(sum(nullif(p->>'valor','')::numeric), 0) into pag
    from jsonb_array_elements(coalesce(o->'pagos','[]'::jsonb)) p;

  return jsonb_build_object(
    'num',         o->>'num',
    'estado',      o->>'estado',
    'cliente',     split_part(coalesce(o#>>'{cliente,nombre}',''), ' ', 1),
    'recibido',    o->>'recibido',
    'entrega',     o->>'entrega',
    'entregadoEn', o->>'entregadoEn',
    'equipo',      jsonb_build_object(
                     'tipo',   o#>>'{equipo,tipo}',
                     'marca',  o#>>'{equipo,marca}',
                     'modelo', o#>>'{equipo,modelo}'),
    'falla',       o->>'falla',
    'diagnostico', o->>'diagnostico',
    'items',       coalesce((select jsonb_agg(jsonb_build_object(
                       'servicio', coalesce(i->>'servicio', i->>'tipo'),
                       'desc',     i->>'desc',
                       'valor',    nullif(i->>'valor','')::numeric))
                     from jsonb_array_elements(coalesce(o->'items','[]'::jsonb)) i), '[]'::jsonb),
    'pagos',       coalesce((select jsonb_agg(jsonb_build_object(
                       'fecha', p->>'fecha',
                       'valor', nullif(p->>'valor','')::numeric))
                     from jsonb_array_elements(coalesce(o->'pagos','[]'::jsonb)) p), '[]'::jsonb),
    'total',       tot,
    'pagado',      pag,
    'saldo',       case when o->>'estado' = 'cancelado' then 0 else tot - pag end,
    'garantia',    coalesce(nullif(s->>'garantia','')::int, 30),
    'telefono',    s->>'telefono'
  );
end;
$$;

revoke all on function public.consultar_orden(text, text) from public;
grant execute on function public.consultar_orden(text, text) to anon, authenticated;
revoke all on function public.es_admin() from public, anon;
grant execute on function public.es_admin() to authenticated;
