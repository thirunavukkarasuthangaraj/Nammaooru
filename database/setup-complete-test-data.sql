-- Complete Test Data Setup for Order Flow
-- This creates everything needed to test customer → shop → delivery flow

-- 1. Create a shop for shopowner1
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
    status, 
    is_active,
    is_verified,
    is_featured,
    opening_time,
    closing_time,
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
    'APPROVED',
    true,
    true,
    true,
    '09:00:00',
    '21:00:00',
    5.0,
    100.00,
    30.00,
    'shopowner1',
    'shopowner1',
    NOW(),
    NOW()
) ON CONFLICT (id) DO NOTHING;

-- 2. Get the shop ID
DO $$
DECLARE 
    v_shop_id BIGINT;
BEGIN
    SELECT id INTO v_shop_id FROM shops WHERE name = 'Test Grocery Store' LIMIT 1;
    
    IF v_shop_id IS NOT NULL THEN
        RAISE NOTICE 'Shop created with ID: %', v_shop_id;
        
        -- 3. Add products to the shop (using master_product_id if exists, otherwise custom products)
        INSERT INTO shop_products (
            shop_id,
            master_product_id,
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
            created_by,
            updated_by,
            created_at,
            updated_at
        ) VALUES 
        (v_shop_id, NULL, 'Fresh Tomatoes', 'Red ripe tomatoes - 1kg', 40.00, 45.00, 30.00, 100, 10, true, true, 'ACTIVE', 'shopowner1', 'shopowner1', NOW(), NOW()),
        (v_shop_id, NULL, 'Fresh Onions', 'Quality onions - 1kg', 35.00, 40.00, 25.00, 150, 15, true, false, 'ACTIVE', 'shopowner1', 'shopowner1', NOW(), NOW()),
        (v_shop_id, NULL, 'Potatoes', 'Fresh potatoes - 1kg', 30.00, 35.00, 22.00, 200, 20, true, false, 'ACTIVE', 'shopowner1', 'shopowner1', NOW(), NOW()),
        (v_shop_id, NULL, 'Full Cream Milk', 'Fresh milk - 1 liter', 25.00, 28.00, 20.00, 50, 10, true, true, 'ACTIVE', 'shopowner1', 'shopowner1', NOW(), NOW()),
        (v_shop_id, NULL, 'White Bread', 'Fresh bread loaf', 45.00, 50.00, 35.00, 30, 5, true, false, 'ACTIVE', 'shopowner1', 'shopowner1', NOW(), NOW()),
        (v_shop_id, NULL, 'Farm Eggs', 'Fresh eggs - 1 dozen', 60.00, 65.00, 45.00, 100, 20, true, false, 'ACTIVE', 'shopowner1', 'shopowner1', NOW(), NOW()),
        (v_shop_id, NULL, 'Basmati Rice', 'Premium rice - 1kg', 120.00, 130.00, 95.00, 80, 10, true, true, 'ACTIVE', 'shopowner1', 'shopowner1', NOW(), NOW()),
        (v_shop_id, NULL, 'Sugar', 'White sugar - 1kg', 45.00, 50.00, 35.00, 100, 15, true, false, 'ACTIVE', 'shopowner1', 'shopowner1', NOW(), NOW()),
        (v_shop_id, NULL, 'Tea Powder', 'Premium tea - 250g', 80.00, 90.00, 60.00, 40, 5, true, false, 'ACTIVE', 'shopowner1', 'shopowner1', NOW(), NOW()),
        (v_shop_id, NULL, 'Orange Juice', 'Fresh juice - 1 liter', 80.00, 90.00, 60.00, 25, 5, true, true, 'ACTIVE', 'shopowner1', 'shopowner1', NOW(), NOW())
        ON CONFLICT DO NOTHING;
    END IF;
END $$;

-- 4. Verify setup
SELECT 'SHOP DETAILS:' as info;
SELECT id, name, business_type, is_active, status 
FROM shops 
WHERE name = 'Test Grocery Store';

SELECT '' as info;
SELECT 'PRODUCTS IN SHOP:' as info;
SELECT 
    sp.id,
    COALESCE(sp.custom_name, 'Product #' || sp.id) as product_name,
    '₹' || sp.price as price,
    sp.stock_quantity as stock,
    CASE WHEN sp.is_available THEN '✓ Available' ELSE '✗ Not Available' END as availability
FROM shop_products sp
JOIN shops s ON sp.shop_id = s.id
WHERE s.name = 'Test Grocery Store'
ORDER BY sp.id
LIMIT 10;

-- 5. Final summary
SELECT '' as info
UNION ALL
SELECT '============================================'
UNION ALL
SELECT '✅ COMPLETE TEST DATA SETUP SUCCESSFUL'
UNION ALL
SELECT '============================================'
UNION ALL
SELECT ''
UNION ALL
SELECT 'TEST ACCOUNTS (password for all: password):'
UNION ALL
SELECT '--------------------------------------------'
UNION ALL
SELECT '1. Customer:     customer1'
UNION ALL
SELECT '2. Shop Owner:   shopowner1'  
UNION ALL
SELECT '3. Delivery:     delivery1'
UNION ALL
SELECT '4. Admin:        admin'
UNION ALL
SELECT '5. Super Admin:  superadmin'
UNION ALL
SELECT ''
UNION ALL
SELECT 'Shop: Test Grocery Store (10 products)'
UNION ALL
SELECT ''
UNION ALL
SELECT '🛒 ORDER FLOW TEST STEPS:'
UNION ALL
SELECT '1. Login as customer1'
UNION ALL
SELECT '2. Browse shops & add products to cart'
UNION ALL
SELECT '3. Place order'
UNION ALL
SELECT '4. Login as shopowner1 (new window)'
UNION ALL
SELECT '5. Accept and prepare order'
UNION ALL
SELECT '6. Login as delivery1 (new window)'
UNION ALL
SELECT '7. Accept and deliver order'
UNION ALL
SELECT ''
UNION ALL
SELECT 'Test URL: http://localhost:8080'
UNION ALL
SELECT '============================================';