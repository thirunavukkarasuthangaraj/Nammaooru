-- =====================================================
-- COMPLETE DATABASE RESTORATION SCRIPT
-- This script will restore all essential data
-- =====================================================

-- 1. CREATE SUPER ADMIN USERS
-- =====================================================
INSERT INTO users (
    username,
    email,
    password,
    role,
    mobile_number,
    first_name,
    last_name,
    is_active,
    email_verified,
    mobile_verified,
    password_change_required,
    is_temporary_password,
    failed_login_attempts,
    two_factor_enabled,
    is_online,
    is_available,
    status,
    ride_status,
    created_at,
    updated_at
) VALUES
-- Super Admin User
(
    'superadmin',
    'admin@nammaooru.com',
    '$2a$10$4P8VxXrSU7KlpZPvyBbTzuLbKxwLJWfMGzPZRNKwGVDfQ8QxI9Khu', -- Password: Test@123
    'SUPER_ADMIN',
    '9999999998',
    'Super',
    'Admin',
    true,
    true,
    true,
    false,
    false,
    0,
    false,
    false,
    true,
    'ACTIVE',
    'AVAILABLE',
    NOW(),
    NOW()
),
-- Your Super Admin Account
(
    'thiruna2394',
    'thiruna2394@gmail.com',
    '$2a$10$4P8VxXrSU7KlpZPvyBbTzuLbKxwLJWfMGzPZRNKwGVDfQ8QxI9Khu', -- Password: Test@123
    'SUPER_ADMIN',
    '9999999999',
    'Thiru',
    'Admin',
    true,
    true,
    true,
    false,
    false,
    0,
    false,
    false,
    true,
    'ACTIVE',
    'AVAILABLE',
    NOW(),
    NOW()
),
-- Your Second Admin Account
(
    'thirunacse75',
    'thirunacse75@gmail.com',
    '$2a$10$4P8VxXrSU7KlpZPvyBbTzuLbKxwLJWfMGzPZRNKwGVDfQ8QxI9Khu', -- Password: Test@123
    'SUPER_ADMIN',
    '9876543210',
    'Thiru',
    'Admin',
    true,
    true,
    true,
    false,
    false,
    0,
    false,
    false,
    true,
    'ACTIVE',
    'AVAILABLE',
    NOW(),
    NOW()
),
-- Shop Owner Account
(
    'shopowner1',
    'shopowner@example.com',
    '$2a$10$dG5EWTw7YixR2cC7xPGSAOoGvmOoiV5dCzi2R7zELzJgJY0fNGNbW', -- Password: shop123
    'SHOP_OWNER',
    '8888888888',
    'Shop',
    'Owner',
    true,
    true,
    true,
    false,
    false,
    0,
    false,
    false,
    true,
    'ACTIVE',
    'AVAILABLE',
    NOW(),
    NOW()
),
-- Delivery Partner Account
(
    'delivery1',
    'delivery@example.com',
    '$2a$10$K7.eJqPEkXzL9BQmUWFyAeGHQ0tXwRj5Y5VqxQ0jXEKzO8pZqF9gO', -- Password: delivery123
    'DELIVERY_PARTNER',
    '7777777777',
    'Delivery',
    'Partner',
    true,
    true,
    true,
    false,
    false,
    0,
    false,
    true,
    true,
    'ACTIVE',
    'AVAILABLE',
    NOW(),
    NOW()
),
-- Customer Account
(
    'customer1',
    'customer@example.com',
    '$2a$10$xmX5KIQQ6ZG8vR7oPW5yW.WPQk5kYLtFqpFYGWxZWG7YxGw6yKHWa', -- Password: customer123
    'USER',
    '6666666666',
    'Customer',
    'User',
    true,
    true,
    true,
    false,
    false,
    0,
    false,
    false,
    true,
    'ACTIVE',
    'AVAILABLE',
    NOW(),
    NOW()
)
ON CONFLICT (email) DO UPDATE SET
    password = EXCLUDED.password,
    role = EXCLUDED.role,
    mobile_number = EXCLUDED.mobile_number,
    is_active = true,
    updated_at = NOW();

-- 2. CREATE PRODUCT CATEGORIES
-- =====================================================
INSERT INTO product_categories (name, description, is_active, created_at, updated_at)
VALUES
    ('Groceries', 'Daily grocery items', true, NOW(), NOW()),
    ('Fruits & Vegetables', 'Fresh fruits and vegetables', true, NOW(), NOW()),
    ('Dairy Products', 'Milk, cheese, butter, etc.', true, NOW(), NOW()),
    ('Beverages', 'Soft drinks, juices, water', true, NOW(), NOW()),
    ('Snacks', 'Chips, biscuits, namkeen', true, NOW(), NOW()),
    ('Personal Care', 'Soap, shampoo, toiletries', true, NOW(), NOW()),
    ('Household', 'Cleaning supplies, kitchen items', true, NOW(), NOW()),
    ('Electronics', 'Mobile accessories, gadgets', true, NOW(), NOW()),
    ('Stationery', 'Books, pens, notebooks', true, NOW(), NOW()),
    ('Medicines', 'OTC medicines and health products', true, NOW(), NOW())
ON CONFLICT DO NOTHING;

-- 3. CREATE SAMPLE SHOPS
-- =====================================================
INSERT INTO shops (
    name,
    owner_id,
    phone,
    email,
    address,
    city,
    state,
    pincode,
    latitude,
    longitude,
    opening_time,
    closing_time,
    is_active,
    rating,
    total_orders,
    created_at,
    updated_at
)
SELECT
    'Sample Shop - ' || u.first_name,
    u.id,
    u.mobile_number,
    u.email,
    '123 Main Street',
    'Bangalore',
    'Karnataka',
    '560001',
    12.9716,
    77.5946,
    '09:00:00',
    '21:00:00',
    true,
    4.5,
    0,
    NOW(),
    NOW()
FROM users u
WHERE u.role = 'SHOP_OWNER'
ON CONFLICT DO NOTHING;

-- 4. CREATE MASTER PRODUCTS
-- =====================================================
INSERT INTO master_products (
    name,
    description,
    category_id,
    brand,
    unit,
    base_price,
    is_active,
    created_at,
    updated_at
)
SELECT
    'Rice - Basmati',
    'Premium quality basmati rice',
    pc.id,
    'India Gate',
    'kg',
    120.00,
    true,
    NOW(),
    NOW()
FROM product_categories pc
WHERE pc.name = 'Groceries'
ON CONFLICT DO NOTHING;

INSERT INTO master_products (
    name,
    description,
    category_id,
    brand,
    unit,
    base_price,
    is_active,
    created_at,
    updated_at
)
SELECT
    'Milk',
    'Fresh pasteurized milk',
    pc.id,
    'Nandini',
    'liter',
    50.00,
    true,
    NOW(),
    NOW()
FROM product_categories pc
WHERE pc.name = 'Dairy Products'
ON CONFLICT DO NOTHING;

-- 5. CREATE SHOP PRODUCTS (Link products to shops)
-- =====================================================
INSERT INTO shop_products (
    shop_id,
    master_product_id,
    selling_price,
    mrp,
    stock_quantity,
    is_available,
    created_at,
    updated_at
)
SELECT
    s.id,
    mp.id,
    mp.base_price * 1.1, -- 10% markup
    mp.base_price * 1.3, -- 30% MRP
    100,
    true,
    NOW(),
    NOW()
FROM shops s
CROSS JOIN master_products mp
WHERE s.is_active = true
ON CONFLICT DO NOTHING;

-- 6. CREATE CUSTOMERS (Link to user accounts)
-- =====================================================
INSERT INTO customers (
    user_id,
    first_name,
    last_name,
    email,
    phone,
    address,
    city,
    state,
    pincode,
    created_at,
    updated_at
)
SELECT
    u.id,
    u.first_name,
    u.last_name,
    u.email,
    u.mobile_number,
    '456 Customer Street',
    'Bangalore',
    'Karnataka',
    '560002',
    NOW(),
    NOW()
FROM users u
WHERE u.role = 'USER'
ON CONFLICT DO NOTHING;

-- 7. CREATE SAMPLE ORDERS
-- =====================================================
INSERT INTO orders (
    customer_id,
    shop_id,
    order_number,
    total_amount,
    delivery_fee,
    status,
    payment_status,
    payment_method,
    delivery_address,
    delivery_latitude,
    delivery_longitude,
    order_date,
    created_at,
    updated_at
)
SELECT
    c.id,
    s.id,
    'ORD-' || TO_CHAR(NOW(), 'YYYYMMDD') || '-001',
    250.00,
    30.00,
    'PENDING',
    'PENDING',
    'COD',
    c.address || ', ' || c.city,
    12.9716,
    77.5946,
    NOW(),
    NOW(),
    NOW()
FROM customers c
CROSS JOIN shops s
LIMIT 1
ON CONFLICT DO NOTHING;

-- 8. VERIFY DATA CREATION
-- =====================================================
SELECT 'Users Created:' as info, COUNT(*) as count FROM users
UNION ALL
SELECT 'Categories Created:', COUNT(*) FROM product_categories
UNION ALL
SELECT 'Shops Created:', COUNT(*) FROM shops
UNION ALL
SELECT 'Master Products Created:', COUNT(*) FROM master_products
UNION ALL
SELECT 'Shop Products Created:', COUNT(*) FROM shop_products
UNION ALL
SELECT 'Customers Created:', COUNT(*) FROM customers
UNION ALL
SELECT 'Orders Created:', COUNT(*) FROM orders;

-- 9. DISPLAY LOGIN CREDENTIALS
-- =====================================================
SELECT
    '=== LOGIN CREDENTIALS ===' as info
UNION ALL
SELECT
    'Email: ' || email || ' | Password: Test@123 | Role: ' || role
FROM users
WHERE role IN ('SUPER_ADMIN', 'ADMIN')
UNION ALL
SELECT
    'Email: ' || email || ' | Password: shop123 | Role: ' || role
FROM users
WHERE role = 'SHOP_OWNER'
UNION ALL
SELECT
    'Email: ' || email || ' | Password: delivery123 | Role: ' || role
FROM users
WHERE role = 'DELIVERY_PARTNER'
UNION ALL
SELECT
    'Email: ' || email || ' | Password: customer123 | Role: ' || role
FROM users
WHERE role = 'USER';