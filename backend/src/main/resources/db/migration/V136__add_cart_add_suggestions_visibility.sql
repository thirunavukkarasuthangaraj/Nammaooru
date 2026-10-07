-- Lets the super admin switch the "Added to cart" bottom sheet (the
-- "You may also need" suggestion row shown after a product's first ADD on the
-- shop screen) on or off, same mechanism as the section toggles from
-- V72 / V120 / V126. Defaults to ON to preserve current behaviour; when OFF
-- the app shows a plain "added to cart" snackbar instead.
--
-- The section_ prefix is required: /feature-config/app-config only returns
-- nav_ / section_ rows and the admin Feature Config page groups them by it.
INSERT INTO feature_configs (feature_name, display_name, display_name_tamil, icon, color, is_active, display_order, radius_km)
VALUES
  ('section_cart_add_suggestions', 'Add-to-cart suggestions popup', 'கூடையில் சேர்த்தபின் பரிந்துரைகள்', NULL, '#2E7D32', true, 47, 50.0)
ON CONFLICT (feature_name) DO NOTHING;
