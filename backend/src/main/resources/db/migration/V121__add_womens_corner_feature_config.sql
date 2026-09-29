-- Women's Corner had a full post-creation flow (create/list/subscription/banner)
-- but no feature_configs row, so admin could never show/hide it from the
-- App Visibility Control page like every other home-screen tile.
INSERT INTO feature_configs (feature_name, display_name, display_name_tamil, icon, color, route, latitude, longitude, radius_km, is_active, display_order, max_posts_per_user)
VALUES
('WOMENS_CORNER', 'Women''s Corner', 'பெண்கள் பகுதி', 'spa_rounded', '#E91E63', '/customer/womens-corner', 12.4966000, 78.5729000, 100, true, 13, 0)
ON CONFLICT (feature_name) DO NOTHING;
