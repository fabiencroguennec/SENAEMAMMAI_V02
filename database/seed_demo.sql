-- ==========================================
-- SEED DATA: Visual Builder Demo
-- ==========================================

-- Clean up previous demo data to avoid duplicates (optional, safe for dev)
delete from public.ui_config where section_id in (select id from public.page_sections where page_slug = 'home');
delete from public.page_sections where page_slug = 'home';

-- 1. Insert Hero Section
with new_section as (
  insert into public.page_sections (
    page_slug, 
    component_type, 
    order_index, 
    content_data, 
    is_visible
  ) values (
    'home',
    'HeroSection',
    0,
    '{
      "title": "SENAEMAMMAI",
      "subtitle": "L''authenticité de la Sardaigne, réinventée.",
      "imageUrl": "https://images.unsplash.com/photo-1625902368307-28d88fa7cc82?q=80&w=2600&auto=format&fit=crop",
      "ctaText": "Découvrir nos terres",
      "ctaLink": "/about"
    }'::jsonb,
    true
  )
  returning id
)
-- 2. Insert UI Config for the Hero
insert into public.ui_config (
  section_id,
  animation_type,
  animation_speed,
  parallax_intensity,
  background_color,
  theme_variant
)
select 
  id,
  'parallax',
  1.0,
  0.5,
  'bg-gray-900',
  'dark'
from new_section;

-- 3. Insert specific Product Grid (Example for future component)
-- with new_grid as (
--   insert into public.page_sections (
--     page_slug, component_type, order_index, content_data
--   ) values (
--     'home', 'ProductGrid', 1, '{"title": "Nos Produits Phares", "limit": 4}'::jsonb
--   ) returning id
-- )
-- insert into public.ui_config (section_id, animation_type)
-- select id, 'fade-up' from new_grid;

