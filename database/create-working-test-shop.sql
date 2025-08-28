-- Create Working Test Shop and Products

-- Generate unique shop_id
DO $$
DECLARE 
    v_shop_id_str VARCHAR(255);
    v_slug VARCHAR(255);
    v_shop_pk BIGINT;
BEGIN
    -- Generate unique identifiers
    v_shop_id_str := 'SHOP_' || EXTRACT(EPOCH FROM NOW())::INTEGER;
    v_slug := 'test-grocery-store-' || EXTRACT(EPOCH FROM NOW())::INTEGER;
    
    -- Insert shop
    INSERT INTO shops (
        shop_id,
        slug,
        name, 
        business_type, 
        business_name,
        description,
        owner_name,
        owner_email,
        owner_phone,
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
        delivery_radius,
        min_order_amount,
        delivery_fee,
        created_by,
        updated_by,
        created_at,
        updated_at
    ) VALUES (
        v_shop_id_str,
        v_slug,
        'Test Grocery Store',
        'GROCERY',
        'Test Grocery Business',
        'Complete test shop for order flow testing',
        'Shop Owner',
        'shopowner1@test.com',
        '9876543210',
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
        5.0,
        100.00,
        30.00,
        'shopowner1',
        'shopowner1',
        NOW(),
        NOW()
    ) RETURNING id INTO v_shop_pk;
    
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
        v_shop_pk,
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
    FROM (
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
    ) AS p(name, description, price, original_price, cost_price, stock, min_stock, featured);
    
    RAISE NOTICE 'Shop created with ID: %', v_shop_pk;
    RAISE NOTICE 'Shop slug: %', v_slug;
END $$;

-- Show results
SELECT '✅ SHOP CREATED:' as status;
SELECT id, shop_id, name, business_type, is_active, status 
FROM shops 
WHERE name = 'Test Grocery Store'
ORDER BY id DESC
LIMIT 1;

SELECT '' as blank;
SELECT '📦 PRODUCTS ADDED:' as status;
SELECT 
    ROW_NUMBER() OVER (ORDER BY sp.id) as "#",
    COALESCE(custom_name, 'Product') as product,
    '₹' || price as price,
    stock_quantity || ' units' as stock
FROM shop_products sp
WHERE sp.shop_id = (SELECT id FROM shops WHERE name = 'Test Grocery Store' ORDER BY id DESC LIMIT 1)
ORDER BY sp.id;

-- Final message
SELECT '' as blank
UNION ALL
SELECT '============================================'
UNION ALL
SELECT '✅ ALL TEST DATA READY!'
UNION ALL
SELECT '============================================'
UNION ALL
SELECT ''
UNION ALL
SELECT '🔐 LOGIN CREDENTIALS (password: password):'
UNION ALL
SELECT '• Customer: customer1'
UNION ALL
SELECT '• Shop Owner: shopowner1'
UNION ALL
SELECT '• Delivery: delivery1'
UNION ALL
SELECT ''
UNION ALL
SELECT '🛍️ Test Grocery Store has 10 products'
UNION ALL
SELECT ''
UNION ALL
SELECT '🌐 Start testing at: http://localhost:8080'
UNION ALL
SELECT '============================================';