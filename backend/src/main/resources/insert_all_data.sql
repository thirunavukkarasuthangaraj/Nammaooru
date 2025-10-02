-- =====================================================
-- COMPLETE DATA INSERTION SCRIPT
-- This will create all necessary data for your system
-- =====================================================

-- 1. CREATE PRODUCT CATEGORIES
-- =====================================================
INSERT INTO product_categories (name, description, is_active, created_at, updated_at)
VALUES
    ('Groceries', 'Rice, dal, oil, flour, sugar, salt', true, NOW(), NOW()),
    ('Fruits & Vegetables', 'Fresh fruits and vegetables', true, NOW(), NOW()),
    ('Dairy Products', 'Milk, curd, cheese, butter, paneer', true, NOW(), NOW()),
    ('Beverages', 'Soft drinks, juices, tea, coffee', true, NOW(), NOW()),
    ('Snacks & Biscuits', 'Chips, cookies, namkeen, chocolates', true, NOW(), NOW()),
    ('Personal Care', 'Soap, shampoo, toothpaste, cosmetics', true, NOW(), NOW()),
    ('Household Items', 'Cleaning supplies, detergents, kitchen items', true, NOW(), NOW()),
    ('Baby Care', 'Diapers, baby food, baby products', true, NOW(), NOW()),
    ('Health & Medicine', 'OTC medicines, first aid, vitamins', true, NOW(), NOW()),
    ('Stationery', 'Pens, notebooks, school supplies', true, NOW(), NOW()),
    ('Electronics', 'Batteries, bulbs, mobile accessories', true, NOW(), NOW()),
    ('Bakery', 'Bread, cakes, pastries', true, NOW(), NOW()),
    ('Meat & Fish', 'Chicken, mutton, fish, eggs', true, NOW(), NOW()),
    ('Spices & Condiments', 'Masala, pickles, sauces', true, NOW(), NOW()),
    ('Frozen Foods', 'Ice cream, frozen vegetables, ready to eat', true, NOW(), NOW())
ON CONFLICT DO NOTHING;

-- 2. CREATE TEST SHOP OWNERS (if not exist)
-- =====================================================
INSERT INTO users (
    username, email, password, role, mobile_number,
    first_name, last_name, is_active, email_verified,
    mobile_verified, status, created_at, updated_at
) VALUES
    ('shopowner1', 'shop1@example.com', '$2a$10$4P8VxXrSU7KlpZPvyBbTzuLbKxwLJWfMGzPZRNKwGVDfQ8QxI9Khu',
     'SHOP_OWNER', '8881111111', 'Rajesh', 'Kumar', true, true, true, 'ACTIVE', NOW(), NOW()),
    ('shopowner2', 'shop2@example.com', '$2a$10$4P8VxXrSU7KlpZPvyBbTzuLbKxwLJWfMGzPZRNKwGVDfQ8QxI9Khu',
     'SHOP_OWNER', '8882222222', 'Priya', 'Sharma', true, true, true, 'ACTIVE', NOW(), NOW()),
    ('shopowner3', 'shop3@example.com', '$2a$10$4P8VxXrSU7KlpZPvyBbTzuLbKxwLJWfMGzPZRNKwGVDfQ8QxI9Khu',
     'SHOP_OWNER', '8883333333', 'Ahmed', 'Khan', true, true, true, 'ACTIVE', NOW(), NOW())
ON CONFLICT (email) DO NOTHING;

-- 3. CREATE SHOPS
-- =====================================================
INSERT INTO shops (
    name, owner_id, phone, email, address, city, state, pincode,
    latitude, longitude, opening_time, closing_time, is_active,
    rating, total_orders, created_at, updated_at
)
SELECT
    'Sri Krishna Stores', u.id, '8881111111', 'shop1@example.com',
    '123 MG Road', 'Bangalore', 'Karnataka', '560001',
    12.9716, 77.5946, '07:00:00', '22:00:00', true, 4.5, 150, NOW(), NOW()
FROM users u WHERE u.email = 'shop1@example.com'
ON CONFLICT DO NOTHING;

INSERT INTO shops (
    name, owner_id, phone, email, address, city, state, pincode,
    latitude, longitude, opening_time, closing_time, is_active,
    rating, total_orders, created_at, updated_at
)
SELECT
    'Fresh Mart Supermarket', u.id, '8882222222', 'shop2@example.com',
    '456 Brigade Road', 'Bangalore', 'Karnataka', '560002',
    12.9698, 77.6069, '08:00:00', '23:00:00', true, 4.8, 320, NOW(), NOW()
FROM users u WHERE u.email = 'shop2@example.com'
ON CONFLICT DO NOTHING;

INSERT INTO shops (
    name, owner_id, phone, email, address, city, state, pincode,
    latitude, longitude, opening_time, closing_time, is_active,
    rating, total_orders, created_at, updated_at
)
SELECT
    'Daily Needs Store', u.id, '8883333333', 'shop3@example.com',
    '789 Indiranagar', 'Bangalore', 'Karnataka', '560038',
    12.9784, 77.6408, '06:00:00', '23:30:00', true, 4.3, 280, NOW(), NOW()
FROM users u WHERE u.email = 'shop3@example.com'
ON CONFLICT DO NOTHING;

-- 4. CREATE MASTER PRODUCTS
-- =====================================================
-- Groceries
INSERT INTO master_products (name, description, category_id, brand, unit, base_price, is_active, created_at, updated_at)
SELECT 'Basmati Rice', 'Premium long grain rice', c.id, 'India Gate', 'kg', 150.00, true, NOW(), NOW()
FROM product_categories c WHERE c.name = 'Groceries' ON CONFLICT DO NOTHING;

INSERT INTO master_products (name, description, category_id, brand, unit, base_price, is_active, created_at, updated_at)
SELECT 'Toor Dal', 'Premium quality toor dal', c.id, 'Tata Sampann', 'kg', 120.00, true, NOW(), NOW()
FROM product_categories c WHERE c.name = 'Groceries' ON CONFLICT DO NOTHING;

INSERT INTO master_products (name, description, category_id, brand, unit, base_price, is_active, created_at, updated_at)
SELECT 'Sunflower Oil', 'Refined sunflower oil', c.id, 'Fortune', 'liter', 180.00, true, NOW(), NOW()
FROM product_categories c WHERE c.name = 'Groceries' ON CONFLICT DO NOTHING;

INSERT INTO master_products (name, description, category_id, brand, unit, base_price, is_active, created_at, updated_at)
SELECT 'Wheat Flour', 'Whole wheat atta', c.id, 'Aashirvaad', 'kg', 45.00, true, NOW(), NOW()
FROM product_categories c WHERE c.name = 'Groceries' ON CONFLICT DO NOTHING;

INSERT INTO master_products (name, description, category_id, brand, unit, base_price, is_active, created_at, updated_at)
SELECT 'Sugar', 'Fine grain sugar', c.id, 'Madhur', 'kg', 42.00, true, NOW(), NOW()
FROM product_categories c WHERE c.name = 'Groceries' ON CONFLICT DO NOTHING;

-- Dairy Products
INSERT INTO master_products (name, description, category_id, brand, unit, base_price, is_active, created_at, updated_at)
SELECT 'Full Cream Milk', 'Pasteurized milk', c.id, 'Nandini', 'liter', 48.00, true, NOW(), NOW()
FROM product_categories c WHERE c.name = 'Dairy Products' ON CONFLICT DO NOTHING;

INSERT INTO master_products (name, description, category_id, brand, unit, base_price, is_active, created_at, updated_at)
SELECT 'Curd', 'Fresh curd', c.id, 'Nandini', '500g', 25.00, true, NOW(), NOW()
FROM product_categories c WHERE c.name = 'Dairy Products' ON CONFLICT DO NOTHING;

INSERT INTO master_products (name, description, category_id, brand, unit, base_price, is_active, created_at, updated_at)
SELECT 'Butter', 'Fresh butter', c.id, 'Amul', '100g', 48.00, true, NOW(), NOW()
FROM product_categories c WHERE c.name = 'Dairy Products' ON CONFLICT DO NOTHING;

INSERT INTO master_products (name, description, category_id, brand, unit, base_price, is_active, created_at, updated_at)
SELECT 'Paneer', 'Fresh cottage cheese', c.id, 'Milky Mist', '200g', 90.00, true, NOW(), NOW()
FROM product_categories c WHERE c.name = 'Dairy Products' ON CONFLICT DO NOTHING;

-- Fruits & Vegetables
INSERT INTO master_products (name, description, category_id, brand, unit, base_price, is_active, created_at, updated_at)
SELECT 'Tomato', 'Fresh red tomatoes', c.id, 'Fresh', 'kg', 30.00, true, NOW(), NOW()
FROM product_categories c WHERE c.name = 'Fruits & Vegetables' ON CONFLICT DO NOTHING;

INSERT INTO master_products (name, description, category_id, brand, unit, base_price, is_active, created_at, updated_at)
SELECT 'Onion', 'Fresh onions', c.id, 'Fresh', 'kg', 35.00, true, NOW(), NOW()
FROM product_categories c WHERE c.name = 'Fruits & Vegetables' ON CONFLICT DO NOTHING;

INSERT INTO master_products (name, description, category_id, brand, unit, base_price, is_active, created_at, updated_at)
SELECT 'Potato', 'Fresh potatoes', c.id, 'Fresh', 'kg', 25.00, true, NOW(), NOW()
FROM product_categories c WHERE c.name = 'Fruits & Vegetables' ON CONFLICT DO NOTHING;

INSERT INTO master_products (name, description, category_id, brand, unit, base_price, is_active, created_at, updated_at)
SELECT 'Apple', 'Fresh apples', c.id, 'Fresh', 'kg', 120.00, true, NOW(), NOW()
FROM product_categories c WHERE c.name = 'Fruits & Vegetables' ON CONFLICT DO NOTHING;

INSERT INTO master_products (name, description, category_id, brand, unit, base_price, is_active, created_at, updated_at)
SELECT 'Banana', 'Fresh bananas', c.id, 'Fresh', 'dozen', 40.00, true, NOW(), NOW()
FROM product_categories c WHERE c.name = 'Fruits & Vegetables' ON CONFLICT DO NOTHING;

-- Beverages
INSERT INTO master_products (name, description, category_id, brand, unit, base_price, is_active, created_at, updated_at)
SELECT 'Cola', 'Carbonated soft drink', c.id, 'Coca Cola', '2 liter', 90.00, true, NOW(), NOW()
FROM product_categories c WHERE c.name = 'Beverages' ON CONFLICT DO NOTHING;

INSERT INTO master_products (name, description, category_id, brand, unit, base_price, is_active, created_at, updated_at)
SELECT 'Orange Juice', 'Fresh orange juice', c.id, 'Real', '1 liter', 110.00, true, NOW(), NOW()
FROM product_categories c WHERE c.name = 'Beverages' ON CONFLICT DO NOTHING;

INSERT INTO master_products (name, description, category_id, brand, unit, base_price, is_active, created_at, updated_at)
SELECT 'Mineral Water', 'Packaged drinking water', c.id, 'Bisleri', '1 liter', 20.00, true, NOW(), NOW()
FROM product_categories c WHERE c.name = 'Beverages' ON CONFLICT DO NOTHING;

-- Snacks
INSERT INTO master_products (name, description, category_id, brand, unit, base_price, is_active, created_at, updated_at)
SELECT 'Potato Chips', 'Crispy potato chips', c.id, 'Lays', '100g', 30.00, true, NOW(), NOW()
FROM product_categories c WHERE c.name = 'Snacks & Biscuits' ON CONFLICT DO NOTHING;

INSERT INTO master_products (name, description, category_id, brand, unit, base_price, is_active, created_at, updated_at)
SELECT 'Biscuits', 'Cream filled biscuits', c.id, 'Parle-G', '100g', 10.00, true, NOW(), NOW()
FROM product_categories c WHERE c.name = 'Snacks & Biscuits' ON CONFLICT DO NOTHING;

INSERT INTO master_products (name, description, category_id, brand, unit, base_price, is_active, created_at, updated_at)
SELECT 'Chocolate', 'Milk chocolate', c.id, 'Cadbury', '50g', 40.00, true, NOW(), NOW()
FROM product_categories c WHERE c.name = 'Snacks & Biscuits' ON CONFLICT DO NOTHING;

-- Personal Care
INSERT INTO master_products (name, description, category_id, brand, unit, base_price, is_active, created_at, updated_at)
SELECT 'Bath Soap', 'Refreshing bath soap', c.id, 'Lux', '100g', 35.00, true, NOW(), NOW()
FROM product_categories c WHERE c.name = 'Personal Care' ON CONFLICT DO NOTHING;

INSERT INTO master_products (name, description, category_id, brand, unit, base_price, is_active, created_at, updated_at)
SELECT 'Shampoo', 'Anti-dandruff shampoo', c.id, 'Head & Shoulders', '200ml', 180.00, true, NOW(), NOW()
FROM product_categories c WHERE c.name = 'Personal Care' ON CONFLICT DO NOTHING;

INSERT INTO master_products (name, description, category_id, brand, unit, base_price, is_active, created_at, updated_at)
SELECT 'Toothpaste', 'Fluoride toothpaste', c.id, 'Colgate', '100g', 45.00, true, NOW(), NOW()
FROM product_categories c WHERE c.name = 'Personal Care' ON CONFLICT DO NOTHING;

-- 5. LINK PRODUCTS TO SHOPS (Shop Products)
-- =====================================================
INSERT INTO shop_products (shop_id, master_product_id, selling_price, mrp, stock_quantity, is_available, created_at, updated_at)
SELECT
    s.id, mp.id,
    mp.base_price * 1.05, -- 5% markup
    mp.base_price * 1.20, -- 20% MRP markup
    FLOOR(RANDOM() * 100 + 50)::int, -- Random stock between 50-150
    true, NOW(), NOW()
FROM shops s
CROSS JOIN master_products mp
WHERE s.is_active = true
ON CONFLICT DO NOTHING;

-- 6. CREATE TEST CUSTOMERS
-- =====================================================
INSERT INTO users (
    username, email, password, role, mobile_number,
    first_name, last_name, is_active, email_verified,
    mobile_verified, status, created_at, updated_at
) VALUES
    ('customer1', 'customer1@example.com', '$2a$10$4P8VxXrSU7KlpZPvyBbTzuLbKxwLJWfMGzPZRNKwGVDfQ8QxI9Khu',
     'USER', '7771111111', 'Rahul', 'Verma', true, true, true, 'ACTIVE', NOW(), NOW()),
    ('customer2', 'customer2@example.com', '$2a$10$4P8VxXrSU7KlpZPvyBbTzuLbKxwLJWfMGzPZRNKwGVDfQ8QxI9Khu',
     'USER', '7772222222', 'Sneha', 'Patel', true, true, true, 'ACTIVE', NOW(), NOW()),
    ('customer3', 'customer3@example.com', '$2a$10$4P8VxXrSU7KlpZPvyBbTzuLbKxwLJWfMGzPZRNKwGVDfQ8QxI9Khu',
     'USER', '7773333333', 'Amit', 'Singh', true, true, true, 'ACTIVE', NOW(), NOW())
ON CONFLICT (email) DO NOTHING;

-- Create customer records
INSERT INTO customers (user_id, first_name, last_name, email, phone, address, city, state, pincode, created_at, updated_at)
SELECT u.id, u.first_name, u.last_name, u.email, u.mobile_number,
       '123 Customer Street', 'Bangalore', 'Karnataka', '560001', NOW(), NOW()
FROM users u WHERE u.role = 'USER' AND u.email LIKE 'customer%@example.com'
ON CONFLICT DO NOTHING;

-- 7. CREATE TEST DELIVERY PARTNERS
-- =====================================================
INSERT INTO users (
    username, email, password, role, mobile_number,
    first_name, last_name, is_active, email_verified,
    mobile_verified, status, ride_status, is_online, is_available,
    created_at, updated_at
) VALUES
    ('delivery1', 'delivery1@example.com', '$2a$10$4P8VxXrSU7KlpZPvyBbTzuLbKxwLJWfMGzPZRNKwGVDfQ8QxI9Khu',
     'DELIVERY_PARTNER', '6661111111', 'Suresh', 'Kumar', true, true, true, 'ACTIVE', 'AVAILABLE', true, true, NOW(), NOW()),
    ('delivery2', 'delivery2@example.com', '$2a$10$4P8VxXrSU7KlpZPvyBbTzuLbKxwLJWfMGzPZRNKwGVDfQ8QxI9Khu',
     'DELIVERY_PARTNER', '6662222222', 'Ravi', 'Sharma', true, true, true, 'ACTIVE', 'AVAILABLE', true, true, NOW(), NOW()),
    ('delivery3', 'delivery3@example.com', '$2a$10$4P8VxXrSU7KlpZPvyBbTzuLbKxwLJWfMGzPZRNKwGVDfQ8QxI9Khu',
     'DELIVERY_PARTNER', '6663333333', 'Kiran', 'Reddy', true, true, true, 'ACTIVE', 'AVAILABLE', true, true, NOW(), NOW())
ON CONFLICT (email) DO NOTHING;

-- 8. CREATE SAMPLE ORDERS
-- =====================================================
-- Get IDs for creating orders
DO $$
DECLARE
    v_customer_id BIGINT;
    v_shop_id BIGINT;
    v_order_id BIGINT;
    v_product_id BIGINT;
    v_price DECIMAL(10,2);
BEGIN
    -- Get first customer
    SELECT c.id INTO v_customer_id FROM customers c LIMIT 1;
    -- Get first shop
    SELECT s.id INTO v_shop_id FROM shops s WHERE s.is_active = true LIMIT 1;

    IF v_customer_id IS NOT NULL AND v_shop_id IS NOT NULL THEN
        -- Create sample order
        INSERT INTO orders (
            customer_id, shop_id, order_number, total_amount, delivery_fee,
            status, payment_status, payment_method, delivery_address,
            delivery_latitude, delivery_longitude, order_date, created_at, updated_at
        ) VALUES (
            v_customer_id, v_shop_id, 'ORD-' || TO_CHAR(NOW(), 'YYYYMMDD') || '-001',
            500.00, 30.00, 'PENDING', 'PENDING', 'COD',
            '123 Customer Street, Bangalore', 12.9716, 77.5946,
            NOW(), NOW(), NOW()
        ) RETURNING id INTO v_order_id;

        -- Add order items
        FOR v_product_id, v_price IN
            SELECT sp.id, sp.selling_price
            FROM shop_products sp
            WHERE sp.shop_id = v_shop_id
            LIMIT 3
        LOOP
            INSERT INTO order_items (
                order_id, product_id, quantity, price, created_at, updated_at
            ) VALUES (
                v_order_id, v_product_id, 2, v_price, NOW(), NOW()
            );
        END LOOP;
    END IF;
END $$;

-- 9. VERIFICATION QUERIES
-- =====================================================
SELECT 'Categories Created:' as info, COUNT(*) as count FROM product_categories
UNION ALL
SELECT 'Master Products Created:', COUNT(*) FROM master_products
UNION ALL
SELECT 'Shops Created:', COUNT(*) FROM shops
UNION ALL
SELECT 'Shop Products Created:', COUNT(*) FROM shop_products
UNION ALL
SELECT 'Shop Owners Created:', COUNT(*) FROM users WHERE role = 'SHOP_OWNER'
UNION ALL
SELECT 'Customers Created:', COUNT(*) FROM users WHERE role = 'USER'
UNION ALL
SELECT 'Delivery Partners Created:', COUNT(*) FROM users WHERE role = 'DELIVERY_PARTNER'
UNION ALL
SELECT 'Orders Created:', COUNT(*) FROM orders;

-- 10. DISPLAY ALL USERS AND PASSWORDS
-- =====================================================
SELECT
    '========== LOGIN CREDENTIALS ==========' as info
UNION ALL
SELECT
    'Email: ' || email || ' | Password: Test@123 | Role: ' || role
FROM users
ORDER BY 1;

-- SUCCESS MESSAGE
SELECT '✓ ALL DATA SUCCESSFULLY INSERTED!' as status,
       'You can now login and use the system' as message;