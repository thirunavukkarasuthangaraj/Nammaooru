-- =====================================================
-- EMERGENCY COMPLETE DATABASE RESTORATION
-- This will restore EVERYTHING that was lost
-- =====================================================

-- FIX ROLE ENUM IF NEEDED
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_enum
        WHERE enumlabel = 'SUPER_ADMIN'
        AND enumtypid = (SELECT oid FROM pg_type WHERE typname = 'user_role')
    ) THEN
        ALTER TYPE user_role ADD VALUE 'SUPER_ADMIN';
    END IF;
END $$;

-- 1. RESTORE ALL USER ACCOUNTS WITH PROPER ROLES
-- =====================================================
INSERT INTO users (
    username, email, password, role, mobile_number, first_name, last_name,
    is_active, email_verified, mobile_verified, password_change_required,
    is_temporary_password, failed_login_attempts, two_factor_enabled,
    is_online, is_available, status, ride_status, created_at, updated_at
) VALUES
-- YOUR SUPER ADMIN ACCOUNT - HIGHEST PRIORITY
('thiruna2394', 'thiruna2394@gmail.com',
 '$2a$10$4P8VxXrSU7KlpZPvyBbTzuLbKxwLJWfMGzPZRNKwGVDfQ8QxI9Khu', -- Test@123
 'SUPER_ADMIN', '9999999999', 'Thiru', 'Admin',
 true, true, true, false, false, 0, false, false, true, 'ACTIVE', 'AVAILABLE', NOW(), NOW()),

-- BACKUP SUPER ADMIN
('superadmin', 'admin@nammaooru.com',
 '$2a$10$4P8VxXrSU7KlpZPvyBbTzuLbKxwLJWfMGzPZRNKwGVDfQ8QxI9Khu', -- Test@123
 'SUPER_ADMIN', '9999999998', 'Super', 'Admin',
 true, true, true, false, false, 0, false, false, true, 'ACTIVE', 'AVAILABLE', NOW(), NOW()),

-- SHOP OWNER - FOR TESTING
('shopowner', 'shopowner@example.com',
 '$2a$10$dG5EWTw7YixR2cC7xPGSAOoGvmOoiV5dCzi2R7zELzJgJY0fNGNbW', -- shop123
 'SHOP_OWNER', '8888888888', 'Shop', 'Owner',
 true, true, true, false, false, 0, false, false, true, 'ACTIVE', 'AVAILABLE', NOW(), NOW()),

-- DELIVERY PARTNER - FOR TESTING
('delivery1', 'delivery@example.com',
 '$2a$10$K7.eJqPEkXzL9BQmUWFyAeGHQ0tXwRj5Y5VqxQ0jXEKzO8pZqF9gO', -- delivery123
 'DELIVERY_PARTNER', '7777777777', 'Delivery', 'Partner',
 true, true, true, false, false, 0, false, true, true, 'ACTIVE', 'AVAILABLE', NOW(), NOW()),

-- CUSTOMER - FOR TESTING
('customer1', 'customer@example.com',
 '$2a$10$xmX5KIQQ6ZG8vR7oPW5yW.WPQk5kYLtFqpFYGWxZWG7YxGw6yKHWa', -- customer123
 'USER', '6666666666', 'Customer', 'User',
 true, true, true, false, false, 0, false, false, true, 'ACTIVE', 'AVAILABLE', NOW(), NOW())
ON CONFLICT (email) DO UPDATE SET
    password = EXCLUDED.password,
    role = EXCLUDED.role,
    is_active = true;

-- 2. RESTORE ALL PRODUCT CATEGORIES
-- =====================================================
INSERT INTO product_categories (name, description, is_active, created_at, updated_at) VALUES
('Groceries', 'Rice, dal, oil, flour, sugar, salt, spices', true, NOW(), NOW()),
('Fruits & Vegetables', 'Fresh fruits and vegetables', true, NOW(), NOW()),
('Dairy Products', 'Milk, curd, cheese, butter, paneer', true, NOW(), NOW()),
('Beverages', 'Soft drinks, juices, water, tea, coffee', true, NOW(), NOW()),
('Snacks & Branded Foods', 'Chips, biscuits, chocolates, namkeen', true, NOW(), NOW()),
('Personal Care', 'Soap, shampoo, toothpaste, cosmetics', true, NOW(), NOW()),
('Household Items', 'Cleaning supplies, detergents, utensils', true, NOW(), NOW()),
('Baby Care', 'Diapers, baby food, baby care products', true, NOW(), NOW()),
('Pet Care', 'Pet food and accessories', true, NOW(), NOW()),
('Stationery', 'Books, pens, notebooks, office supplies', true, NOW(), NOW()),
('Electronics', 'Mobile accessories, batteries, bulbs', true, NOW(), NOW()),
('Medicines', 'OTC medicines, first aid, health supplements', true, NOW(), NOW()),
('Bakery', 'Bread, cakes, cookies, pastries', true, NOW(), NOW()),
('Meat & Fish', 'Chicken, mutton, fish, eggs', true, NOW(), NOW()),
('Frozen Food', 'Frozen vegetables, ice cream, frozen snacks', true, NOW(), NOW())
ON CONFLICT (name) DO NOTHING;

-- 3. CREATE MULTIPLE SHOPS
-- =====================================================
INSERT INTO shops (
    name, owner_id, phone, email, address, city, state, pincode,
    latitude, longitude, opening_time, closing_time, is_active,
    rating, total_orders, created_at, updated_at, description, shop_type
)
SELECT
    'Namma Store - Main Branch',
    u.id, '8888888801', 'mainstore@nammaooru.com',
    '123 MG Road, Near Bus Stand', 'Bangalore', 'Karnataka', '560001',
    12.9716, 77.5946, '07:00:00', '23:00:00', true,
    4.5, 156, NOW(), NOW(), 'Your neighborhood supermarket', 'GROCERY'
FROM users u WHERE u.email = 'shopowner@example.com'
ON CONFLICT DO NOTHING;

INSERT INTO shops (
    name, owner_id, phone, email, address, city, state, pincode,
    latitude, longitude, opening_time, closing_time, is_active,
    rating, total_orders, created_at, updated_at, description, shop_type
)
SELECT
    'Fresh Mart',
    u.id, '8888888802', 'freshmart@nammaooru.com',
    '456 Brigade Road', 'Bangalore', 'Karnataka', '560002',
    12.9718, 77.6067, '08:00:00', '22:00:00', true,
    4.3, 89, NOW(), NOW(), 'Fresh fruits and vegetables', 'GROCERY'
FROM users u WHERE u.email = 'shopowner@example.com'
ON CONFLICT DO NOTHING;

-- 4. RESTORE MASTER PRODUCTS (COMPREHENSIVE LIST)
-- =====================================================
-- GROCERIES
INSERT INTO master_products (name, description, category_id, brand, unit, base_price, is_active, created_at, updated_at)
SELECT 'Basmati Rice', 'Premium aged basmati rice', c.id, 'India Gate', 'kg', 120.00, true, NOW(), NOW()
FROM product_categories c WHERE c.name = 'Groceries' ON CONFLICT DO NOTHING;

INSERT INTO master_products (name, description, category_id, brand, unit, base_price, is_active, created_at, updated_at)
SELECT 'Sona Masoori Rice', 'Premium sona masoori rice', c.id, 'Fortune', 'kg', 65.00, true, NOW(), NOW()
FROM product_categories c WHERE c.name = 'Groceries' ON CONFLICT DO NOTHING;

INSERT INTO master_products (name, description, category_id, brand, unit, base_price, is_active, created_at, updated_at)
SELECT 'Toor Dal', 'Premium toor dal', c.id, 'Tata Sampann', 'kg', 150.00, true, NOW(), NOW()
FROM product_categories c WHERE c.name = 'Groceries' ON CONFLICT DO NOTHING;

INSERT INTO master_products (name, description, category_id, brand, unit, base_price, is_active, created_at, updated_at)
SELECT 'Sunflower Oil', 'Refined sunflower oil', c.id, 'Fortune', '1 liter', 140.00, true, NOW(), NOW()
FROM product_categories c WHERE c.name = 'Groceries' ON CONFLICT DO NOTHING;

INSERT INTO master_products (name, description, category_id, brand, unit, base_price, is_active, created_at, updated_at)
SELECT 'Wheat Flour (Atta)', 'Whole wheat flour', c.id, 'Aashirvaad', 'kg', 50.00, true, NOW(), NOW()
FROM product_categories c WHERE c.name = 'Groceries' ON CONFLICT DO NOTHING;

INSERT INTO master_products (name, description, category_id, brand, unit, base_price, is_active, created_at, updated_at)
SELECT 'Sugar', 'Fine grain sugar', c.id, 'Madhur', 'kg', 45.00, true, NOW(), NOW()
FROM product_categories c WHERE c.name = 'Groceries' ON CONFLICT DO NOTHING;

INSERT INTO master_products (name, description, category_id, brand, unit, base_price, is_active, created_at, updated_at)
SELECT 'Tea Powder', 'Premium tea', c.id, 'Red Label', '500g', 250.00, true, NOW(), NOW()
FROM product_categories c WHERE c.name = 'Groceries' ON CONFLICT DO NOTHING;

-- DAIRY PRODUCTS
INSERT INTO master_products (name, description, category_id, brand, unit, base_price, is_active, created_at, updated_at)
SELECT 'Milk', 'Fresh pasteurized milk', c.id, 'Nandini', '1 liter', 50.00, true, NOW(), NOW()
FROM product_categories c WHERE c.name = 'Dairy Products' ON CONFLICT DO NOTHING;

INSERT INTO master_products (name, description, category_id, brand, unit, base_price, is_active, created_at, updated_at)
SELECT 'Curd', 'Fresh curd', c.id, 'Nandini', '500ml', 30.00, true, NOW(), NOW()
FROM product_categories c WHERE c.name = 'Dairy Products' ON CONFLICT DO NOTHING;

INSERT INTO master_products (name, description, category_id, brand, unit, base_price, is_active, created_at, updated_at)
SELECT 'Butter', 'Salted butter', c.id, 'Amul', '100g', 50.00, true, NOW(), NOW()
FROM product_categories c WHERE c.name = 'Dairy Products' ON CONFLICT DO NOTHING;

INSERT INTO master_products (name, description, category_id, brand, unit, base_price, is_active, created_at, updated_at)
SELECT 'Cheese Slices', 'Processed cheese', c.id, 'Amul', '200g', 120.00, true, NOW(), NOW()
FROM product_categories c WHERE c.name = 'Dairy Products' ON CONFLICT DO NOTHING;

INSERT INTO master_products (name, description, category_id, brand, unit, base_price, is_active, created_at, updated_at)
SELECT 'Paneer', 'Fresh paneer', c.id, 'Mother Dairy', '200g', 90.00, true, NOW(), NOW()
FROM product_categories c WHERE c.name = 'Dairy Products' ON CONFLICT DO NOTHING;

-- FRUITS & VEGETABLES
INSERT INTO master_products (name, description, category_id, brand, unit, base_price, is_active, created_at, updated_at)
SELECT 'Tomato', 'Fresh tomatoes', c.id, 'Local', 'kg', 40.00, true, NOW(), NOW()
FROM product_categories c WHERE c.name = 'Fruits & Vegetables' ON CONFLICT DO NOTHING;

INSERT INTO master_products (name, description, category_id, brand, unit, base_price, is_active, created_at, updated_at)
SELECT 'Onion', 'Fresh onions', c.id, 'Local', 'kg', 35.00, true, NOW(), NOW()
FROM product_categories c WHERE c.name = 'Fruits & Vegetables' ON CONFLICT DO NOTHING;

INSERT INTO master_products (name, description, category_id, brand, unit, base_price, is_active, created_at, updated_at)
SELECT 'Potato', 'Fresh potatoes', c.id, 'Local', 'kg', 30.00, true, NOW(), NOW()
FROM product_categories c WHERE c.name = 'Fruits & Vegetables' ON CONFLICT DO NOTHING;

INSERT INTO master_products (name, description, category_id, brand, unit, base_price, is_active, created_at, updated_at)
SELECT 'Banana', 'Fresh bananas', c.id, 'Local', 'dozen', 60.00, true, NOW(), NOW()
FROM product_categories c WHERE c.name = 'Fruits & Vegetables' ON CONFLICT DO NOTHING;

INSERT INTO master_products (name, description, category_id, brand, unit, base_price, is_active, created_at, updated_at)
SELECT 'Apple', 'Fresh apples', c.id, 'Kashmir', 'kg', 120.00, true, NOW(), NOW()
FROM product_categories c WHERE c.name = 'Fruits & Vegetables' ON CONFLICT DO NOTHING;

-- BEVERAGES
INSERT INTO master_products (name, description, category_id, brand, unit, base_price, is_active, created_at, updated_at)
SELECT 'Coca Cola', 'Soft drink', c.id, 'Coca Cola', '2 liter', 90.00, true, NOW(), NOW()
FROM product_categories c WHERE c.name = 'Beverages' ON CONFLICT DO NOTHING;

INSERT INTO master_products (name, description, category_id, brand, unit, base_price, is_active, created_at, updated_at)
SELECT 'Mineral Water', 'Packaged drinking water', c.id, 'Bisleri', '1 liter', 20.00, true, NOW(), NOW()
FROM product_categories c WHERE c.name = 'Beverages' ON CONFLICT DO NOTHING;

INSERT INTO master_products (name, description, category_id, brand, unit, base_price, is_active, created_at, updated_at)
SELECT 'Orange Juice', 'Fresh orange juice', c.id, 'Real', '1 liter', 110.00, true, NOW(), NOW()
FROM product_categories c WHERE c.name = 'Beverages' ON CONFLICT DO NOTHING;

-- SNACKS
INSERT INTO master_products (name, description, category_id, brand, unit, base_price, is_active, created_at, updated_at)
SELECT 'Potato Chips', 'Classic salted chips', c.id, 'Lays', '90g', 30.00, true, NOW(), NOW()
FROM product_categories c WHERE c.name = 'Snacks & Branded Foods' ON CONFLICT DO NOTHING;

INSERT INTO master_products (name, description, category_id, brand, unit, base_price, is_active, created_at, updated_at)
SELECT 'Marie Biscuits', 'Light tea biscuits', c.id, 'Britannia', '250g', 30.00, true, NOW(), NOW()
FROM product_categories c WHERE c.name = 'Snacks & Branded Foods' ON CONFLICT DO NOTHING;

INSERT INTO master_products (name, description, category_id, brand, unit, base_price, is_active, created_at, updated_at)
SELECT 'Chocolate', 'Milk chocolate', c.id, 'Cadbury Dairy Milk', '50g', 40.00, true, NOW(), NOW()
FROM product_categories c WHERE c.name = 'Snacks & Branded Foods' ON CONFLICT DO NOTHING;

INSERT INTO master_products (name, description, category_id, brand, unit, base_price, is_active, created_at, updated_at)
SELECT 'Namkeen', 'Spicy mixture', c.id, 'Haldirams', '200g', 60.00, true, NOW(), NOW()
FROM product_categories c WHERE c.name = 'Snacks & Branded Foods' ON CONFLICT DO NOTHING;

-- PERSONAL CARE
INSERT INTO master_products (name, description, category_id, brand, unit, base_price, is_active, created_at, updated_at)
SELECT 'Bath Soap', 'Refreshing bath soap', c.id, 'Lux', '100g x 4', 120.00, true, NOW(), NOW()
FROM product_categories c WHERE c.name = 'Personal Care' ON CONFLICT DO NOTHING;

INSERT INTO master_products (name, description, category_id, brand, unit, base_price, is_active, created_at, updated_at)
SELECT 'Shampoo', 'Anti-dandruff shampoo', c.id, 'Head & Shoulders', '340ml', 320.00, true, NOW(), NOW()
FROM product_categories c WHERE c.name = 'Personal Care' ON CONFLICT DO NOTHING;

INSERT INTO master_products (name, description, category_id, brand, unit, base_price, is_active, created_at, updated_at)
SELECT 'Toothpaste', 'Cavity protection', c.id, 'Colgate', '200g', 80.00, true, NOW(), NOW()
FROM product_categories c WHERE c.name = 'Personal Care' ON CONFLICT DO NOTHING;

INSERT INTO master_products (name, description, category_id, brand, unit, base_price, is_active, created_at, updated_at)
SELECT 'Face Wash', 'Daily face wash', c.id, 'Himalaya', '100ml', 120.00, true, NOW(), NOW()
FROM product_categories c WHERE c.name = 'Personal Care' ON CONFLICT DO NOTHING;

-- HOUSEHOLD
INSERT INTO master_products (name, description, category_id, brand, unit, base_price, is_active, created_at, updated_at)
SELECT 'Detergent Powder', 'Washing powder', c.id, 'Surf Excel', '1kg', 140.00, true, NOW(), NOW()
FROM product_categories c WHERE c.name = 'Household Items' ON CONFLICT DO NOTHING;

INSERT INTO master_products (name, description, category_id, brand, unit, base_price, is_active, created_at, updated_at)
SELECT 'Dishwash Liquid', 'Dishwashing liquid', c.id, 'Vim', '500ml', 95.00, true, NOW(), NOW()
FROM product_categories c WHERE c.name = 'Household Items' ON CONFLICT DO NOTHING;

INSERT INTO master_products (name, description, category_id, brand, unit, base_price, is_active, created_at, updated_at)
SELECT 'Floor Cleaner', 'Disinfectant floor cleaner', c.id, 'Lizol', '975ml', 180.00, true, NOW(), NOW()
FROM product_categories c WHERE c.name = 'Household Items' ON CONFLICT DO NOTHING;

INSERT INTO master_products (name, description, category_id, brand, unit, base_price, is_active, created_at, updated_at)
SELECT 'Toilet Cleaner', 'Toilet cleaning liquid', c.id, 'Harpic', '500ml', 85.00, true, NOW(), NOW()
FROM product_categories c WHERE c.name = 'Household Items' ON CONFLICT DO NOTHING;

-- 5. LINK PRODUCTS TO SHOPS WITH INVENTORY
-- =====================================================
INSERT INTO shop_products (
    shop_id, master_product_id, selling_price, mrp,
    stock_quantity, is_available, created_at, updated_at
)
SELECT
    s.id, mp.id,
    mp.base_price * 1.1, -- 10% markup
    mp.base_price * 1.3, -- 30% MRP markup
    FLOOR(RANDOM() * 100 + 50)::int, -- Random stock 50-150
    true, NOW(), NOW()
FROM shops s
CROSS JOIN master_products mp
WHERE s.is_active = true
ON CONFLICT DO NOTHING;

-- 6. CREATE CUSTOMER PROFILES
-- =====================================================
INSERT INTO customers (
    user_id, first_name, last_name, email, phone,
    address, city, state, pincode, created_at, updated_at
)
SELECT
    u.id, u.first_name, u.last_name, u.email, u.mobile_number,
    '456 Customer Street, Near Park', 'Bangalore', 'Karnataka', '560002',
    NOW(), NOW()
FROM users u
WHERE u.role = 'USER'
ON CONFLICT (user_id) DO NOTHING;

-- 7. CREATE SAMPLE ORDERS FOR TESTING
-- =====================================================
-- Create a pending order
INSERT INTO orders (
    customer_id, shop_id, order_number, total_amount, delivery_fee,
    status, payment_status, payment_method, delivery_address,
    delivery_latitude, delivery_longitude, order_date, created_at, updated_at
)
SELECT
    c.id, s.id,
    'ORD-' || TO_CHAR(NOW(), 'YYYYMMDD') || '-001',
    350.00, 30.00,
    'PENDING', 'PENDING', 'COD',
    'Test Address, Bangalore', 12.9716, 77.5946,
    NOW(), NOW(), NOW()
FROM customers c
CROSS JOIN shops s
LIMIT 1
ON CONFLICT DO NOTHING;

-- Create an accepted order ready for pickup
INSERT INTO orders (
    customer_id, shop_id, order_number, total_amount, delivery_fee,
    status, payment_status, payment_method, delivery_address,
    delivery_latitude, delivery_longitude, order_date, created_at, updated_at
)
SELECT
    c.id, s.id,
    'ORD-' || TO_CHAR(NOW(), 'YYYYMMDD') || '-002',
    520.00, 40.00,
    'READY_FOR_PICKUP', 'PAID', 'ONLINE',
    'Another Test Address, Bangalore', 12.9800, 77.6000,
    NOW(), NOW(), NOW()
FROM customers c
CROSS JOIN shops s
LIMIT 1
ON CONFLICT DO NOTHING;

-- 8. CREATE ORDER ITEMS
-- =====================================================
INSERT INTO order_items (
    order_id, product_id, quantity, price, total, created_at, updated_at
)
SELECT
    o.id,
    sp.id,
    2,
    sp.selling_price,
    sp.selling_price * 2,
    NOW(),
    NOW()
FROM orders o
CROSS JOIN shop_products sp
WHERE sp.is_available = true
LIMIT 3
ON CONFLICT DO NOTHING;

-- 9. PERFORMANCE TUNING INDEXES
-- =====================================================
CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);
CREATE INDEX IF NOT EXISTS idx_users_role ON users(role);
CREATE INDEX IF NOT EXISTS idx_shops_owner ON shops(owner_id);
CREATE INDEX IF NOT EXISTS idx_products_category ON master_products(category_id);
CREATE INDEX IF NOT EXISTS idx_shop_products_shop ON shop_products(shop_id);
CREATE INDEX IF NOT EXISTS idx_orders_customer ON orders(customer_id);
CREATE INDEX IF NOT EXISTS idx_orders_status ON orders(status);
CREATE INDEX IF NOT EXISTS idx_order_items_order ON order_items(order_id);

-- 10. VERIFY RESTORATION
-- =====================================================
SELECT '=== RESTORATION COMPLETE ===' as status;
SELECT 'Total Users: ' || COUNT(*) FROM users;
SELECT 'Total Categories: ' || COUNT(*) FROM product_categories;
SELECT 'Total Master Products: ' || COUNT(*) FROM master_products;
SELECT 'Total Shops: ' || COUNT(*) FROM shops;
SELECT 'Total Shop Products: ' || COUNT(*) FROM shop_products;
SELECT 'Total Orders: ' || COUNT(*) FROM orders;

SELECT '=== YOUR LOGIN CREDENTIALS ===' as info;
SELECT 'Email: thiruna2394@gmail.com | Password: Test@123 | Role: SUPER_ADMIN' as credentials;
SELECT '=== OTHER TEST ACCOUNTS ===' as info;
SELECT 'Shop Owner: shopowner@example.com | Password: shop123' as credentials;
SELECT 'Delivery: delivery@example.com | Password: delivery123' as credentials;
SELECT 'Customer: customer@example.com | Password: customer123' as credentials;