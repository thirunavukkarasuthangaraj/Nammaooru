-- Create Test Shop for shopowner1

-- First, make sure shopowner1 exists
INSERT INTO users (username, email, password, first_name, last_name, role, status, is_active, email_verified, created_at, updated_at) 
VALUES 
('shopowner1', 'shopowner1@test.com', '$2a$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'Shop', 'Owner', 'SHOP_OWNER', 'ACTIVE', true, true, NOW(), NOW())
ON CONFLICT (username) DO UPDATE 
SET password = '$2a$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi',
    role = 'SHOP_OWNER',
    is_active = true,
    email_verified = true,
    status = 'ACTIVE';

-- Create shop
INSERT INTO shops (
    name, 
    business_type, 
    business_name,
    description, 
    address_line1,
    city, 
    state, 
    postal_code, 
    country,
    latitude, 
    longitude,
    owner_email,
    owner_phone,
    status, 
    is_active,
    is_verified,
    is_featured,
    delivery_radius,
    minimum_order,
    delivery_fee,
    created_by,
    updated_by,
    created_at,
    updated_at
) VALUES (
    'Test Grocery Store',
    'GROCERY',
    'Test Grocery Business',
    'Complete test shop for order flow testing',
    '123 Test Street',
    'Bangalore',
    'Karnataka', 
    '560001',
    'India',
    12.9716,
    77.5946,
    'shopowner1@test.com',
    '9876543210',
    'APPROVED',
    true,
    true,
    true,
    5.0,
    100.00,
    30.00,
    'shopowner1',
    'shopowner1',
    NOW(),
    NOW()
);

-- Add products to the shop
INSERT INTO shop_products (
    shop_id,
    custom_name,
    custom_description,
    price,
    original_price,
    cost_price,
    stock_quantity,
    min_stock_level,
    is_available,
    is_featured,
    status,
    track_inventory,
    created_by,
    updated_by,
    created_at,
    updated_at
)
SELECT 
    s.id,
    p.name,
    p.description,
    p.price,
    p.original_price,
    p.cost_price,
    p.stock,
    p.min_stock,
    true,
    p.featured,
    'ACTIVE',
    true,
    'shopowner1',
    'shopowner1',
    NOW(),
    NOW()
FROM shops s
CROSS JOIN (
    VALUES 
    ('Fresh Tomatoes', 'Red ripe tomatoes - 1kg', 40.00, 45.00, 30.00, 100, 10, true),
    ('Fresh Onions', 'Quality onions - 1kg', 35.00, 40.00, 25.00, 150, 15, false),
    ('Potatoes', 'Fresh potatoes - 1kg', 30.00, 35.00, 22.00, 200, 20, false),
    ('Full Cream Milk', 'Fresh milk - 1 liter', 25.00, 28.00, 20.00, 50, 10, true),
    ('White Bread', 'Fresh bread loaf', 45.00, 50.00, 35.00, 30, 5, false),
    ('Farm Eggs', 'Fresh eggs - 1 dozen', 60.00, 65.00, 45.00, 100, 20, false),
    ('Basmati Rice', 'Premium rice - 1kg', 120.00, 130.00, 95.00, 80, 10, true),
    ('Sugar', 'White sugar - 1kg', 45.00, 50.00, 35.00, 100, 15, false),
    ('Tea Powder', 'Premium tea - 250g', 80.00, 90.00, 60.00, 40, 5, false),
    ('Orange Juice', 'Fresh juice - 1 liter', 80.00, 90.00, 60.00, 25, 5, true)
) AS p(name, description, price, original_price, cost_price, stock, min_stock, featured)
WHERE s.name = 'Test Grocery Store';

-- Show results
SELECT 'Shop Created:' as info;
SELECT id, name, business_type, is_active, status FROM shops WHERE name = 'Test Grocery Store';

SELECT '' as blank;
SELECT 'Products Added:' as info;
SELECT 
    COALESCE(custom_name, 'Product') as name,
    '₹' || price as price,
    stock_quantity as stock,
    CASE WHEN is_available THEN '✓' ELSE '✗' END as available
FROM shop_products sp
JOIN shops s ON sp.shop_id = s.id
WHERE s.name = 'Test Grocery Store'
ORDER BY sp.id;

-- Summary
SELECT '' as info
UNION ALL
SELECT '============================================'
UNION ALL
SELECT '✅ TEST SHOP & PRODUCTS CREATED'
UNION ALL
SELECT '============================================'
UNION ALL
SELECT ''
UNION ALL
SELECT 'LOGIN CREDENTIALS:'
UNION ALL
SELECT '• customer1 / password'
UNION ALL
SELECT '• shopowner1 / password'
UNION ALL
SELECT '• delivery1 / password'
UNION ALL
SELECT ''
UNION ALL
SELECT 'You can now test the complete order flow!'
UNION ALL
SELECT 'Start at: http://localhost:8080';