-- Run this entire file in Supabase > SQL Editor.

create extension if not exists pgcrypto;

create table if not exists public.admins (
  user_id uuid primary key references auth.users(id) on delete cascade,
  created_at timestamptz not null default now()
);

create table if not exists public.products (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  brand text,
  size text,
  price numeric(12,2) not null check (price >= 0),
  old_price numeric(12,2) check (old_price is null or old_price >= 0),
  type text not null default 'own' check (type in ('own','imp')),
  description text,
  image_url text,
  created_at timestamptz not null default now()
);

create table if not exists public.orders (
  id uuid primary key default gen_random_uuid(),
  product_id uuid not null references public.products(id) on delete restrict,
  customer_name text not null,
  phone text not null,
  address text not null,
  quantity integer not null default 1 check (quantity > 0 and quantity <= 50),
  note text,
  status text not null default 'new' check (status in ('new','confirmed','shipped','done','cancelled')),
  created_at timestamptz not null default now()
);

alter table public.admins enable row level security;
alter table public.products enable row level security;
alter table public.orders enable row level security;

create or replace function public.is_admin()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1 from public.admins where user_id = auth.uid()
  );
$$;

revoke all on function public.is_admin() from public;
grant execute on function public.is_admin() to anon, authenticated;

-- ADMIN membership: only the signed-in account may read its own admin row.
drop policy if exists admins_select_own on public.admins;
create policy admins_select_own on public.admins
for select to authenticated
using (user_id = auth.uid());

-- PRODUCTS: everyone can view; only admins can change them.
drop policy if exists products_public_read on public.products;
create policy products_public_read on public.products
for select to anon, authenticated using (true);

drop policy if exists products_admin_insert on public.products;
create policy products_admin_insert on public.products
for insert to authenticated with check (public.is_admin());

drop policy if exists products_admin_update on public.products;
create policy products_admin_update on public.products
for update to authenticated using (public.is_admin()) with check (public.is_admin());

drop policy if exists products_admin_delete on public.products;
create policy products_admin_delete on public.products
for delete to authenticated using (public.is_admin());

-- ORDERS: visitors can create orders; only admins can see or update them.
drop policy if exists orders_public_insert on public.orders;
create policy orders_public_insert on public.orders
for insert to anon, authenticated with check (true);

drop policy if exists orders_admin_read on public.orders;
create policy orders_admin_read on public.orders
for select to authenticated using (public.is_admin());

drop policy if exists orders_admin_update on public.orders;
create policy orders_admin_update on public.orders
for update to authenticated using (public.is_admin()) with check (public.is_admin());

drop policy if exists orders_admin_delete on public.orders;
create policy orders_admin_delete on public.orders
for delete to authenticated using (public.is_admin());

-- Storage bucket for product photos.
insert into storage.buckets (id, name, public)
values ('product-images', 'product-images', true)
on conflict (id) do nothing;

drop policy if exists product_images_public_read on storage.objects;
create policy product_images_public_read on storage.objects
for select to public
using (bucket_id = 'product-images');

drop policy if exists product_images_admin_insert on storage.objects;
create policy product_images_admin_insert on storage.objects
for insert to authenticated
with check (bucket_id = 'product-images' and public.is_admin());

drop policy if exists product_images_admin_update on storage.objects;
create policy product_images_admin_update on storage.objects
for update to authenticated
using (bucket_id = 'product-images' and public.is_admin())
with check (bucket_id = 'product-images' and public.is_admin());

drop policy if exists product_images_admin_delete on storage.objects;
create policy product_images_admin_delete on storage.objects
for delete to authenticated
using (bucket_id = 'product-images' and public.is_admin());

-- After creating your admin account in Supabase Authentication, run:
-- insert into public.admins (user_id) values ('YOUR-AUTH-USER-UUID');
