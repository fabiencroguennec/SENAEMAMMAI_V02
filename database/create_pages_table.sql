
-- Create pages table for structure management
create table public.pages (
  id uuid primary key default uuid_generate_v4(),
  created_at timestamp with time zone default timezone('utc'::text, now()) not null,
  slug text unique not null,
  title text not null,
  meta_description text,
  is_published boolean default true,
  order_index integer default 0
);

-- Enable RLS
alter table public.pages enable row level security;

-- Policies
create policy "Public pages are viewable by everyone" on public.pages
  for select using (is_published = true);

create policy "Auth users can do everything on pages" on public.pages
  for all using (auth.role() = 'authenticated');

-- Insert default pages if they don't exist
insert into public.pages (slug, title, order_index)
values 
('home', 'Accueil', 0),
('about', 'À propos', 1)
on conflict (slug) do nothing;
