-- Complete test data for shop management system
-- Run this in pgAdmin query editor for postgres database
-- This will create test data for all menu functionalities

-- First, let's check existing tables
SELECT table_name FROM information_schema.tables WHERE table_schema = 'public' ORDER BY table_name;

-- ========================================
-- 1. INSERT TEST USERS (All Roles)
-- ========================================

-- Insert users for all roles: SUPER_ADMIN, ADMIN, SHOP_OWNER, MANAGER, DELIVERY_PARTNER
INSERT INTO users (username, email, password, first_name, last_name, role, status, email_verified, mobile_verified, two_factor_enabled, failed_login_attempts, password_change_required, is_temporary_password, created_at, updated_at) VALUES
-- Super Admin
('superadmin', 'superadmin@shopmanagement.com', '$2a$10$N9qo8uLOickgx2ZMRJWqNOeWGuyqvvrVt3p/C4.WQ5FHC5yNEVJ/6', 'Super', 'Admin', 'SUPER_ADMIN', 'ACTIVE', true, true, false, 0, false, false, NOW(), NOW()),
-- Admins
('admin1', 'admin1@shopmanagement.com', '$2a$10$N9qo8uLOickgx2ZMRJWqNOeWGuyqvvrVt3p/C4.WQ5FHC5yNEVJ/6', 'Admin', 'One', 'ADMIN', 'ACTIVE', true, true, false, 0, false, false, NOW(), NOW()),
('admin2', 'admin2@shopmanagement.com', '$2a$10$N9qo8uLOickgx2ZMRJWqNOeWGuyqvvrVt3p/C4.WQ5FHC5yNEVJ/6', 'Admin', 'Two', 'ADMIN', 'ACTIVE', true, true, false, 0, false, false, NOW(), NOW()),
-- Shop Owners
('shopowner1', 'owner1@electronics.com', '$2a$10$N9qo8uLOickgx2ZMRJWqNOeWGuyqvvrVt3p/C4.WQ5FHC5yNEVJ/6', 'Rajesh', 'Kumar', 'SHOP_OWNER', 'ACTIVE', true, true, false, 0, false, false, NOW(), NOW()),
('shopowner2', 'owner2@grocery.com', '$2a$10$N9qo8uLOickgx2ZMRJWqNOeWGuyqvvrVt3p/C4.WQ5FHC5yNEVJ/6', 'Priya', 'Sharma', 'SHOP_OWNER', 'ACTIVE', true, true, false, 0, false, false, NOW(), NOW()),
('shopowner3', 'owner3@clothing.com', '$2a$10$N9qo8uLOickgx2ZMRJWqNOeWGuyqvvrVt3p/C4.WQ5FHC5yNEVJ/6', 'Amit', 'Singh', 'SHOP_OWNER', 'ACTIVE', true, true, false, 0, false, false, NOW(), NOW()),
-- Managers
('manager1', 'manager1@electronics.com', '$2a$10$N9qo8uLOickgx2ZMRJWqNOeWGuyqvvrVt3p/C4.WQ5FHC5yNEVJ/6', 'Suresh', 'Reddy', 'MANAGER', 'ACTIVE', true, true, false, 0, false, false, NOW(), NOW()),
('manager2', 'manager2@grocery.com', '$2a$10$N9qo8uLOickgx2ZMRJWqNOeWGuyqvvrVt3p/C4.WQ5FHC5yNEVJ/6', 'Kavitha', 'Nair', 'MANAGER', 'ACTIVE', true, true, false, 0, false, false, NOW(), NOW()),
-- Delivery Partners
('partner1', 'raj.kumar@delivery.com', '$2a$10$N9qo8uLOickgx2ZMRJWqNOeWGuyqvvrVt3p/C4.WQ5FHC5yNEVJ/6', 'Raj', 'Kumar', 'DELIVERY_PARTNER', 'ACTIVE', true, true, false, 0, false, false, NOW(), NOW()),
('partner2', 'priya.delivery@gmail.com', '$2a$10$N9qo8uLOickgx2ZMRJWqNOeWGuyqvvrVt3p/C4.WQ5FHC5yNEVJ/6', 'Priya', 'Devi', 'DELIVERY_PARTNER', 'ACTIVE', true, true, false, 0, false, false, NOW(), NOW()),
('partner3', 'amit.delivery@gmail.com', '$2a$10$N9qo8uLOickgx2ZMRJWqNOeWGuyqvvrVt3p/C4.WQ5FHC5yNEVJ/6', 'Amit', 'Gupta', 'DELIVERY_PARTNER', 'ACTIVE', true, true, false, 0, false, false, NOW(), NOW());

-- ========================================
-- 2. INSERT TEST CUSTOMERS
-- ========================================

INSERT INTO customers (name, email, phone, address_line_1, address_line_2, city, state, postal_code, country, date_of_birth, gender, created_at, updated_at) VALUES
('John Doe', 'john.doe@customer.com', '+919876543210', '123 MG Road', 'Near Metro Station', 'Bangalore', 'Karnataka', '560001', 'India', '1985-06-15', 'MALE', NOW(), NOW()),
('Jane Smith', 'jane.smith@customer.com', '+919876543211', '456 Brigade Road', 'Commercial Street Area', 'Bangalore', 'Karnataka', '560002', 'India', '1990-03-20', 'FEMALE', NOW(), NOW()),
('Mike Johnson', 'mike.johnson@customer.com', '+919876543212', '789 Commercial Street', 'Near Forum Mall', 'Bangalore', 'Karnataka', '560003', 'India', '1988-12-05', 'MALE', NOW(), NOW()),
('Sarah Wilson', 'sarah.wilson@customer.com', '+919876543213', '321 Koramangala', '5th Block', 'Bangalore', 'Karnataka', '560034', 'India', '1992-09-18', 'FEMALE', NOW(), NOW()),
('David Brown', 'david.brown@customer.com', '+919876543214', '654 Whitefield', 'ITPL Road', 'Bangalore', 'Karnataka', '560066', 'India', '1987-04-12', 'MALE', NOW(), NOW());

-- ========================================
-- 3. INSERT TEST SHOPS
-- ========================================

INSERT INTO shops (name, description, owner_id, phone, email, address_line_1, address_line_2, city, state, postal_code, country, latitude, longitude, category, subcategory, status, license_number, gst_number, pan_number, created_at, updated_at) VALUES
('TechWorld Electronics', 'Best electronics store in Bangalore with latest gadgets and home appliances', (SELECT id FROM users WHERE username = 'shopowner1'), '+918012345678', 'contact@techworld.com', '12 Electronic City Phase 1', 'Near Infosys Gate', 'Bangalore', 'Karnataka', '560100', 'India', 12.8456, 77.6632, 'ELECTRONICS', 'GADGETS', 'APPROVED', 'LIC123456789', 'GST123456789', 'PAN123456789', NOW(), NOW()),
('Fresh Mart Grocery', 'Your daily grocery needs with fresh vegetables and organic products', (SELECT id FROM users WHERE username = 'shopowner2'), '+918012345679', 'orders@freshmart.com', '45 Jayanagar 4th Block', 'Near Shopping Complex', 'Bangalore', 'Karnataka', '560011', 'India', 12.9279, 77.5937, 'GROCERY', 'VEGETABLES', 'APPROVED', 'LIC987654321', 'GST987654321', 'PAN987654321', NOW(), NOW()),
('Style Avenue Clothing', 'Trendy fashion for men and women with latest collections', (SELECT id FROM users WHERE username = 'shopowner3'), '+918012345680', 'info@styleavenue.com', '78 Commercial Street', 'Near Brigade Road', 'Bangalore', 'Karnataka', '560001', 'India', 12.9716, 77.6197, 'FASHION', 'CLOTHING', 'APPROVED', 'LIC456789123', 'GST456789123', 'PAN456789123', NOW(), NOW()),
('Book Haven', 'Complete bookstore with academic and fiction books', (SELECT id FROM users WHERE username = 'shopowner1'), '+918012345681', 'books@bookhaven.com', '23 Malleshwaram', 'Near Metro Station', 'Bangalore', 'Karnataka', '560003', 'India', 13.0037, 77.5619, 'BOOKS', 'ACADEMIC', 'PENDING', 'LIC789123456', 'GST789123456', 'PAN789123456', NOW(), NOW()),
('Cafe Delight', 'Cozy cafe with delicious food and beverages', (SELECT id FROM users WHERE username = 'shopowner2'), '+918012345682', 'orders@cafedelight.com', '67 Indiranagar', '100 Feet Road', 'Bangalore', 'Karnataka', '560038', 'India', 12.9719, 77.6412, 'FOOD', 'RESTAURANT', 'APPROVED', 'LIC321654987', 'GST321654987', 'PAN321654987', NOW(), NOW());

-- ========================================
-- 4. INSERT TEST SHOP PRODUCTS
-- ========================================

INSERT INTO shop_products (shop_id, name, description, category, subcategory, price, discounted_price, quantity_available, sku, brand, specifications, warranty_period, is_active, track_inventory, created_at, updated_at) VALUES
-- TechWorld Electronics Products
((SELECT id FROM shops WHERE name = 'TechWorld Electronics'), 'Samsung Galaxy S24', 'Latest Samsung flagship smartphone with AI features', 'ELECTRONICS', 'MOBILE', 75000.00, 69000.00, 25, 'SAM-S24-001', 'Samsung', '{"display": "6.2 inch", "storage": "256GB", "ram": "8GB", "camera": "50MP"}', 24, true, true, NOW(), NOW()),
((SELECT id FROM shops WHERE name = 'TechWorld Electronics'), 'iPhone 15 Pro', 'Apple iPhone 15 Pro with titanium design', 'ELECTRONICS', 'MOBILE', 135000.00, 129000.00, 15, 'APL-I15P-001', 'Apple', '{"display": "6.1 inch", "storage": "256GB", "ram": "8GB", "camera": "48MP"}', 12, true, true, NOW(), NOW()),
((SELECT id FROM shops WHERE name = 'TechWorld Electronics'), 'LG 55" OLED TV', '4K OLED Smart TV with webOS', 'ELECTRONICS', 'TV', 85000.00, 79000.00, 10, 'LG-OLED55-001', 'LG', '{"size": "55 inch", "resolution": "4K", "smart": "webOS", "hdr": "Dolby Vision"}', 36, true, true, NOW(), NOW()),
((SELECT id FROM shops WHERE name = 'TechWorld Electronics'), 'Dell XPS 13 Laptop', 'Ultra-portable laptop for professionals', 'ELECTRONICS', 'LAPTOP', 95000.00, 89000.00, 8, 'DELL-XPS13-001', 'Dell', '{"processor": "Intel i7", "ram": "16GB", "storage": "512GB SSD", "display": "13.3 inch"}', 24, true, true, NOW(), NOW()),
((SELECT id FROM shops WHERE name = 'TechWorld Electronics'), 'Sony WH-1000XM5 Headphones', 'Noise cancelling wireless headphones', 'ELECTRONICS', 'AUDIO', 25000.00, 23000.00, 20, 'SONY-WH1000XM5', 'Sony', '{"type": "Over-ear", "wireless": "Bluetooth 5.2", "battery": "30 hours", "anc": "Industry leading"}', 12, true, true, NOW(), NOW()),

-- Fresh Mart Grocery Products
((SELECT id FROM shops WHERE name = 'Fresh Mart Grocery'), 'Organic Tomatoes', 'Fresh organic tomatoes from local farms', 'GROCERY', 'VEGETABLES', 60.00, 55.00, 100, 'ORG-TOM-001', 'Local Farm', '{"organic": true, "origin": "Karnataka", "shelf_life": "5 days"}', 0, true, true, NOW(), NOW()),
((SELECT id FROM shops WHERE name = 'Fresh Mart Grocery'), 'Basmati Rice 5kg', 'Premium quality basmati rice', 'GROCERY', 'GRAINS', 450.00, 420.00, 50, 'BAS-RICE-5KG', 'India Gate', '{"weight": "5kg", "type": "Basmati", "origin": "Punjab"}', 0, true, true, NOW(), NOW()),
((SELECT id FROM shops WHERE name = 'Fresh Mart Grocery'), 'Amul Fresh Milk 1L', 'Fresh toned milk from Amul', 'GROCERY', 'DAIRY', 55.00, 52.00, 200, 'AMUL-MILK-1L', 'Amul', '{"volume": "1L", "type": "Toned", "fat": "3%"}', 0, true, true, NOW(), NOW()),
((SELECT id FROM shops WHERE name = 'Fresh Mart Grocery'), 'Britannia Bread', 'Soft white bread loaf', 'GROCERY', 'BAKERY', 35.00, 32.00, 75, 'BRIT-BREAD-001', 'Britannia', '{"weight": "400g", "type": "White bread", "shelf_life": "3 days"}', 0, true, true, NOW(), NOW()),

-- Style Avenue Clothing Products
((SELECT id FROM shops WHERE name = 'Style Avenue Clothing'), 'Men Cotton Shirt', 'Formal cotton shirt for office wear', 'FASHION', 'CLOTHING', 1200.00, 999.00, 30, 'MEN-SHIRT-001', 'Arrow', '{"size": "L", "material": "Cotton", "color": "Blue", "pattern": "Solid"}', 6, true, true, NOW(), NOW()),
((SELECT id FROM shops WHERE name = 'Style Avenue Clothing'), 'Women Ethnic Kurti', 'Traditional Indian kurti with embroidery', 'FASHION', 'CLOTHING', 800.00, 650.00, 25, 'WOM-KURTI-001', 'Fabindia', '{"size": "M", "material": "Cotton", "color": "Red", "pattern": "Embroidered"}', 6, true, true, NOW(), NOW()),
((SELECT id FROM shops WHERE name = 'Style Avenue Clothing'), 'Jeans Denim', 'Comfortable slim fit jeans', 'FASHION', 'CLOTHING', 1500.00, 1299.00, 40, 'JEANS-001', 'Levis', '{"size": "32", "fit": "Slim", "color": "Dark Blue", "material": "Denim"}', 12, true, true, NOW(), NOW());

-- ========================================
-- 5. INSERT TEST ORDERS
-- ========================================

INSERT INTO orders (order_number, customer_id, shop_id, total_amount, discount_amount, tax_amount, delivery_fee, final_amount, status, payment_status, payment_method, delivery_address, delivery_latitude, delivery_longitude, delivery_notes, order_date, expected_delivery_date, created_at, updated_at) VALUES
('ORD-2025-001', (SELECT id FROM customers WHERE email = 'john.doe@customer.com'), (SELECT id FROM shops WHERE name = 'TechWorld Electronics'), 69000.00, 6000.00, 4140.00, 100.00, 67240.00, 'CONFIRMED', 'PAID', 'UPI', '123 MG Road, Bangalore, Karnataka 560001', 12.9716, 77.5946, 'Call before delivery', '2025-01-15 10:30:00', '2025-01-17 18:00:00', NOW(), NOW()),
('ORD-2025-002', (SELECT id FROM customers WHERE email = 'jane.smith@customer.com'), (SELECT id FROM shops WHERE name = 'Fresh Mart Grocery'), 562.00, 20.00, 97.56, 50.00, 689.56, 'PROCESSING', 'PAID', 'CARD', '456 Brigade Road, Bangalore, Karnataka 560002', 12.9750, 77.6010, 'Evening delivery preferred', '2025-01-15 14:20:00', '2025-01-16 20:00:00', NOW(), NOW()),
('ORD-2025-003', (SELECT id FROM customers WHERE email = 'mike.johnson@customer.com'), (SELECT id FROM shops WHERE name = 'Style Avenue Clothing'), 1949.00, 250.00, 305.82, 75.00, 2079.82, 'SHIPPED', 'PAID', 'COD', '789 Commercial Street, Bangalore, Karnataka 560003', 12.9800, 77.6050, 'Handle with care', '2025-01-14 16:45:00', '2025-01-16 18:00:00', NOW(), NOW()),
('ORD-2025-004', (SELECT id FROM customers WHERE email = 'sarah.wilson@customer.com'), (SELECT id FROM shops WHERE name = 'TechWorld Electronics'), 23000.00, 2000.00, 3680.00, 0.00, 24680.00, 'DELIVERED', 'PAID', 'UPI', '321 Koramangala, Bangalore, Karnataka 560034', 12.9352, 77.6245, 'Delivered successfully', '2025-01-13 11:15:00', '2025-01-15 17:00:00', NOW(), NOW()),
('ORD-2025-005', (SELECT id FROM customers WHERE email = 'david.brown@customer.com'), (SELECT id FROM shops WHERE name = 'Fresh Mart Grocery'), 927.00, 50.00, 157.59, 60.00, 1094.59, 'PENDING', 'PENDING', 'CARD', '654 Whitefield, Bangalore, Karnataka 560066', 12.9698, 77.7500, 'Morning delivery only', '2025-01-15 18:30:00', '2025-01-17 10:00:00', NOW(), NOW());

-- ========================================
-- 6. INSERT TEST ORDER ITEMS
-- ========================================

INSERT INTO order_items (order_id, product_id, quantity, unit_price, total_price, created_at, updated_at) VALUES
-- Order 1: Samsung Galaxy S24
((SELECT id FROM orders WHERE order_number = 'ORD-2025-001'), (SELECT id FROM shop_products WHERE sku = 'SAM-S24-001'), 1, 69000.00, 69000.00, NOW(), NOW()),

-- Order 2: Grocery items
((SELECT id FROM orders WHERE order_number = 'ORD-2025-002'), (SELECT id FROM shop_products WHERE sku = 'ORG-TOM-001'), 2, 55.00, 110.00, NOW(), NOW()),
((SELECT id FROM orders WHERE order_number = 'ORD-2025-002'), (SELECT id FROM shop_products WHERE sku = 'BAS-RICE-5KG'), 1, 420.00, 420.00, NOW(), NOW()),
((SELECT id FROM orders WHERE order_number = 'ORD-2025-002'), (SELECT id FROM shop_products WHERE sku = 'BRIT-BREAD-001'), 1, 32.00, 32.00, NOW(), NOW()),

-- Order 3: Clothing items
((SELECT id FROM orders WHERE order_number = 'ORD-2025-003'), (SELECT id FROM shop_products WHERE sku = 'MEN-SHIRT-001'), 1, 999.00, 999.00, NOW(), NOW()),
((SELECT id FROM orders WHERE order_number = 'ORD-2025-003'), (SELECT id FROM shop_products WHERE sku = 'JEANS-001'), 1, 1299.00, 1299.00, NOW(), NOW()),

-- Order 4: Sony Headphones
((SELECT id FROM orders WHERE order_number = 'ORD-2025-004'), (SELECT id FROM shop_products WHERE sku = 'SONY-WH1000XM5'), 1, 23000.00, 23000.00, NOW(), NOW()),

-- Order 5: Mixed grocery
((SELECT id FROM orders WHERE order_number = 'ORD-2025-005'), (SELECT id FROM shop_products WHERE sku = 'AMUL-MILK-1L'), 5, 52.00, 260.00, NOW(), NOW()),
((SELECT id FROM orders WHERE order_number = 'ORD-2025-005'), (SELECT id FROM shop_products WHERE sku = 'BAS-RICE-5KG'), 1, 420.00, 420.00, NOW(), NOW()),
((SELECT id FROM orders WHERE order_number = 'ORD-2025-005'), (SELECT id FROM shop_products WHERE sku = 'ORG-TOM-001'), 3, 55.00, 165.00, NOW(), NOW());

-- ========================================
-- 7. INSERT TEST DELIVERY PARTNERS
-- ========================================

INSERT INTO delivery_partners (
    partner_id, user_id, full_name, phone_number, email, date_of_birth, gender,
    address_line1, address_line2, city, state, postal_code, country,
    vehicle_type, vehicle_number, vehicle_model, vehicle_color,
    license_number, license_expiry_date,
    bank_account_number, bank_ifsc_code, bank_name, account_holder_name,
    max_delivery_radius, status, verification_status,
    is_online, is_available, rating, total_deliveries, successful_deliveries, total_earnings,
    current_latitude, current_longitude, last_location_update, last_seen,
    created_at, updated_at, created_by, updated_by
) VALUES
('DP00000001', 
 (SELECT id FROM users WHERE username = 'partner1'),
 'Raj Kumar', '+919876543210', 'raj.kumar@delivery.com', '1990-01-15', 'MALE',
 '123 Electronic City', 'Phase 1', 'Bangalore', 'Karnataka', '560100', 'India',
 'BIKE', 'KA05AB1234', 'Honda CB Shine', 'Red',
 'KA1234567890', '2025-12-31',
 '1234567890123456', 'HDFC0001234', 'HDFC Bank', 'Raj Kumar',
 15.00, 'ACTIVE', 'VERIFIED',
 true, true, 4.8, 150, 145, 25000.00,
 12.9700, 77.5930, NOW() - INTERVAL '2 minutes', NOW() - INTERVAL '1 minute',
 NOW(), NOW(), 'system', 'system'),
('DP00000002',
 (SELECT id FROM users WHERE username = 'partner2'),
 'Priya Devi', '+919876543211', 'priya.delivery@gmail.com', '1992-03-20', 'FEMALE',
 '456 Whitefield', 'Main Road', 'Bangalore', 'Karnataka', '560066', 'India',
 'SCOOTER', 'KA05CD5678', 'Honda Activa', 'Blue',
 'KA2345678901', '2025-10-31',
 '2345678901234567', 'ICICI0002345', 'ICICI Bank', 'Priya Devi',
 12.00, 'ACTIVE', 'VERIFIED',
 true, true, 4.9, 200, 195, 35000.00,
 12.9716, 77.5946, NOW() - INTERVAL '1 minute', NOW() - INTERVAL '30 seconds',
 NOW(), NOW(), 'system', 'system'),
('DP00000003',
 (SELECT id FROM users WHERE username = 'partner3'),
 'Amit Gupta', '+919876543212', 'amit.delivery@gmail.com', '1988-07-10', 'MALE',
 '789 Koramangala', '5th Block', 'Bangalore', 'Karnataka', '560034', 'India',
 'BIKE', 'KA05EF9012', 'Bajaj Pulsar', 'Black',
 'KA3456789012', '2025-08-31',
 '3456789012345678', 'SBI0003456', 'State Bank of India', 'Amit Gupta',
 20.00, 'ACTIVE', 'VERIFIED',
 false, false, 4.7, 100, 98, 18000.00,
 12.9500, 77.6000, NOW() - INTERVAL '5 minutes', NOW() - INTERVAL '3 minutes',
 NOW(), NOW(), 'system', 'system');

-- ========================================
-- 8. INSERT TEST ORDER ASSIGNMENTS
-- ========================================

INSERT INTO order_assignments (
    order_id, partner_id, assigned_at, assignment_type, status,
    delivery_fee, partner_commission,
    pickup_latitude, pickup_longitude, delivery_latitude, delivery_longitude,
    accepted_at, pickup_time, delivery_time,
    created_at, updated_at
) VALUES
-- Assignment 1: Order 1 to Partner 1 (In Transit)
((SELECT id FROM orders WHERE order_number = 'ORD-2025-001'),
 (SELECT id FROM delivery_partners WHERE partner_id = 'DP00000001'),
 NOW() - INTERVAL '30 minutes', 'AUTO', 'IN_TRANSIT',
 100.00, 60.00,
 12.8456, 77.6632, 12.9716, 77.5946,
 NOW() - INTERVAL '25 minutes', NOW() - INTERVAL '15 minutes', NULL,
 NOW(), NOW()),

-- Assignment 2: Order 2 to Partner 2 (Picked Up)
((SELECT id FROM orders WHERE order_number = 'ORD-2025-002'),
 (SELECT id FROM delivery_partners WHERE partner_id = 'DP00000002'),
 NOW() - INTERVAL '20 minutes', 'AUTO', 'PICKED_UP',
 50.00, 30.00,
 12.9279, 77.5937, 12.9750, 77.6010,
 NOW() - INTERVAL '18 minutes', NOW() - INTERVAL '5 minutes', NULL,
 NOW(), NOW()),

-- Assignment 3: Order 3 to Partner 3 (Assigned)
((SELECT id FROM orders WHERE order_number = 'ORD-2025-003'),
 (SELECT id FROM delivery_partners WHERE partner_id = 'DP00000003'),
 NOW() - INTERVAL '10 minutes', 'MANUAL', 'ASSIGNED',
 75.00, 45.00,
 12.9716, 77.6197, 12.9800, 77.6050,
 NULL, NULL, NULL,
 NOW(), NOW()),

-- Assignment 4: Order 4 to Partner 1 (Delivered)
((SELECT id FROM orders WHERE order_number = 'ORD-2025-004'),
 (SELECT id FROM delivery_partners WHERE partner_id = 'DP00000001'),
 NOW() - INTERVAL '2 days', 'AUTO', 'DELIVERED',
 0.00, 40.00,
 12.8456, 77.6632, 12.9352, 77.6245,
 NOW() - INTERVAL '2 days' + INTERVAL '10 minutes', NOW() - INTERVAL '2 days' + INTERVAL '30 minutes', NOW() - INTERVAL '1 day' + INTERVAL '15 minutes',
 NOW() - INTERVAL '2 days', NOW());

-- ========================================
-- 9. INSERT TEST DELIVERY TRACKING
-- ========================================

INSERT INTO delivery_tracking (
    assignment_id, latitude, longitude, accuracy, speed, heading,
    tracked_at, battery_level, is_moving, estimated_arrival_time,
    distance_to_destination, distance_traveled, created_at
) VALUES
-- Tracking for Order 1 (IN_TRANSIT) - Multiple tracking points
((SELECT id FROM order_assignments WHERE order_id = (SELECT id FROM orders WHERE order_number = 'ORD-2025-001')),
 12.9700, 77.5930, 5.0, 25.5, 45.0,
 NOW() - INTERVAL '2 minutes', 85, true, NOW() + INTERVAL '15 minutes',
 2.5, 3.2, NOW()),
((SELECT id FROM order_assignments WHERE order_id = (SELECT id FROM orders WHERE order_number = 'ORD-2025-001')),
 12.9690, 77.5920, 4.5, 28.0, 42.0,
 NOW() - INTERVAL '5 minutes', 83, true, NOW() + INTERVAL '18 minutes',
 2.8, 2.8, NOW()),
((SELECT id FROM order_assignments WHERE order_id = (SELECT id FROM orders WHERE order_number = 'ORD-2025-001')),
 12.9680, 77.5910, 5.2, 22.0, 38.0,
 NOW() - INTERVAL '8 minutes', 81, true, NOW() + INTERVAL '20 minutes',
 3.1, 2.4, NOW()),

-- Tracking for Order 2 (PICKED_UP)
((SELECT id FROM order_assignments WHERE order_id = (SELECT id FROM orders WHERE order_number = 'ORD-2025-002')),
 12.9716, 77.5946, 6.0, 22.0, 180.0,
 NOW() - INTERVAL '1 minute', 78, true, NOW() + INTERVAL '12 minutes',
 1.8, 4.1, NOW()),
((SELECT id FROM order_assignments WHERE order_id = (SELECT id FROM orders WHERE order_number = 'ORD-2025-002')),
 12.9705, 77.5935, 5.5, 30.0, 175.0,
 NOW() - INTERVAL '3 minutes', 80, true, NOW() + INTERVAL '15 minutes',
 2.1, 3.8, NOW()),

-- Tracking for Order 4 (DELIVERED) - Historical data
((SELECT id FROM order_assignments WHERE order_id = (SELECT id FROM orders WHERE order_number = 'ORD-2025-004')),
 12.9352, 77.6245, 3.0, 0.0, 0.0,
 NOW() - INTERVAL '1 day' + INTERVAL '15 minutes', 65, false, NULL,
 0.0, 8.5, NOW() - INTERVAL '1 day');

-- ========================================
-- 10. INSERT TEST DELIVERY ZONES
-- ========================================

INSERT INTO delivery_zones (
    zone_code, zone_name, boundaries, delivery_fee, min_order_amount,
    max_delivery_time, is_active, service_start_time, service_end_time,
    created_at, updated_at
) VALUES
('BLR_CENTRAL', 'Bangalore Central', 
 '{"type":"Polygon","coordinates":[[[77.5800,12.9600],[77.6000,12.9600],[77.6000,12.9800],[77.5800,12.9800],[77.5800,12.9600]]]}',
 30.00, 200.00, 45, true, '09:00:00', '23:00:00', NOW(), NOW()),
('BLR_NORTH', 'Bangalore North',
 '{"type":"Polygon","coordinates":[[[77.5600,12.9800],[77.6200,12.9800],[77.6200,13.0200],[77.5600,13.0200],[77.5600,12.9800]]]}',
 40.00, 250.00, 60, true, '08:00:00', '22:00:00', NOW(), NOW()),
('BLR_SOUTH', 'Bangalore South',
 '{"type":"Polygon","coordinates":[[[77.5500,12.8500],[77.6500,12.8500],[77.6500,12.9500],[77.5500,12.9500],[77.5500,12.8500]]]}',
 35.00, 300.00, 50, true, '09:00:00', '21:00:00', NOW(), NOW()),
('BLR_EAST', 'Bangalore East',
 '{"type":"Polygon","coordinates":[[[77.6000,12.9000],[77.7500,12.9000],[77.7500,13.0000],[77.6000,13.0000],[77.6000,12.9000]]]}',
 50.00, 400.00, 75, true, '10:00:00', '20:00:00', NOW(), NOW());

-- ========================================
-- 11. INSERT TEST PARTNER EARNINGS
-- ========================================

INSERT INTO partner_earnings (
    partner_id, assignment_id, earning_date, base_amount, bonus_amount,
    incentive_amount, penalty_amount, total_amount, payment_status,
    distance_covered, time_taken, surge_multiplier, created_at, updated_at
) VALUES
-- Earnings for Partner 1
((SELECT id FROM delivery_partners WHERE partner_id = 'DP00000001'),
 (SELECT id FROM order_assignments WHERE order_id = (SELECT id FROM orders WHERE order_number = 'ORD-2025-001')),
 CURRENT_DATE, 60.00, 10.00, 5.00, 0.00, 75.00, 'PENDING',
 3.2, 25, 1.20, NOW(), NOW()),
((SELECT id FROM delivery_partners WHERE partner_id = 'DP00000001'),
 (SELECT id FROM order_assignments WHERE order_id = (SELECT id FROM orders WHERE order_number = 'ORD-2025-004')),
 CURRENT_DATE - INTERVAL '1 day', 40.00, 5.00, 0.00, 0.00, 45.00, 'PAID',
 8.5, 45, 1.00, NOW() - INTERVAL '1 day', NOW()),

-- Earnings for Partner 2
((SELECT id FROM delivery_partners WHERE partner_id = 'DP00000002'),
 (SELECT id FROM order_assignments WHERE order_id = (SELECT id FROM orders WHERE order_number = 'ORD-2025-002')),
 CURRENT_DATE, 30.00, 8.00, 2.00, 0.00, 40.00, 'PENDING',
 4.1, 18, 1.10, NOW(), NOW()),

-- Earnings for Partner 3
((SELECT id FROM delivery_partners WHERE partner_id = 'DP00000003'),
 (SELECT id FROM order_assignments WHERE order_id = (SELECT id FROM orders WHERE order_number = 'ORD-2025-003')),
 CURRENT_DATE, 45.00, 0.00, 0.00, 5.00, 40.00, 'PENDING',
 0.0, 0, 1.00, NOW(), NOW());

-- ========================================
-- 12. INSERT TEST SHOP MANAGERS
-- ========================================

INSERT INTO shop_managers (shop_id, user_id, role, permissions, start_date, is_active, created_at, updated_at) VALUES
((SELECT id FROM shops WHERE name = 'TechWorld Electronics'), (SELECT id FROM users WHERE username = 'manager1'), 'STORE_MANAGER', '["INVENTORY_MANAGEMENT", "ORDER_PROCESSING", "CUSTOMER_SERVICE"]', '2024-01-01', true, NOW(), NOW()),
((SELECT id FROM shops WHERE name = 'Fresh Mart Grocery'), (SELECT id FROM users WHERE username = 'manager2'), 'ASSISTANT_MANAGER', '["ORDER_PROCESSING", "CUSTOMER_SERVICE"]', '2024-02-01', true, NOW(), NOW());

-- ========================================
-- 13. INSERT TEST INVENTORY LOGS
-- ========================================

INSERT INTO inventory_logs (product_id, change_type, quantity_change, previous_quantity, new_quantity, reason, reference_id, created_at, created_by) VALUES
-- Stock adjustments for Samsung Galaxy S24
((SELECT id FROM shop_products WHERE sku = 'SAM-S24-001'), 'ADJUSTMENT', -1, 26, 25, 'Sale - Order ORD-2025-001', (SELECT id FROM orders WHERE order_number = 'ORD-2025-001'), NOW() - INTERVAL '2 hours', 'system'),
((SELECT id FROM shop_products WHERE sku = 'SAM-S24-001'), 'RESTOCK', 10, 16, 26, 'New stock received', NULL, NOW() - INTERVAL '1 day', 'manager1'),

-- Stock adjustments for grocery items
((SELECT id FROM shop_products WHERE sku = 'ORG-TOM-001'), 'ADJUSTMENT', -2, 102, 100, 'Sale - Order ORD-2025-002', (SELECT id FROM orders WHERE order_number = 'ORD-2025-002'), NOW() - INTERVAL '1 hour', 'system'),
((SELECT id FROM shop_products WHERE sku = 'BAS-RICE-5KG'), 'ADJUSTMENT', -1, 51, 50, 'Sale - Order ORD-2025-002', (SELECT id FROM orders WHERE order_number = 'ORD-2025-002'), NOW() - INTERVAL '1 hour', 'system'),

-- Stock adjustments for clothing
((SELECT id FROM shop_products WHERE sku = 'MEN-SHIRT-001'), 'ADJUSTMENT', -1, 31, 30, 'Sale - Order ORD-2025-003', (SELECT id FROM orders WHERE order_number = 'ORD-2025-003'), NOW() - INTERVAL '6 hours', 'system'),
((SELECT id FROM shop_products WHERE sku = 'JEANS-001'), 'ADJUSTMENT', -1, 41, 40, 'Sale - Order ORD-2025-003', (SELECT id FROM orders WHERE order_number = 'ORD-2025-003'), NOW() - INTERVAL '6 hours', 'system');

-- ========================================
-- 14. VERIFICATION QUERIES
-- ========================================

-- Show summary of all inserted data
SELECT 'USERS' as table_name, COUNT(*) as record_count FROM users
UNION ALL
SELECT 'CUSTOMERS', COUNT(*) FROM customers
UNION ALL  
SELECT 'SHOPS', COUNT(*) FROM shops
UNION ALL
SELECT 'SHOP_PRODUCTS', COUNT(*) FROM shop_products
UNION ALL
SELECT 'ORDERS', COUNT(*) FROM orders
UNION ALL
SELECT 'ORDER_ITEMS', COUNT(*) FROM order_items
UNION ALL
SELECT 'DELIVERY_PARTNERS', COUNT(*) FROM delivery_partners
UNION ALL
SELECT 'ORDER_ASSIGNMENTS', COUNT(*) FROM order_assignments
UNION ALL
SELECT 'DELIVERY_TRACKING', COUNT(*) FROM delivery_tracking
UNION ALL
SELECT 'DELIVERY_ZONES', COUNT(*) FROM delivery_zones
UNION ALL
SELECT 'PARTNER_EARNINGS', COUNT(*) FROM partner_earnings
UNION ALL
SELECT 'SHOP_MANAGERS', COUNT(*) FROM shop_managers
UNION ALL
SELECT 'INVENTORY_LOGS', COUNT(*) FROM inventory_logs;

-- Show test users by role
SELECT 'TEST USERS BY ROLE:' as info;
SELECT role, COUNT(*) as user_count, STRING_AGG(username, ', ') as usernames
FROM users 
GROUP BY role 
ORDER BY role;

-- Show test shops with owners
SELECT 'TEST SHOPS:' as info;
SELECT s.name as shop_name, s.category, s.status, u.username as owner_username, u.first_name || ' ' || u.last_name as owner_name
FROM shops s
JOIN users u ON s.owner_id = u.id
ORDER BY s.name;

-- Show test orders with status
SELECT 'TEST ORDERS:' as info;
SELECT o.order_number, c.name as customer_name, s.name as shop_name, o.status, o.final_amount, o.payment_status
FROM orders o
JOIN customers c ON o.customer_id = c.id
JOIN shops s ON o.shop_id = s.id
ORDER BY o.order_number;

-- Show delivery partners status
SELECT 'DELIVERY PARTNERS:' as info;
SELECT dp.partner_id, dp.full_name, dp.vehicle_type, dp.status, dp.is_online, dp.is_available, dp.rating
FROM delivery_partners dp
ORDER BY dp.partner_id;

-- Show current order assignments
SELECT 'CURRENT ORDER ASSIGNMENTS:' as info;
SELECT oa.id, o.order_number, dp.full_name as partner_name, oa.status, oa.assigned_at
FROM order_assignments oa
JOIN orders o ON oa.order_id = o.id
JOIN delivery_partners dp ON oa.partner_id = dp.id
ORDER BY oa.assigned_at DESC;

-- Test login credentials information
SELECT 'TEST LOGIN CREDENTIALS:' as info;
SELECT 'All test accounts use password: password (encrypted as: $2a$10$N9qo8uLOickgx2ZMRJWqNOeWGuyqvvrVt3p/C4.WQ5FHC5yNEVJ/6)' as note;
SELECT role, username, email, first_name || ' ' || last_name as full_name
FROM users 
ORDER BY role, username;