-- Add test products for order flow testing

-- First, get the shop ID for shopowner1
DO $$
DECLARE 
    v_shop_id INTEGER;
    v_owner_id INTEGER;
BEGIN
    -- Get owner ID
    SELECT id INTO v_owner_id FROM users WHERE username = 'shopowner1';
    
    -- Get or create shop
    SELECT id INTO v_shop_id FROM shops WHERE created_by = 'shopowner1' OR updated_by = 'shopowner1' LIMIT 1;
    
    IF v_shop_id IS NULL THEN
        -- Create a simple shop if none exists
        INSERT INTO shops (
            name, shop_type, description, 
            address, city, state, postal_code, country,
            status, is_active, created_by, updated_by, created_at, updated_at
        ) VALUES (
            'Test Grocery Store', 'GROCERY', 'Test shop for order flow',
            '123 Test Street', 'Bangalore', 'Karnataka', '560001', 'India',
            'APPROVED', true, 'shopowner1', 'shopowner1', NOW(), NOW()
        ) RETURNING id INTO v_shop_id;
    END IF;
    
    RAISE NOTICE 'Shop ID: %', v_shop_id;
END $$;

-- Add sample products to the shop
INSERT INTO shop_products (
    shop_id, 
    name, 
    description, 
    category,
    price, 
    original_price,
    stock_quantity,
    unit,
    is_available,
    is_featured,
    created_at,
    updated_at
)
SELECT 
    s.id,
    p.name,
    p.description,
    p.category,
    p.price,
    p.original_price,
    p.stock,
    p.unit,
    true,
    p.featured,
    NOW(),
    NOW()
FROM shops s
CROSS JOIN (
    VALUES 
    ('Tomatoes', 'Fresh red tomatoes', 'VEGETABLES', 40.00, 45.00, 100, 'kg', true),
    ('Onions', 'Fresh onions', 'VEGETABLES', 35.00, 40.00, 150, 'kg', true),
    ('Potatoes', 'Fresh potatoes', 'VEGETABLES', 30.00, 35.00, 200, 'kg', false),
    ('Milk', 'Fresh full cream milk', 'DAIRY', 25.00, 28.00, 50, 'liter', true),
    ('Bread', 'Fresh white bread', 'BAKERY', 45.00, 50.00, 30, 'loaf', false),
    ('Eggs', 'Farm fresh eggs', 'DAIRY', 60.00, 65.00, 100, 'dozen', false),
    ('Rice', 'Basmati rice', 'GRAINS', 120.00, 130.00, 80, 'kg', true),
    ('Sugar', 'White sugar', 'GROCERY', 45.00, 50.00, 100, 'kg', false),
    ('Tea', 'Premium tea', 'BEVERAGES', 250.00, 280.00, 40, 'kg', false),
    ('Orange Juice', 'Fresh orange juice', 'BEVERAGES', 80.00, 90.00, 25, 'liter', true)
) AS p(name, description, category, price, original_price, stock, unit, featured)
WHERE (s.created_by = 'shopowner1' OR s.updated_by = 'shopowner1')
AND NOT EXISTS (
    SELECT 1 FROM shop_products sp 
    WHERE sp.shop_id = s.id AND sp.name = p.name
);

-- Show products added
SELECT 
    'Products in Test Grocery Store:' as info
UNION ALL
SELECT 
    '--------------------------------';

SELECT 
    sp.name,
    sp.category,
    '₹' || sp.price || '/' || sp.unit as price,
    sp.stock_quantity || ' ' || sp.unit as stock,
    CASE WHEN sp.is_available THEN '✓ Available' ELSE '✗ Not Available' END as status
FROM shop_products sp
JOIN shops s ON sp.shop_id = s.id
WHERE s.created_by = 'shopowner1' OR s.updated_by = 'shopowner1'
ORDER BY sp.category, sp.name;

-- Summary
SELECT '' as message
UNION ALL
SELECT '========================================='
UNION ALL
SELECT '✅ TEST DATA READY FOR ORDER FLOW'
UNION ALL
SELECT '========================================='
UNION ALL
SELECT 'Shop: Test Grocery Store (Active)'
UNION ALL
SELECT 'Products: 10 items added'
UNION ALL
SELECT ''
UNION ALL
SELECT 'LOGIN CREDENTIALS:'
UNION ALL
SELECT '1. Customer: customer1 / password'
UNION ALL
SELECT '2. Shop Owner: shopowner1 / password'
UNION ALL
SELECT '3. Delivery: delivery1 / password'
UNION ALL
SELECT ''
UNION ALL
SELECT 'TEST URL: http://localhost:8080'
UNION ALL
SELECT '=========================================';