-- Enable RLS on tables (if not already)
alter table page_sections enable row level security;
alter table ui_config enable row level security;

-- Drop existing policies to start fresh
drop policy if exists "Enable access for all users" on page_sections;
drop policy if exists "Enable access for all users" on ui_config;

-- Create PERMISSIVE policies for Development (Anon + Authenticated)
create policy "Enable access for all users"
on page_sections
for all
using (true)
with check (true);

create policy "Enable access for all users"
on ui_config
for all
using (true)
with check (true);

-- Verify
select * from page_sections limit 1;
