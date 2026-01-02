-- Add missing columns to ui_config table
ALTER TABLE public.ui_config 
ADD COLUMN IF NOT EXISTS background_type text DEFAULT 'color',
ADD COLUMN IF NOT EXISTS background_value text,
ADD COLUMN IF NOT EXISTS overlay_opacity float DEFAULT 0.5;

-- Update existing rows to have sensible defaults if needed
UPDATE public.ui_config 
SET background_type = 'color' 
WHERE background_type IS NULL;

-- Ensure schema cache is reloaded
NOTIFY pgrst, 'reload schema';
