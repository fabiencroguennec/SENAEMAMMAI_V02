/**
 * Enable Realtime for Visual Builder tables.
 * Run this in Supabase SQL Editor.
 */

begin;

  -- Add tables to the supabase_realtime publication
  alter publication supabase_realtime add table page_sections;
  alter publication supabase_realtime add table ui_config;

commit;
