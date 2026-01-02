-- Add background_timeline_config column for independent background animations
ALTER TABLE ui_config 
ADD COLUMN IF NOT EXISTS background_timeline_config JSONB DEFAULT '{}'::jsonb;

-- Comment for documentation
COMMENT ON COLUMN ui_config.background_timeline_config IS 'Configuration for Background GSAP Scroll Timeline (start/active/end)';
