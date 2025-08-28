-- Add products to Test Grocery Store for shopowner1

-- Add all available master products to the shop with reasonable prices
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
    11, -- Test Grocery Store ID
    mp.id,
    CASE 
        WHEN mp.id = 1 THEN 89999.00  -- Samsung Galaxy
        WHEN mp.id = 2 THEN 7999.00   -- Nike Shoes
        WHEN mp.id = 3 THEN 299.00    -- Green Tea
        WHEN mp.id = 4 THEN 79999.00  -- Dell Laptop
        WHEN mp.id = 5 THEN 2999.00   -- Levi's Jeans
        WHEN mp.id = 6 THEN 999.00    -- Yoga Mat
        WHEN mp.id = 7 THEN 199.00    -- Coffee Beans
        WHEN mp.id = 8 THEN 49999.00  -- iPad Pro
        WHEN mp.id = 9 THEN 1499.00   -- Adidas T-Shirt
        ELSE 999.00
    END as price,
    CASE 
        WHEN mp.id = 1 THEN 99999.00  -- Samsung Galaxy
        WHEN mp.id = 2 THEN 8999.00   -- Nike Shoes
        WHEN mp.id = 3 THEN 349.00    -- Green Tea
        WHEN mp.id = 4 THEN 89999.00  -- Dell Laptop
        WHEN mp.id = 5 THEN 3499.00   -- Levi's Jeans
        WHEN mp.id = 6 THEN 1199.00   -- Yoga Mat
        WHEN mp.id = 7 THEN 249.00    -- Coffee Beans
        WHEN mp.id = 8 THEN 54999.00  -- iPad Pro
        WHEN mp.id = 9 THEN 1799.00   -- Adidas T-Shirt
        ELSE 1199.00
    END as original_price,
    CASE 
        WHEN mp.id = 1 THEN 70000.00  -- Samsung Galaxy
        WHEN mp.id = 2 THEN 6000.00   -- Nike Shoes
        WHEN mp.id = 3 THEN 200.00    -- Green Tea
        WHEN mp.id = 4 THEN 60000.00  -- Dell Laptop
        WHEN mp.id = 5 THEN 2000.00   -- Levi's Jeans
        WHEN mp.id = 6 THEN 700.00    -- Yoga Mat
        WHEN mp.id = 7 THEN 150.00    -- Coffee Beans
        WHEN mp.id = 8 THEN 40000.00  -- iPad Pro
        WHEN mp.id = 9 THEN 1000.00   -- Adidas T-Shirt
        ELSE 700.00
    END as cost_price,
    CASE 
        WHEN mp.id IN (1, 4, 8) THEN 10  -- Electronics - low stock
        WHEN mp.id IN (2, 5, 9) THEN 50  -- Clothing - medium stock
        ELSE 100  -- Others - high stock
    END as stock_quantity,
    5, -- min_stock_level
    true, -- is_available
    CASE WHEN mp.id IN (1, 3, 4) THEN true ELSE false END, -- featured items
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

-- Show products in shop
SELECT 'PRODUCTS IN TEST GROCERY STORE:' as info;
SELECT 
    mp.name as product,
    '₹' || sp.price as price,
    '₹' || sp.original_price as original,
    sp.stock_quantity || ' units' as stock,
    CASE WHEN sp.is_featured THEN '⭐' ELSE '' END as featured,
    CASE WHEN sp.is_available THEN '✓ Available' ELSE '✗' END as status
FROM shop_products sp
JOIN master_products mp ON sp.master_product_id = mp.id
WHERE sp.shop_id = 11
ORDER BY sp.is_featured DESC, mp.name;

-- Count summary
SELECT '' as blank;
SELECT 
    COUNT(*) || ' products added to Test Grocery Store' as summary
FROM shop_products 
WHERE shop_id = 11;

-- Final message
SELECT '' as info
UNION ALL
SELECT '============================================'
UNION ALL
SELECT '✅ PRODUCTS ADDED SUCCESSFULLY!'
UNION ALL
SELECT '============================================'
UNION ALL
SELECT ''
UNION ALL
SELECT '🛍️ Test Grocery Store is ready with products!'
UNION ALL
SELECT ''
UNION ALL
SELECT 'Now you can test the complete order flow:'
UNION ALL
SELECT ''
UNION ALL
SELECT '1️⃣ Login as customer1 / password'
UNION ALL
SELECT '2️⃣ Browse "Test Grocery Store"'
UNION ALL
SELECT '3️⃣ Add products to cart'
UNION ALL
SELECT '4️⃣ Place order'
UNION ALL
SELECT '5️⃣ Login as shopowner1 / password'
UNION ALL
SELECT '6️⃣ Process the order'
UNION ALL
SELECT '7️⃣ Login as delivery1 / password'
UNION ALL
SELECT '8️⃣ Complete delivery'
UNION ALL
SELECT ''
UNION ALL
SELECT '🌐 http://localhost:8080'
UNION ALL
SELECT '============================================';