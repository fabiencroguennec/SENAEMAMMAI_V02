-- Create a table for global site appearance settings
CREATE TABLE IF NOT EXISTS public.site_appearance (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    site_slug TEXT UNIQUE NOT NULL DEFAULT 'main',
    colors JSONB DEFAULT '{
        "primary": "#3b82f6",
        "secondary": "#64748b",
        "background": "#020617",
        "text": "#f8fafc",
        "accent": "#f59e0b"
    }'::jsonb,
    typography JSONB DEFAULT '{
        "h1": { "size": "3rem", "weight": "700", "family": "Inter, sans-serif" },
        "h2": { "size": "2.25rem", "weight": "600", "family": "Inter, sans-serif" },
        "h3": { "size": "1.5rem", "weight": "600", "family": "Inter, sans-serif" },
        "p": { "size": "1rem", "weight": "400", "family": "Inter, sans-serif" },
        "font_body": "Inter, sans-serif",
        "font_heading": "Inter, sans-serif"
    }'::jsonb,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Enable RLS
ALTER TABLE public.site_appearance ENABLE ROW LEVEL SECURITY;

-- Create Policies
CREATE POLICY "Public Read Access" 
ON public.site_appearance FOR SELECT 
USING (true);

CREATE POLICY "Admin Update Access" 
ON public.site_appearance FOR UPDATE
USING (true)
WITH CHECK (true); -- Ideally restrict to authenticated users in prod

CREATE POLICY "Admin Insert Access" 
ON public.site_appearance FOR INSERT
WITH CHECK (true); 

-- Seed default appearance if not exists
INSERT INTO public.site_appearance (site_slug)
VALUES ('main')
ON CONFLICT (site_slug) DO NOTHING;
