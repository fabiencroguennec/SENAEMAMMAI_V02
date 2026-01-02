ALTER TABLE ui_config ADD COLUMN IF NOT EXISTS gradient_config JSONB DEFAULT '{}'::jsonb;
