-- Local Shop and Panchayat also had full screens/flows but no feature_configs
-- row, so admin could never show/hide them from App Visibility Control.
-- Local Shop's dashboard tile was additionally hard-excluded in app code;
-- that exclusion is removed in the same change as this migration.
INSERT INTO feature_configs (feature_name, display_name, display_name_tamil, icon, color, route, latitude, longitude, radius_km, is_active, display_order, max_posts_per_user)
VALUES
('LOCAL_SHOP', 'Local Shops', 'கடைகள்', 'shopping_bag_rounded', '#FF6F00', '/customer/local-shops', 12.4966000, 78.5729000, 50, true, 14, 0),
('PANCHAYAT', 'Panchayat', 'பஞ்சாயத்து', 'account_balance_rounded', '#00695C', '/customer/village', 12.4966000, 78.5729000, 50, true, 15, 0)
ON CONFLICT (feature_name) DO NOTHING;
