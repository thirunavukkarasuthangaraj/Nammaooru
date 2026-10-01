-- Lets the admin show/hide the "My Posts" block (post stats, pricing and
-- per-type counts) on the customer app's Profile screen, same mechanism as
-- the home-screen section toggles from V72 / V120.
INSERT INTO feature_configs (feature_name, display_name, display_name_tamil, icon, color, is_active, display_order, radius_km)
VALUES
  ('section_profile_my_posts', 'Profile: My Posts', 'சுயவிவரம்: என் பதிவுகள்', NULL, '#4CAF50', true, 46, 50.0)
ON CONFLICT (feature_name) DO NOTHING;
