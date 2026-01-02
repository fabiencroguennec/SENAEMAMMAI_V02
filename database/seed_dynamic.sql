-- Insert a Dynamic Section for testing
INSERT INTO page_sections (page_slug, component_type, order_index, is_visible, content_data)
VALUES (
    'home',
    'DynamicSection',
    100, -- Put it at the end
    true,
    '{
        "modules": [
            {
                "id": "demo-text-1",
                "type": "text",
                "data": {
                    "tag": "h2",
                    "align": "center",
                    "content": "Architecture Modulaire",
                    "color": "#ffffff"
                },
                "config": {
                    "animation_type": "fade-up",
                    "animation_speed": 1
                }
            },
            {
                "id": "demo-image-1",
                "type": "image",
                "data": {
                    "src": "https://images.unsplash.com/photo-1500382017468-9049fed747ef",
                    "alt": "Nature",
                    "fit": "cover",
                    "height": "h-96"
                },
                "config": {
                    "animation_type": "parallax",
                    "parallax_intensity": 0.3
                }
            }
        ]
    }'::jsonb
);
