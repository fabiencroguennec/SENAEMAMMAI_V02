-- Add columns for Background Textures and Video Scroll Scrubbing
ALTER TABLE public.ui_config 
ADD COLUMN IF NOT EXISTS overlay_texture text DEFAULT 'none', -- 'none', 'noise', 'dots', 'grid', 'lines'
ADD COLUMN IF NOT EXISTS video_scroll_scrub boolean DEFAULT false;
