-- App visibility configs: nav items and dashboard sections
-- Admin can toggle these ON/OFF to control what users see in the mobile app.
-- Naming conventions:
--   nav_*     → bottom navigation bar items
--   section_* → dashboard sections (deliver_to bar, featured shops, recent orders)

INSERT INTO feature_configs (feature_name, display_name, display_name_tamil, icon, color, is_active, display_order, radius_km)
VALUES
  -- Bottom navigation
  ('nav_cart',           'Cart',           'கார்ட்',          'shopping_cart_rounded',  '#2196F3', true,  10, 50.0),
  ('nav_orders',         'Orders',         'ஆர்டர்கள்',       'list_alt_rounded',       '#2196F3', true,  20, 50.0),
  ('nav_profile',        'Profile',        'சுயவிவரம்',       'person_rounded',         '#2196F3', true,  30, 50.0),

  -- Dashboard sections
  ('section_deliver_to',      'Deliver To Bar',      'டெலிவரி பட்டி',       NULL, '#4CAF50', true,  40, 50.0),
  ('section_featured_shops',  'Featured Shops',      'சிறப்பு கடைகள்',     NULL, '#FF9800', true,  50, 50.0),
  ('section_recent_orders',   'Recent Orders',       'சமீபத்திய ஆர்டர்கள்', NULL, '#9C27B0', true,  60, 50.0)

ON CONFLICT (feature_name) DO NOTHING;
