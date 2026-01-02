-- Add timeline_config column for scroll animations
ALTER TABLE ui_config 
ADD COLUMN IF NOT EXISTS timeline_config JSONB DEFAULT '{}'::jsonb;

-- Comment for documentation
COMMENT ON COLUMN ui_config.timeline_config IS 'Configuration for GSAP Scroll Timeline (start/active/end keyframes)';
