-- Create Animation Presets Table
CREATE TABLE IF NOT EXISTS animation_presets (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    config JSONB NOT NULL,
    is_system BOOLEAN DEFAULT FALSE, -- To distinguish built-in presets
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Enable RLS
ALTER TABLE animation_presets ENABLE ROW LEVEL SECURITY;

-- Policies
DO $$ 
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'animation_presets' AND policyname = 'Public Read Presets') THEN
        CREATE POLICY "Public Read Presets" ON animation_presets FOR SELECT USING (true);
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'animation_presets' AND policyname = 'Public Insert Presets') THEN
        CREATE POLICY "Public Insert Presets" ON animation_presets FOR INSERT WITH CHECK (true);
    END IF;
END $$;

-- Clean old system presets to avoid duplicates on re-run
DELETE FROM animation_presets WHERE is_system = TRUE;

-- Seed Default Presets (IN, OUT, IN & OUT)
INSERT INTO animation_presets (name, config, is_system) VALUES 

-- 1. FADE IN (Entrance Only)
(
    'Fade In Up (IN)', 
    '{
        "trigger_start": "top 85%",
        "trigger_end": "top 60%",
        "scrub": true,
        "scrub_sensitivity": 1,
        "steps": {
            "start": { "y": 100, "opacity": 0, "scale": 1, "x": 0 },
            "active": { "y": 0, "opacity": 1, "scale": 1, "x": 0 },
            "end": { "y": 0, "opacity": 1, "scale": 1, "x": 0 }
        }
    }'::jsonb,
    true
),
(
    'Fade In Zoom (IN)', 
    '{
        "trigger_start": "top 90%",
        "trigger_end": "center center",
        "scrub": true,
        "scrub_sensitivity": 1,
        "steps": {
            "start": { "scale": 0.8, "opacity": 0, "y": 50, "x": 0 },
            "active": { "scale": 1, "opacity": 1, "y": 0, "x": 0 },
            "end": { "scale": 1, "opacity": 1, "y": 0, "x": 0 }
        }
    }'::jsonb,
    true
),

-- 2. FADE OUT (Exit Only)
(
    'Fade Out Up (OUT)', 
    '{
        "trigger_start": "center center",
        "trigger_end": "bottom 0%",
        "scrub": true,
        "scrub_sensitivity": 1,
        "steps": {
            "start": { "y": 0, "opacity": 1, "scale": 1, "x": 0 },
            "active": { "y": 0, "opacity": 1, "scale": 1, "x": 0 },
            "end": { "y": -100, "opacity": 0, "scale": 1, "x": 0 }
        }
    }'::jsonb,
    true
),

-- 3. IN & OUT (Both)
(
    'Fade In Out Up (IN & OUT)', 
    '{
        "trigger_start": "top 90%",
        "trigger_end": "bottom 10%",
        "scrub": true,
        "scrub_sensitivity": 1,
        "steps": {
            "start": { "y": 100, "opacity": 0, "scale": 1, "x": 0 },
            "active": { "y": 0, "opacity": 1, "scale": 1, "x": 0 },
            "end": { "y": -100, "opacity": 0, "scale": 1, "x": 0 }
        }
    }'::jsonb,
    true
),
(
    'Slide Left-Right (IN & OUT)', 
    '{
        "trigger_start": "top 100%",
        "trigger_end": "bottom 0%",
        "scrub": true,
        "scrub_sensitivity": 1,
        "steps": {
            "start": { "x": -200, "opacity": 0, "y": 0, "scale": 1 },
            "active": { "x": 0, "opacity": 1, "y": 0, "scale": 1 },
            "end": { "x": 200, "opacity": 0, "y": 0, "scale": 1 }
        }
    }'::jsonb,
    true
),
(
    'Zoom In Out (IN & OUT)', 
    '{
        "trigger_start": "top 100%",
        "trigger_end": "bottom 0%",
        "scrub": true,
        "scrub_sensitivity": 1,
        "steps": {
            "start": { "scale": 0.5, "opacity": 0, "y": 0, "x": 0 },
            "active": { "scale": 1, "opacity": 1, "y": 0, "x": 0 },
            "end": { "scale": 1.5, "opacity": 0, "y": 0, "x": 0 }
        }
    }'::jsonb,
    true
),

-- 4. BACKGROUND SPECIALS
(
    'Background Zoom (Subtle)', 
    '{
        "trigger_start": "top 100%",
        "trigger_end": "bottom 0%",
        "scrub": true,
        "scrub_sensitivity": 1,
        "steps": {
            "start": { "scale": 1.2, "opacity": 1, "y": 0, "x": 0 },
            "active": { "scale": 1.0, "opacity": 1, "y": 0, "x": 0 },
            "end": { "scale": 1.0, "opacity": 1, "y": 0, "x": 0 }
        }
    }'::jsonb,
    true
);
