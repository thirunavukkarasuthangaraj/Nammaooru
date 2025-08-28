-- Fix Test Users and Setup Complete Order Flow
-- Password for all users: 'password' (bcrypt hash)

-- 1. First, check existing users
SELECT username, email, role, is_active, email_verified FROM users;

-- 2. Update/Insert test users with correct password hash
-- The hash below is for 'password'
UPDATE users SET 
    password = '$2a$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi',
    is_active = true,
    email_verified = true,
    status = 'ACTIVE'
WHERE username IN ('customer1', 'shopowner1', 'delivery1', 'admin');

-- If users don't exist, create them
INSERT INTO users (username, email, password, first_name, last_name, role, status, is_active, email_verified, phone, created_at, updated_at) 
VALUES 
('customer1', 'customer1@test.com', '$2a$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'Test', 'Customer', 'USER', 'ACTIVE', true, true, '9876543211', NOW(), NOW()),
('shopowner1', 'shopowner1@test.com', '$2a$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'Shop', 'Owner', 'SHOP_OWNER', 'ACTIVE', true, true, '9876543210', NOW(), NOW()),
('delivery1', 'delivery1@test.com', '$2a$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'Delivery', 'Partner', 'DELIVERY_PARTNER', 'ACTIVE', true, true, '9876543212', NOW(), NOW())
ON CONFLICT (username) DO UPDATE 
SET password = '$2a$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi',
    is_active = true,
    email_verified = true,
    status = 'ACTIVE',
    role = EXCLUDED.role;

-- 3. Create/Update Shop for shopowner1
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
    status = 'APPROVED',
    name = 'Test Grocery Store';

-- 4. Create Customer record for customer1
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
SET is_active = true,
    email_verified = true;

-- 5. Verify users can login
SELECT 
    username,
    email,
    role,
    is_active,
    email_verified,
    status,
    CASE 
        WHEN password = '$2a$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi' 
        THEN 'password' 
        ELSE 'unknown' 
    END as password_status
FROM users 
WHERE username IN ('customer1', 'shopowner1', 'delivery1', 'admin', 'superadmin')
ORDER BY username;

-- 6. Check shop status
SELECT 
    s.id,
    s.name,
    s.owner_username,
    s.status,
    s.is_active,
    u.username,
    u.role
FROM shops s
JOIN users u ON s.owner_username = u.username
WHERE s.owner_username = 'shopowner1';

-- 7. Quick check - count records
SELECT 'Test Data Summary:' as info;
SELECT 'Users with role USER (Customer):' as category, COUNT(*) as count FROM users WHERE role = 'USER'
UNION ALL
SELECT 'Users with role SHOP_OWNER:', COUNT(*) FROM users WHERE role = 'SHOP_OWNER'
UNION ALL
SELECT 'Users with role DELIVERY_PARTNER:', COUNT(*) FROM users WHERE role = 'DELIVERY_PARTNER'
UNION ALL
SELECT 'Active Shops:', COUNT(*) FROM shops WHERE is_active = true AND status = 'APPROVED'
UNION ALL
SELECT 'Shop Products:', COUNT(*) FROM shop_products WHERE is_available = true;

-- Display login credentials
SELECT '=== LOGIN CREDENTIALS ===' as info
UNION ALL
SELECT 'Customer: customer1 / password'
UNION ALL
SELECT 'Shop Owner: shopowner1 / password'
UNION ALL
SELECT 'Delivery: delivery1 / password'
UNION ALL
SELECT 'Admin: admin / password'
UNION ALL
SELECT 'Super Admin: superadmin / password';