-- ==========================================
-- SEED DATA: Products & Grid
-- ==========================================

-- 1. Insert Dummy Products
insert into public.products (name, description, sku, price, stock_quantity, attributes)
values 
(
  'Huile d''Olive Extra Vierge (500ml)',
  'Une huile pressée à froid, issue d''oliviers centenaires de la région de Alghero. Notes fruitées et ardentes.',
  'OIL-500',
  18.50,
  100,
  '{"imageUrl": "https://images.unsplash.com/photo-1595123550441-d377e017de6a?q=80&w=1000&auto=format&fit=crop"}'::jsonb
),
(
  'Miel de Maquis Sarde',
  'Miel sauvage récolté au printemps. Goût intense aux arômes de romarin et de myrte.',
  'HONEY-250',
  12.00,
  50,
  '{"imageUrl": "https://images.unsplash.com/photo-1587049352846-4a222e784d38?q=80&w=1000&auto=format&fit=crop"}'::jsonb
),
(
  'Pecorino Affiné (300g)',
  'Fromage de brebis AOP, affiné pendant 6 mois dans nos caves naturelles.',
  'CHEESE-PEC',
  9.80,
  30,
  '{"imageUrl": "https://images.unsplash.com/photo-1624806992066-5ffcf7ca186b?q=80&w=1000&auto=format&fit=crop"}'::jsonb
)
ON CONFLICT (sku) DO UPDATE 
SET attributes = EXCLUDED.attributes;

-- 2. Add Product Grid Section to Home (Only if not exists)
do $$
declare
  v_section_id uuid;
begin
  if not exists (select 1 from public.page_sections where page_slug = 'home' and component_type = 'ProductGrid') then
    insert into public.page_sections (
      page_slug, 
      component_type, 
      order_index, 
      content_data, 
      is_visible
    ) values (
      'home',
      'ProductGrid',
      10,
      '{
        "title": "Nos Trésors Culinaires",
        "subtitle": "Découvrez les saveurs authentiques produites sur notre domaine.",
        "limit": 3
      }'::jsonb,
      true
    )
    returning id into v_section_id;

    -- 3. Add UI Config
    insert into public.ui_config (
      section_id,
      animation_type,
      animation_speed,
      background_color
    )
    values (
      v_section_id,
      'fade-up',
      0.8,
      'bg-white dark:bg-gray-900'
    );
  end if;
end $$;
