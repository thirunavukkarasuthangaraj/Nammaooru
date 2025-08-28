-- Test Data for Complete Order Flow Testing
-- Run this in pgAdmin4 after creating the database

-- 1. Create Test Users (Password for all: 'password' - bcrypt hash)
INSERT INTO users (username, email, password, first_name, last_name, role, status, is_active, email_verified, phone, created_at, updated_at) 
VALUES 
-- Shop Owner
('shopowner1', 'shopowner1@test.com', '$2a$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'Shop', 'Owner', 'SHOP_OWNER', 'ACTIVE', true, true, '9876543210', NOW(), NOW()),
-- Customer
('customer1', 'customer1@test.com', '$2a$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'Test', 'Customer', 'USER', 'ACTIVE', true, true, '9876543211', NOW(), NOW()),
-- Delivery Partner
('delivery1', 'delivery1@test.com', '$2a$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'Delivery', 'Partner', 'DELIVERY_PARTNER', 'ACTIVE', true, true, '9876543212', NOW(), NOW()),
-- Admin
('admin', 'admin@test.com', '$2a$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'Admin', 'User', 'ADMIN', 'ACTIVE', true, true, '9876543213', NOW(), NOW())
ON CONFLICT (username) DO UPDATE 
SET password = EXCLUDED.password,
    is_active = true,
    email_verified = true;

-- 2. Create Test Shop
INSERT INTO shops (
    name, owner_username, shop_type, description, phone, email, 
    address, city, state, postal_code, country, 
    latitude, longitude, status, is_active, 
    opening_time, closing_time, delivery_radius,
    minimum_order, delivery_fee, 
    created_at, updated_at, created_by, updated_by
) VALUES (
    'Test Grocery Store', 'shopowner1', 'GROCERY', 
    'Test shop for order flow testing', '9876543210', 'shop1@test.com',
    '123 Test Street', 'Bangalore', 'Karnataka', '560001', 'India',
    12.9716, 77.5946, 'APPROVED', true,
    '09:00:00', '21:00:00', 5.0,
    100.00, 30.00,
    NOW(), NOW(), 'admin', 'admin'
) ON CONFLICT (owner_username) DO UPDATE
SET is_active = true,
    status = 'APPROVED';

-- 3. Create Test Customer Record
INSERT INTO customers (
    user_id, first_name, last_name, email, phone,
    address_line1, city, state, postal_code, country,
    latitude, longitude, 
    is_active, email_verified,
    created_at, updated_at
) 
SELECT 
    u.id, 'Test', 'Customer', 'customer1@test.com', '9876543211',
    '456 Customer Street', 'Bangalore', 'Karnataka', '560002', 'India',
    12.9716, 77.5946,
    true, true,
    NOW(), NOW()
FROM users u 
WHERE u.username = 'customer1'
ON CONFLICT (user_id) DO UPDATE
SET is_active = true;

-- 4. Create Product Categories
INSERT INTO product_categories (name, description, slug, is_active, created_by, created_at, updated_at)
VALUES 
('Fruits & Vegetables', 'Fresh produce', 'fruits-vegetables', true, 'admin', NOW(), NOW()),
('Dairy Products', 'Milk, cheese, yogurt', 'dairy-products', true, 'admin', NOW(), NOW()),
('Beverages', 'Soft drinks, juices', 'beverages', true, 'admin', NOW(), NOW())
ON CONFLICT (slug) DO NOTHING;

-- 5. Create Master Products
INSERT INTO master_products (
    name, description, sku, barcode, category_id, 
    brand, base_unit, base_weight, status, 
    is_featured, is_global, created_by, updated_by, created_at, updated_at
)
SELECT 
    'Tomatoes', 'Fresh red tomatoes', 'VEG001', '1234567890', c.id,
    'Local Farm', 'kg', 1.0, 'ACTIVE',
    true, true, 'admin', 'admin', NOW(), NOW()
FROM product_categories c WHERE c.slug = 'fruits-vegetables'
ON CONFLICT (sku) DO NOTHING;

INSERT INTO master_products (
    name, description, sku, barcode, category_id, 
    brand, base_unit, base_weight, status, 
    is_featured, is_global, created_by, updated_by, created_at, updated_at
)
SELECT 
    'Milk', 'Fresh full cream milk', 'DAIRY001', '1234567891', c.id,
    'Amul', 'liter', 1.0, 'ACTIVE',
    true, true, 'admin', 'admin', NOW(), NOW()
FROM product_categories c WHERE c.slug = 'dairy-products'
ON CONFLICT (sku) DO NOTHING;

INSERT INTO master_products (
    name, description, sku, barcode, category_id, 
    brand, base_unit, base_weight, status, 
    is_featured, is_global, created_by, updated_by, created_at, updated_at
)
SELECT 
    'Orange Juice', 'Fresh orange juice', 'BEV001', '1234567892', c.id,
    'Tropicana', 'liter', 1.0, 'ACTIVE',
    true, true, 'admin', 'admin', NOW(), NOW()
FROM product_categories c WHERE c.slug = 'beverages'
ON CONFLICT (sku) DO NOTHING;

-- 6. Add Products to Shop
INSERT INTO shop_products (
    shop_id, master_product_id, price, original_price, cost_price,
    stock_quantity, min_stock_level, track_inventory,
    status, is_available, is_featured,
    created_by, updated_by, created_at, updated_at
)
SELECT 
    s.id, mp.id, 40.00, 45.00, 30.00,
    100, 10, true,
    'ACTIVE', true, true,
    'shopowner1', 'shopowner1', NOW(), NOW()
FROM shops s, master_products mp
WHERE s.owner_username = 'shopowner1' AND mp.sku = 'VEG001'
ON CONFLICT (shop_id, master_product_id) DO UPDATE
SET is_available = true,
    stock_quantity = 100;

INSERT INTO shop_products (
    shop_id, master_product_id, price, original_price, cost_price,
    stock_quantity, min_stock_level, track_inventory,
    status, is_available, is_featured,
    created_by, updated_by, created_at, updated_at
)
SELECT 
    s.id, mp.id, 25.00, 28.00, 20.00,
    200, 20, true,
    'ACTIVE', true, true,
    'shopowner1', 'shopowner1', NOW(), NOW()
FROM shops s, master_products mp
WHERE s.owner_username = 'shopowner1' AND mp.sku = 'DAIRY001'
ON CONFLICT (shop_id, master_product_id) DO UPDATE
SET is_available = true,
    stock_quantity = 200;

INSERT INTO shop_products (
    shop_id, master_product_id, price, original_price, cost_price,
    stock_quantity, min_stock_level, track_inventory,
    status, is_available, is_featured,
    created_by, updated_by, created_at, updated_at
)
SELECT 
    s.id, mp.id, 80.00, 90.00, 60.00,
    50, 5, true,
    'ACTIVE', true, true,
    'shopowner1', 'shopowner1', NOW(), NOW()
FROM shops s, master_products mp
WHERE s.owner_username = 'shopowner1' AND mp.sku = 'BEV001'
ON CONFLICT (shop_id, master_product_id) DO UPDATE
SET is_available = true,
    stock_quantity = 50;

-- 7. Create Delivery Partner
INSERT INTO delivery_partners (
    user_id, partner_id, first_name, last_name, email, phone,
    vehicle_type, vehicle_number, license_number,
    address, city, state, postal_code,
    is_available, is_online, current_latitude, current_longitude,
    total_deliveries, rating, status,
    created_at, updated_at
)
SELECT 
    u.id, 'DP' || LPAD(u.id::text, 6, '0'), 'Delivery', 'Partner', 
    'delivery1@test.com', '9876543212',
    'BIKE', 'KA01AB1234', 'DL123456789',
    '789 Delivery Street', 'Bangalore', 'Karnataka', '560003',
    true, true, 12.9716, 77.5946,
    0, 5.0, 'ACTIVE',
    NOW(), NOW()
FROM users u 
WHERE u.username = 'delivery1'
ON CONFLICT (user_id) DO UPDATE
SET is_available = true,
    is_online = true,
    status = 'ACTIVE';

-- Display test credentials
SELECT 
    'TEST USERS CREATED:' as info
UNION ALL
SELECT 
    '-------------------'
UNION ALL
SELECT 
    'Customer: customer1 / password'
UNION ALL
SELECT 
    'Shop Owner: shopowner1 / password'
UNION ALL
SELECT 
    'Delivery: delivery1 / password'
UNION ALL
SELECT 
    'Admin: admin / password'
UNION ALL
SELECT 
    'Super Admin: superadmin / password';

-- Verify data
SELECT 'Users:' as table_name, COUNT(*) as count FROM users
UNION ALL
SELECT 'Shops:', COUNT(*) FROM shops
UNION ALL
SELECT 'Customers:', COUNT(*) FROM customers
UNION ALL
SELECT 'Products:', COUNT(*) FROM master_products
UNION ALL
SELECT 'Shop Products:', COUNT(*) FROM shop_products
UNION ALL
SELECT 'Delivery Partners:', COUNT(*) FROM delivery_partners;