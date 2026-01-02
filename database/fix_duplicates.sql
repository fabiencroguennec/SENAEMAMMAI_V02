-- 0. Drop constraint if it exists (to allow cleaning)
alter table ui_config drop constraint if exists ui_config_section_id_key;

-- 1. Remove duplicates, keeping the most recent one (highest ID)
delete from ui_config a using ui_config b
where a.section_id = b.section_id
and a.id < b.id;

-- 2. Add Unique Constraint to prevent future duplicates
alter table ui_config
add constraint ui_config_section_id_key unique (section_id);
