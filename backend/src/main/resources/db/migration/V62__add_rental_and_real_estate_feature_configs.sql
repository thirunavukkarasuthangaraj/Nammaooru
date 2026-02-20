-- Add missing feature configs for Rental and Real Estate modules
INSERT INTO feature_configs (feature_name, display_name, display_name_tamil, icon, color, route, latitude, longitude, radius_km, is_active, display_order, max_posts_per_user)
VALUES
('RENTAL', 'Rentals', 'வாடகை', 'vpn_key_rounded', '#795548', '/customer/rentals', 12.4966000, 78.5729000, 100, true, 9, 0),
('REAL_ESTATE', 'Real Estate', 'ரியல் எஸ்டேட்', 'home_work_rounded', '#607D8B', '/customer/real-estate', 12.4966000, 78.5729000, 100, true, 10, 0)
ON CONFLICT (feature_name) DO NOTHING;
