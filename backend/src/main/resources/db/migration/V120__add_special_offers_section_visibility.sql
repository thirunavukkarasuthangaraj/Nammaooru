-- Lets the admin show/hide the "Special Offers" (promo codes + combos) banner
-- carousel on the customer app's home screen, same as the existing
-- Featured Shops / Recent Orders section toggles from V72.
INSERT INTO feature_configs (feature_name, display_name, display_name_tamil, icon, color, is_active, display_order, radius_km)
VALUES
  ('section_special_offers', 'Special Offers Banner', 'சிறப்பு சலுகைகள்', NULL, '#FF6F00', true, 45, 50.0)
ON CONFLICT (feature_name) DO NOTHING;
