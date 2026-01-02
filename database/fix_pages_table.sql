
-- 1. Ensure columns exist (Idempotent)
alter table public.pages add column if not exists slug text unique;
alter table public.pages add column if not exists title text;
alter table public.pages add column if not exists meta_description text;
alter table public.pages add column if not exists is_published boolean default true;
alter table public.pages add column if not exists order_index integer default 0;

-- 2. Ensure RLS is enabled
alter table public.pages enable row level security;

-- 3. Reset Policies (Fixes permissions for INSERT)
drop policy if exists "Public pages are viewable by everyone" on public.pages;
create policy "Public pages are viewable by everyone" on public.pages
  for select using (is_published = true);

drop policy if exists "Auth users can do everything on pages" on public.pages;
create policy "Auth users can do everything on pages" on public.pages
  for all using (auth.role() = 'authenticated');

-- 4. Insert defaults (if not present)
insert into public.pages (slug, title, order_index)
values 
('home', 'Accueil', 0),
('about', 'À propos', 1)
on conflict (slug) do nothing;
