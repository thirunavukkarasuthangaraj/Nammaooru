-- Assign existing shop to shopowner1 for testing

-- First update the TechStore shop to be owned by shopowner1
UPDATE shops 
SET 
    owner_name = 'Shop Owner Test',
    owner_email = 'shopowner1@test.com',
    owner_phone = '9876543210',
    created_by = 'shopowner1',
    updated_by = 'shopowner1',
    is_active = true,
    status = 'APPROVED',
    business_type = 'GROCERY',
    name = 'Test Grocery Store',
    description = 'Test shop for order flow testing'
WHERE id = 11;

-- Add products using existing master products
INSERT INTO shop_products (
    shop_id,
    master_product_id,
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
    11, -- TechStore shop ID
    mp.id,
    mp.base_price * 0.9, -- 10% discount
    mp.base_price,
    mp.base_price * 0.7, -- 30% margin
    100,
    10,
    true,
    true,
    'ACTIVE',
    true,
    'shopowner1',
    'shopowner1',
    NOW(),
    NOW()
FROM master_products mp
WHERE NOT EXISTS (
    SELECT 1 FROM shop_products sp 
    WHERE sp.shop_id = 11 AND sp.master_product_id = mp.id
);

-- Show shop details
SELECT 'SHOP ASSIGNED TO SHOPOWNER1:' as info;
SELECT id, name, owner_email, business_type, is_active, status 
FROM shops 
WHERE id = 11;

SELECT '' as blank;
SELECT 'PRODUCTS IN SHOP:' as info;
SELECT 
    mp.name as product,
    mp.category,
    '₹' || sp.price as price,
    sp.stock_quantity || ' units' as stock,
    CASE WHEN sp.is_available THEN '✓' ELSE '✗' END as available
FROM shop_products sp
JOIN master_products mp ON sp.master_product_id = mp.id
WHERE sp.shop_id = 11
ORDER BY mp.category, mp.name;

-- Summary
SELECT '' as info
UNION ALL
SELECT '============================================'
UNION ALL
SELECT '✅ SHOP READY FOR TESTING!'
UNION ALL
SELECT '============================================'
UNION ALL
SELECT ''
UNION ALL
SELECT '🏪 Shop: Test Grocery Store (ID: 11)'
UNION ALL
SELECT '👤 Owner: shopowner1'
UNION ALL
SELECT ''
UNION ALL
SELECT '🔐 TEST ACCOUNTS (password: password):'
UNION ALL
SELECT '• Customer: customer1'
UNION ALL
SELECT '• Shop Owner: shopowner1'  
UNION ALL
SELECT '• Delivery: delivery1'
UNION ALL
SELECT '• Admin: admin'
UNION ALL
SELECT ''
UNION ALL
SELECT '📋 ORDER FLOW TEST:'
UNION ALL
SELECT '1. Login as customer1'
UNION ALL
SELECT '2. Find "Test Grocery Store"'
UNION ALL
SELECT '3. Add products to cart & place order'
UNION ALL
SELECT '4. Switch to shopowner1 (new window)'
UNION ALL
SELECT '5. Accept and process the order'
UNION ALL
SELECT '6. Assign to delivery1'
UNION ALL
SELECT '7. Complete delivery'
UNION ALL
SELECT ''
UNION ALL
SELECT '🌐 http://localhost:8080'
UNION ALL
SELECT '============================================';