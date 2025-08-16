-- Insert admin user with bcrypt hashed password for 'admin123'
-- Password: admin123 -> BCrypt hash
INSERT INTO users (username, email, password, first_name, last_name, role, is_active, status, created_at, updated_at)
VALUES (
    'admin',
    'admin@shopmanagement.com',
    '$2a$10$TkFJqCLjeEGmW5OESQ5cLOxbnrx3a2GG5p9nnixNHJKKLXqEKq3vy', -- admin123
    'System',
    'Admin',
    'ADMIN',
    true,
    'ACTIVE',
    CURRENT_TIMESTAMP,
    CURRENT_TIMESTAMP
) ON CONFLICT (username) DO UPDATE
SET password = '$2a$10$TkFJqCLjeEGmW5OESQ5cLOxbnrx3a2GG5p9nnixNHJKKLXqEKq3vy',
    email = 'admin@shopmanagement.com',
    role = 'ADMIN',
    is_active = true,
    status = 'ACTIVE',
    updated_at = CURRENT_TIMESTAMP;

-- Insert a shop owner user
INSERT INTO users (username, email, password, first_name, last_name, role, is_active, status, created_at, updated_at)
VALUES (
    'shopowner',
    'shopowner@shopmanagement.com',
    '$2a$10$TkFJqCLjeEGmW5OESQ5cLOxbnrx3a2GG5p9nnixNHJKKLXqEKq3vy', -- admin123
    'Shop',
    'Owner',
    'SHOP_OWNER',
    true,
    'ACTIVE',
    CURRENT_TIMESTAMP,
    CURRENT_TIMESTAMP
) ON CONFLICT (username) DO NOTHING;

-- Insert a regular user
INSERT INTO users (username, email, password, first_name, last_name, role, is_active, status, created_at, updated_at)
VALUES (
    'user',
    'user@shopmanagement.com',
    '$2a$10$TkFJqCLjeEGmW5OESQ5cLOxbnrx3a2GG5p9nnixNHJKKLXqEKq3vy', -- admin123
    'Regular',
    'User',
    'USER',
    true,
    'ACTIVE',
    CURRENT_TIMESTAMP,
    CURRENT_TIMESTAMP
) ON CONFLICT (username) DO NOTHING;

-- Insert sample product categories
INSERT INTO product_categories (name, description, slug, parent_id, is_active, sort_order, created_by, created_at, updated_at)
VALUES 
    ('Electronics', 'Electronic devices and accessories', 'electronics', NULL, true, 1, 'admin', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
    ('Clothing', 'Apparel and fashion items', 'clothing', NULL, true, 2, 'admin', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
    ('Food & Beverages', 'Food items and drinks', 'food-beverages', NULL, true, 3, 'admin', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
    ('Home & Garden', 'Home improvement and gardening items', 'home-garden', NULL, true, 4, 'admin', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
    ('Books', 'Books and educational materials', 'books', NULL, true, 5, 'admin', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
ON CONFLICT (slug) DO NOTHING;

-- Insert sample master products
INSERT INTO master_products (name, description, sku, barcode, category_id, brand, base_unit, base_weight, specifications, status, is_featured, is_global, created_by, updated_by, created_at, updated_at)
VALUES 
    ('Samsung Galaxy S24', 'Latest Samsung smartphone with advanced camera', 'SGS24-001', '1234567890123', (SELECT id FROM product_categories WHERE slug = 'electronics'), 'Samsung', 'pcs', 0.168, 'Display: 6.2 inches, RAM: 8GB, Storage: 256GB', 'ACTIVE', true, true, 'admin', 'admin', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
    ('Nike Air Max 270', 'Comfortable running shoes', 'NAM270-001', '2345678901234', (SELECT id FROM product_categories WHERE slug = 'clothing'), 'Nike', 'pcs', 0.5, 'Size: Various, Color: Multiple options available', 'ACTIVE', true, true, 'admin', 'admin', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
    ('Organic Green Tea', 'Premium organic green tea leaves', 'OGT-001', '3456789012345', (SELECT id FROM product_categories WHERE slug = 'food-beverages'), 'Twinings', 'box', 0.1, 'Weight: 100g, Organic certified, 20 tea bags', 'ACTIVE', false, true, 'admin', 'admin', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
    ('Dell Laptop XPS 13', 'High-performance ultrabook for professionals', 'DELL-XPS13-001', '4567890123456', (SELECT id FROM product_categories WHERE slug = 'electronics'), 'Dell', 'pcs', 1.2, 'Intel i7, 16GB RAM, 512GB SSD, 13.3 inch display', 'ACTIVE', true, true, 'admin', 'admin', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
    ('Levi''s Jeans 501', 'Classic straight fit denim jeans', 'LEVI-501-001', '5678901234567', (SELECT id FROM product_categories WHERE slug = 'clothing'), 'Levi''s', 'pcs', 0.6, 'Cotton denim, available in multiple sizes and washes', 'ACTIVE', false, true, 'admin', 'admin', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
    ('Coffee Beans Arabica', 'Premium roasted coffee beans', 'COFFEE-ARB-001', '6789012345678', (SELECT id FROM product_categories WHERE slug = 'food-beverages'), 'Blue Tokai', 'kg', 1.0, 'Single origin, medium roast, 250g pack', 'ACTIVE', true, true, 'admin', 'admin', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
    ('Garden Soil Organic', 'Premium organic potting soil', 'SOIL-ORG-001', '7890123456789', (SELECT id FROM product_categories WHERE slug = 'home-garden'), 'Cocopeat', 'bag', 5.0, '10kg bag, enriched with compost', 'ACTIVE', false, true, 'admin', 'admin', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
    ('Programming Book Java', 'Complete guide to Java programming', 'BOOK-JAVA-001', '8901234567890', (SELECT id FROM product_categories WHERE slug = 'books'), 'O''Reilly', 'pcs', 0.8, '800 pages, includes examples and exercises', 'ACTIVE', true, true, 'admin', 'admin', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
ON CONFLICT (sku) DO NOTHING;

-- Insert sample shops
INSERT INTO shops (shop_id, name, business_name, description, owner_name, owner_email, owner_phone, address_line1, city, state, postal_code, country, business_type, latitude, longitude, is_active, is_verified, is_featured, status, created_by, created_at, updated_at)
VALUES 
    ('SHOP001', 'Tech Store Chennai', 'Chennai Electronics Hub', 'Your one-stop shop for all electronic needs', 'Rajesh Kumar', 'rajesh@techstore.com', '+919876543210', '123 Anna Salai', 'Chennai', 'Tamil Nadu', '600002', 'India', 'GENERAL', 13.0827, 80.2707, true, true, true, 'APPROVED', 'admin', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
    ('SHOP002', 'Fashion Hub Mumbai', 'Mumbai Fashion Center', 'Latest fashion trends and clothing', 'Priya Sharma', 'priya@fashionhub.com', '+919876543211', '456 Linking Road', 'Mumbai', 'Maharashtra', '400050', 'India', 'GENERAL', 19.0760, 72.8777, true, true, false, 'APPROVED', 'admin', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
    ('SHOP003', 'Green Grocery Delhi', 'Fresh Mart Delhi', 'Fresh vegetables, fruits and organic products', 'Amit Singh', 'amit@greengrocer.com', '+919876543212', '789 Connaught Place', 'New Delhi', 'Delhi', '110001', 'India', 'GROCERY', 28.6139, 77.2090, true, true, true, 'APPROVED', 'admin', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
    ('SHOP004', 'Book Haven Bangalore', 'Bangalore Book Store', 'Wide collection of books and educational materials', 'Sunita Reddy', 'sunita@bookhaven.com', '+919876543213', '321 MG Road', 'Bangalore', 'Karnataka', '560001', 'India', 'GENERAL', 12.9716, 77.5946, true, false, false, 'PENDING', 'admin', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
ON CONFLICT (shop_id) DO NOTHING;

-- Insert shop products (products available in each shop)
INSERT INTO shop_products (shop_id, master_product_id, price, original_price, cost_price, stock_quantity, track_inventory, is_available, is_featured, status, created_by, created_at, updated_at)
VALUES 
    -- Tech Store Chennai products (Electronics)
    ((SELECT id FROM shops WHERE shop_id = 'SHOP001'), (SELECT id FROM master_products WHERE sku = 'SGS24-001'), 75000.00, 80000.00, 65000.00, 25, true, true, true, 'ACTIVE', 'admin', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
    ((SELECT id FROM shops WHERE shop_id = 'SHOP001'), (SELECT id FROM master_products WHERE sku = 'DELL-XPS13-001'), 125000.00, 130000.00, 110000.00, 15, true, true, true, 'ACTIVE', 'admin', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
    
    -- Fashion Hub Mumbai products (Clothing)
    ((SELECT id FROM shops WHERE shop_id = 'SHOP002'), (SELECT id FROM master_products WHERE sku = 'NAM270-001'), 8500.00, 9000.00, 7000.00, 50, true, true, true, 'ACTIVE', 'admin', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
    ((SELECT id FROM shops WHERE shop_id = 'SHOP002'), (SELECT id FROM master_products WHERE sku = 'LEVI-501-001'), 3500.00, 4000.00, 2800.00, 30, true, true, false, 'ACTIVE', 'admin', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
    
    -- Green Grocery Delhi products (Food & Beverages, Garden)
    ((SELECT id FROM shops WHERE shop_id = 'SHOP003'), (SELECT id FROM master_products WHERE sku = 'OGT-001'), 250.00, 300.00, 200.00, 100, true, true, true, 'ACTIVE', 'admin', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
    ((SELECT id FROM shops WHERE shop_id = 'SHOP003'), (SELECT id FROM master_products WHERE sku = 'COFFEE-ARB-001'), 450.00, 500.00, 350.00, 75, true, true, true, 'ACTIVE', 'admin', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
    ((SELECT id FROM shops WHERE shop_id = 'SHOP003'), (SELECT id FROM master_products WHERE sku = 'SOIL-ORG-001'), 350.00, 400.00, 250.00, 40, true, true, false, 'ACTIVE', 'admin', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
    
    -- Book Haven Bangalore products (Books)
    ((SELECT id FROM shops WHERE shop_id = 'SHOP004'), (SELECT id FROM master_products WHERE sku = 'BOOK-JAVA-001'), 1200.00, 1500.00, 900.00, 20, true, true, true, 'ACTIVE', 'admin', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
    
    -- Add more products to each shop for variety
    -- Tech Store Chennai - Additional electronics
    ((SELECT id FROM shops WHERE shop_id = 'SHOP001'), (SELECT id FROM master_products WHERE sku = 'OGT-001'), 280.00, 300.00, 200.00, 50, true, true, false, 'ACTIVE', 'admin', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
    
    -- Fashion Hub Mumbai - Additional clothing and electronics
    ((SELECT id FROM shops WHERE shop_id = 'SHOP002'), (SELECT id FROM master_products WHERE sku = 'SGS24-001'), 76000.00, 80000.00, 65000.00, 10, true, true, false, 'ACTIVE', 'admin', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
    
    -- Green Grocery Delhi - Books (diversification) 
    ((SELECT id FROM shops WHERE shop_id = 'SHOP003'), (SELECT id FROM master_products WHERE sku = 'BOOK-JAVA-001'), 1100.00, 1500.00, 900.00, 15, true, true, false, 'ACTIVE', 'admin', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
    
    -- Book Haven Bangalore - Technology items
    ((SELECT id FROM shops WHERE shop_id = 'SHOP004'), (SELECT id FROM master_products WHERE sku = 'OGT-001'), 300.00, 350.00, 200.00, 25, true, true, false, 'ACTIVE', 'admin', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
    
ON CONFLICT (shop_id, master_product_id) DO UPDATE SET
    price = EXCLUDED.price,
    original_price = EXCLUDED.original_price,
    cost_price = EXCLUDED.cost_price,
    stock_quantity = EXCLUDED.stock_quantity,
    track_inventory = EXCLUDED.track_inventory,
    is_available = EXCLUDED.is_available,
    is_featured = EXCLUDED.is_featured,
    status = EXCLUDED.status,
    updated_at = CURRENT_TIMESTAMP;

-- Insert sample customers
INSERT INTO customers (first_name, last_name, email, mobile_number, is_active, is_verified, status, city, state, country, created_by, created_at, updated_at)
VALUES 
    ('Arjun', 'Patel', 'arjun.patel@email.com', '+919876543220', true, true, 'ACTIVE', 'Chennai', 'Tamil Nadu', 'India', 'admin', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
    ('Sneha', 'Gupta', 'sneha.gupta@email.com', '+919876543221', true, true, 'ACTIVE', 'Mumbai', 'Maharashtra', 'India', 'admin', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
    ('Rohit', 'Singh', 'rohit.singh@email.com', '+919876543222', true, false, 'PENDING_VERIFICATION', 'Delhi', 'Delhi', 'India', 'admin', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
    ('Kavya', 'Nair', 'kavya.nair@email.com', '+919876543223', true, true, 'ACTIVE', 'Bangalore', 'Karnataka', 'India', 'admin', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
ON CONFLICT (email) DO NOTHING;

-- Insert sample orders
INSERT INTO orders (order_number, customer_id, shop_id, subtotal, tax_amount, delivery_fee, total_amount, status, payment_status, payment_method, delivery_address, delivery_city, delivery_state, delivery_postal_code, delivery_phone, created_by, created_at, updated_at)
VALUES 
    ('ORD-2024-001', (SELECT id FROM customers WHERE email = 'arjun.patel@email.com'), (SELECT id FROM shops WHERE shop_id = 'SHOP001'), 75000.00, 13500.00, 100.00, 88600.00, 'DELIVERED', 'PAID', 'ONLINE_PAYMENT', '123 Test Address', 'Chennai', 'Tamil Nadu', '600001', '+919876543220', 'admin', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
    ('ORD-2024-002', (SELECT id FROM customers WHERE email = 'sneha.gupta@email.com'), (SELECT id FROM shops WHERE shop_id = 'SHOP002'), 8500.00, 1530.00, 50.00, 10080.00, 'CONFIRMED', 'PAID', 'UPI', '456 Fashion Street', 'Mumbai', 'Maharashtra', '400001', '+919876543221', 'admin', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
    ('ORD-2024-003', (SELECT id FROM customers WHERE email = 'kavya.nair@email.com'), (SELECT id FROM shops WHERE shop_id = 'SHOP003'), 700.00, 126.00, 30.00, 856.00, 'PREPARING', 'PAID', 'CASH_ON_DELIVERY', '789 Green Lane', 'Bangalore', 'Karnataka', '560001', '+919876543223', 'admin', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
ON CONFLICT (order_number) DO NOTHING;

-- Insert order items
INSERT INTO order_items (order_id, shop_product_id, product_name, product_sku, quantity, unit_price, total_price, created_at, updated_at)
VALUES 
    -- Order 1 items
    ((SELECT id FROM orders WHERE order_number = 'ORD-2024-001'), (SELECT sp.id FROM shop_products sp JOIN shops s ON sp.shop_id = s.id JOIN master_products mp ON sp.master_product_id = mp.id WHERE s.shop_id = 'SHOP001' AND mp.sku = 'SGS24-001'), 'Samsung Galaxy S24', 'SGS24-001', 1, 75000.00, 75000.00, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
    
    -- Order 2 items
    ((SELECT id FROM orders WHERE order_number = 'ORD-2024-002'), (SELECT sp.id FROM shop_products sp JOIN shops s ON sp.shop_id = s.id JOIN master_products mp ON sp.master_product_id = mp.id WHERE s.shop_id = 'SHOP002' AND mp.sku = 'NAM270-001'), 'Nike Air Max 270', 'NAM270-001', 1, 8500.00, 8500.00, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
    
    -- Order 3 items  
    ((SELECT id FROM orders WHERE order_number = 'ORD-2024-003'), (SELECT sp.id FROM shop_products sp JOIN shops s ON sp.shop_id = s.id JOIN master_products mp ON sp.master_product_id = mp.id WHERE s.shop_id = 'SHOP003' AND mp.sku = 'OGT-001'), 'Organic Green Tea', 'OGT-001', 2, 250.00, 500.00, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
    ((SELECT id FROM orders WHERE order_number = 'ORD-2024-003'), (SELECT sp.id FROM shop_products sp JOIN shops s ON sp.shop_id = s.id JOIN master_products mp ON sp.master_product_id = mp.id WHERE s.shop_id = 'SHOP003' AND mp.sku = 'COFFEE-ARB-001'), 'Coffee Beans Arabica', 'COFFEE-ARB-001', 1, 450.00, 200.00, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP);

-- Insert notifications
INSERT INTO notifications (title, message, recipient_type, recipient_id, type, priority, status, is_active, created_by, created_at, updated_at)
VALUES 
    ('Welcome to NammaOoru!', 'Thank you for joining our platform. Start exploring shops near you.', 'CUSTOMER', (SELECT id FROM customers WHERE email = 'arjun.patel@email.com'), 'INFO', 'LOW', 'UNREAD', true, 'system', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
    ('Order Confirmed', 'Your order ORD-2024-001 has been confirmed and is being processed.', 'CUSTOMER', (SELECT id FROM customers WHERE email = 'arjun.patel@email.com'), 'ORDER', 'HIGH', 'UNREAD', true, 'system', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
    ('New Order Received', 'You have received a new order ORD-2024-002. Please check your dashboard.', 'SHOP_OWNER', (SELECT id FROM users WHERE username = 'shopowner'), 'ORDER', 'HIGH', 'UNREAD', true, 'system', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
    ('Shop Approved', 'Congratulations! Your shop has been approved and is now live.', 'SHOP_OWNER', (SELECT id FROM users WHERE username = 'shopowner'), 'SUCCESS', 'HIGH', 'READ', true, 'system', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP);