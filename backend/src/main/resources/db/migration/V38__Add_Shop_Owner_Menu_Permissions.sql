-- Add menu permissions for shop owner menus
-- Super admin can assign these permissions to shop owners

-- Insert menu permissions for shop owner role
INSERT INTO permissions (name, description, category, resource_type, action_type, active, created_at, updated_at, created_by)
VALUES
-- Main
('MENU_DASHBOARD', 'Access to Dashboard menu', 'SHOP_OWNER_MENU', 'MENU', 'VIEW', true, NOW(), NOW(), 'system'),

-- Shop Profile
('MENU_SHOP_PROFILE', 'Access to Shop Profile menu', 'SHOP_OWNER_MENU', 'MENU', 'VIEW', true, NOW(), NOW(), 'system'),

-- Products
('MENU_MY_PRODUCTS', 'Access to My Products menu', 'SHOP_OWNER_MENU', 'MENU', 'VIEW', true, NOW(), NOW(), 'system'),
('MENU_BROWSE_PRODUCTS', 'Access to Browse Products menu', 'SHOP_OWNER_MENU', 'MENU', 'VIEW', true, NOW(), NOW(), 'system'),
('MENU_COMBOS', 'Access to Combos menu', 'SHOP_OWNER_MENU', 'MENU', 'VIEW', true, NOW(), NOW(), 'system'),
('MENU_BULK_IMPORT', 'Access to Bulk Import menu', 'SHOP_OWNER_MENU', 'MENU', 'VIEW', true, NOW(), NOW(), 'system'),

-- Orders
('MENU_ORDER_MANAGEMENT', 'Access to Order Management menu', 'SHOP_OWNER_MENU', 'MENU', 'VIEW', true, NOW(), NOW(), 'system'),
('MENU_NOTIFICATIONS', 'Access to Notifications menu', 'SHOP_OWNER_MENU', 'MENU', 'VIEW', true, NOW(), NOW(), 'system'),

-- Marketing
('MENU_PROMO_CODES', 'Access to Promo Codes menu', 'SHOP_OWNER_MENU', 'MENU', 'VIEW', true, NOW(), NOW(), 'system')
ON CONFLICT (name) DO NOTHING;
