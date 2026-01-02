-- Enable necessary extensions
create extension if not exists "uuid-ossp";

-- ==========================================
-- 1. ERP / GESTION TABLES
-- ==========================================

-- Contacts: People, Suppliers, Customers, Team Members
create type contact_type as enum ('individual', 'company', 'employee', 'supplier');

create table public.contacts (
  id uuid primary key default uuid_generate_v4(),
  created_at timestamp with time zone default timezone('utc'::text, now()) not null,
  updated_at timestamp with time zone default timezone('utc'::text, now()) not null,
  full_name text not null,
  email text,
  phone text,
  type contact_type default 'individual' not null,
  profile_data jsonb default '{}'::jsonb, -- Flexible fields for specific addresses, preferences, etc.
  user_id uuid references auth.users(id) -- Optional link to Supabase Auth user if they have a login
);

-- Products: Items for sale or internal stock
create table public.products (
  id uuid primary key default uuid_generate_v4(),
  created_at timestamp with time zone default timezone('utc'::text, now()) not null,
  updated_at timestamp with time zone default timezone('utc'::text, now()) not null,
  name text not null,
  description text,
  sku text unique,
  price decimal(10, 2),
  stock_quantity integer default 0,
  supplier_id uuid references public.contacts(id),
  attributes jsonb default '{}'::jsonb -- Flexible fields: weight, dimensions, custom properties
);

-- Activities: Agrotourism events/activities
create table public.activities (
  id uuid primary key default uuid_generate_v4(),
  created_at timestamp with time zone default timezone('utc'::text, now()) not null,
  updated_at timestamp with time zone default timezone('utc'::text, now()) not null,
  title text not null,
  description text,
  start_date timestamp with time zone,
  end_date timestamp with time zone,
  max_participants integer,
  facilitator_id uuid references public.contacts(id),
  location_data jsonb default '{}'::jsonb
);

-- Semantic Relationships: Linking entities for "Graph" navigation
create table public.semantic_relationships (
  id uuid primary key default uuid_generate_v4(),
  created_at timestamp with time zone default timezone('utc'::text, now()) not null,
  source_id uuid not null, -- Can be product_id, contact_id, post_id, etc.
  target_id uuid not null,
  relation_type text not null, -- e.g., 'facilitates', 'produces', 'related_to'
  metadata jsonb default '{}'::jsonb
);
-- Note: In a real implementation, you might want polymorphic associations or separate join tables if strict referential integrity is required between specific tables.
-- For a semantic web approach, ID-to-ID with application-level logic is flexible.

-- ==========================================
-- 2. CMS Tables (Blog)
-- ==========================================

create table public.posts (
  id uuid primary key default uuid_generate_v4(),
  created_at timestamp with time zone default timezone('utc'::text, now()) not null,
  updated_at timestamp with time zone default timezone('utc'::text, now()) not null,
  title text not null,
  slug text unique not null,
  content text, -- Markdown or HTML
  excerpt text,
  cover_image_url text,
  published_at timestamp with time zone,
  is_published boolean default false,
  author_id uuid references public.contacts(id)
);

-- ==========================================
-- 3. VISUAL BUILDER / UI TABLES
-- ==========================================

-- Page Sections: Ordered blocks for constructing pages
create table public.page_sections (
  id uuid primary key default uuid_generate_v4(),
  created_at timestamp with time zone default timezone('utc'::text, now()) not null,
  page_slug text default 'home' not null, -- Which page this section belongs to
  component_type text not null, -- Maps to Nuxt component name (e.g. 'HeroSection', 'ProductGrid')
  order_index integer default 0 not null,
  content_data jsonb default '{}'::jsonb, -- The actual content: headings, text, image URLs
  is_visible boolean default true
);

-- UI Config: Animation and style settings for sections
create table public.ui_config (
  id uuid primary key default uuid_generate_v4(),
  section_id uuid references public.page_sections(id) on delete cascade unique, -- One config per section
  animation_type text, -- e.g., 'fade-up', 'zoom-in', 'parallax'
  animation_speed float default 1.0, -- Multiplier
  parallax_intensity float default 0.0, -- 0 to 1
  background_color text, -- hex or tailwind class
  custom_classes text, -- Extra Tailwind classes override
  theme_variant text default 'default' -- 'dark', 'light', 'glass'
);

-- ==========================================
-- RLS (Row Level Security) - Basic Setup
-- ==========================================

-- Enable RLS
alter table public.contacts enable row level security;
alter table public.products enable row level security;
alter table public.activities enable row level security;
alter table public.semantic_relationships enable row level security;
alter table public.posts enable row level security;
alter table public.page_sections enable row level security;
alter table public.ui_config enable row level security;

-- Policies (Examples - Adjust for production)

-- Public read access for published content
create policy "Public posts are viewable by everyone" on public.posts
  for select using (is_published = true);

create policy "Public sections are viewable by everyone" on public.page_sections
  for select using (is_visible = true);

create policy "Public ui_config is viewable by everyone" on public.ui_config
  for select using (true);

create policy "Public products are viewable by everyone" on public.products
  for select using (true); 

-- Full access for authenticated admins (Assuming Supabase Auth)
-- This assumes you have logic to determine who is an admin, possibly a claim or a table.
-- For simplicity here, we allow authenticated users to do everything (DEV MODE).
-- REPLACE with proper admin check in production.
create policy "Auth users can do everything" on public.contacts for all using (auth.role() = 'authenticated');
create policy "Auth users can do everything" on public.products for all using (auth.role() = 'authenticated');
create policy "Auth users can do everything" on public.activities for all using (auth.role() = 'authenticated');
create policy "Auth users can do everything" on public.semantic_relationships for all using (auth.role() = 'authenticated');
create policy "Auth users can do everything" on public.posts for all using (auth.role() = 'authenticated');
create policy "Auth users can do everything" on public.page_sections for all using (auth.role() = 'authenticated');
create policy "Auth users can do everything" on public.ui_config for all using (auth.role() = 'authenticated');
