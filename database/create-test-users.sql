-- Create missing test users for order flow testing
-- Password for all: 'password' (bcrypt hash)

-- Create shopowner1 if not exists
INSERT INTO users (username, email, password, first_name, last_name, role, status, is_active, email_verified, created_at, updated_at) 
VALUES 
('shopowner1', 'shopowner1@test.com', '$2a$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'Shop', 'Owner', 'SHOP_OWNER', 'ACTIVE', true, true, NOW(), NOW())
ON CONFLICT (username) DO UPDATE 
SET password = '$2a$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi',
    is_active = true,
    email_verified = true,
    status = 'ACTIVE',
    role = 'SHOP_OWNER';

-- Update existing delivery1 user password
UPDATE users 
SET password = '$2a$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi',
    is_active = true,
    email_verified = true,
    status = 'ACTIVE'
WHERE username = 'delivery1';

-- Create shop for shopowner1
INSERT INTO shops (
    id, name, owner_id, shop_type, description, 
    address, city, state, postal_code, country, 
    latitude, longitude, status, is_active, 
    opening_time, closing_time, delivery_radius,
    minimum_order, delivery_fee, 
    created_at, updated_at, created_by, updated_by
) 
SELECT 
    COALESCE((SELECT MAX(id) FROM shops), 0) + 1,
    'Test Grocery Store', 
    u.id,
    'GROCERY', 
    'Test shop for order flow testing',
    '123 Test Street', 'Bangalore', 'Karnataka', '560001', 'India',
    12.9716, 77.5946, 'APPROVED', true,
    '09:00:00', '21:00:00', 5.0,
    100.00, 30.00,
    NOW(), NOW(), 'admin', 'admin'
FROM users u 
WHERE u.username = 'shopowner1'
ON CONFLICT (owner_id) DO UPDATE
SET is_active = true,
    status = 'APPROVED',
    name = 'Test Grocery Store';

-- Create delivery partner record for delivery1
INSERT INTO delivery_partners (
    user_id, partner_id, first_name, last_name, email,
    vehicle_type, vehicle_number, license_number,
    address, city, state, postal_code,
    is_available, is_online, current_latitude, current_longitude,
    total_deliveries, rating, status,
    created_at, updated_at
)
SELECT 
    u.id, 
    'DP' || LPAD(u.id::text, 6, '0'), 
    'Delivery', 
    'Partner', 
    'delivery1@test.com',
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

-- Verify all test users can login
SELECT 
    username,
    email,
    role,
    is_active,
    email_verified,
    status,
    CASE 
        WHEN password = '$2a$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi' 
        THEN '✓ password works' 
        ELSE '✗ password issue' 
    END as login_status
FROM users 
WHERE username IN ('customer1', 'shopowner1', 'delivery1', 'admin', 'superadmin')
ORDER BY 
    CASE role 
        WHEN 'USER' THEN 1
        WHEN 'SHOP_OWNER' THEN 2  
        WHEN 'DELIVERY_PARTNER' THEN 3
        WHEN 'ADMIN' THEN 4
        WHEN 'SUPER_ADMIN' THEN 5
    END;

-- Show ready to test message
SELECT '' as message
UNION ALL
SELECT '========================================='
UNION ALL
SELECT '✓ TEST USERS READY - All can login with password: password'
UNION ALL
SELECT '========================================='
UNION ALL
SELECT '1. Customer: customer1 / password'
UNION ALL
SELECT '2. Shop Owner: shopowner1 / password'
UNION ALL
SELECT '3. Delivery: delivery1 / password'
UNION ALL
SELECT '4. Admin: admin / password'
UNION ALL
SELECT '5. Super Admin: superadmin / password'
UNION ALL
SELECT '========================================='
UNION ALL
SELECT 'Test at: http://localhost:8080';