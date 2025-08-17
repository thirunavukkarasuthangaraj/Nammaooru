-- Corrected test data for shop management system  
-- Run this in pgAdmin query editor for postgres database
-- Based on actual database schema

-- ========================================
-- 1. INSERT TEST USERS (Corrected Roles)
-- ========================================

-- Insert users with correct role names from check constraint
INSERT INTO users (username, email, password, first_name, last_name, role, status, email_verified, mobile_verified, two_factor_enabled, failed_login_attempts, password_change_required, is_temporary_password, created_at, updated_at, created_by, updated_by) VALUES
-- Super Admin  
('superadmin', 'superadmin@shopmanagement.com', '$2a$10$N9qo8uLOickgx2ZMRJWqNOeWGuyqvvrVt3p/C4.WQ5FHC5yNEVJ/6', 'Super', 'Admin', 'SUPER_ADMIN', 'ACTIVE', true, true, false, 0, false, false, NOW(), NOW(), 'system', 'system'),
-- Admins
('admin1', 'admin1@shopmanagement.com', '$2a$10$N9qo8uLOickgx2ZMRJWqNOeWGuyqvvrVt3p/C4.WQ5FHC5yNEVJ/6', 'Admin', 'One', 'ADMIN', 'ACTIVE', true, true, false, 0, false, false, NOW(), NOW(), 'system', 'system'),
('admin2', 'admin2@shopmanagement.com', '$2a$10$N9qo8uLOickgx2ZMRJWqNOeWGuyqvvrVt3p/C4.WQ5FHC5yNEVJ/6', 'Admin', 'Two', 'ADMIN', 'ACTIVE', true, true, false, 0, false, false, NOW(), NOW(), 'system', 'system'),
-- Shop Owners
('shopowner1', 'owner1@electronics.com', '$2a$10$N9qo8uLOickgx2ZMRJWqNOeWGuyqvvrVt3p/C4.WQ5FHC5yNEVJ/6', 'Rajesh', 'Kumar', 'SHOP_OWNER', 'ACTIVE', true, true, false, 0, false, false, NOW(), NOW(), 'system', 'system'),
('shopowner2', 'owner2@grocery.com', '$2a$10$N9qo8uLOickgx2ZMRJWqNOeWGuyqvvrVt3p/C4.WQ5FHC5yNEVJ/6', 'Priya', 'Sharma', 'SHOP_OWNER', 'ACTIVE', true, true, false, 0, false, false, NOW(), NOW(), 'system', 'system'),
('shopowner3', 'owner3@clothing.com', '$2a$10$N9qo8uLOickgx2ZMRJWqNOeWGuyqvvrVt3p/C4.WQ5FHC5yNEVJ/6', 'Amit', 'Singh', 'SHOP_OWNER', 'ACTIVE', true, true, false, 0, false, false, NOW(), NOW(), 'system', 'system'),
-- Managers
('manager1', 'manager1@electronics.com', '$2a$10$N9qo8uLOickgx2ZMRJWqNOeWGuyqvvrVt3p/C4.WQ5FHC5yNEVJ/6', 'Suresh', 'Reddy', 'MANAGER', 'ACTIVE', true, true, false, 0, false, false, NOW(), NOW(), 'system', 'system'),
('manager2', 'manager2@grocery.com', '$2a$10$N9qo8uLOickgx2ZMRJWqNOeWGuyqvvrVt3p/C4.WQ5FHC5yNEVJ/6', 'Kavitha', 'Nair', 'MANAGER', 'ACTIVE', true, true, false, 0, false, false, NOW(), NOW(), 'system', 'system'),
-- Delivery Agents (correct role name)
('delivery1', 'raj.kumar@delivery.com', '$2a$10$N9qo8uLOickgx2ZMRJWqNOeWGuyqvvrVt3p/C4.WQ5FHC5yNEVJ/6', 'Raj', 'Kumar', 'DELIVERY_AGENT', 'ACTIVE', true, true, false, 0, false, false, NOW(), NOW(), 'system', 'system'),
('delivery2', 'priya.delivery@gmail.com', '$2a$10$N9qo8uLOickgx2ZMRJWqNOeWGuyqvvrVt3p/C4.WQ5FHC5yNEVJ/6', 'Priya', 'Devi', 'DELIVERY_AGENT', 'ACTIVE', true, true, false, 0, false, false, NOW(), NOW(), 'system', 'system'),
('delivery3', 'amit.delivery@gmail.com', '$2a$10$N9qo8uLOickgx2ZMRJWqNOeWGuyqvvrVt3p/C4.WQ5FHC5yNEVJ/6', 'Amit', 'Gupta', 'DELIVERY_AGENT', 'ACTIVE', true, true, false, 0, false, false, NOW(), NOW(), 'system', 'system'),
-- Customer Service
('cs1', 'cs1@shopmanagement.com', '$2a$10$N9qo8uLOickgx2ZMRJWqNOeWGuyqvvrVt3p/C4.WQ5FHC5yNEVJ/6', 'Customer', 'Service', 'CUSTOMER_SERVICE', 'ACTIVE', true, true, false, 0, false, false, NOW(), NOW(), 'system', 'system'),
-- Regular Users
('user1', 'user1@example.com', '$2a$10$N9qo8uLOickgx2ZMRJWqNOeWGuyqvvrVt3p/C4.WQ5FHC5yNEVJ/6', 'Regular', 'User', 'USER', 'ACTIVE', true, true, false, 0, false, false, NOW(), NOW(), 'system', 'system');

-- ========================================
-- 2. INSERT TEST CUSTOMERS (Corrected Schema)
-- ========================================

INSERT INTO customers (first_name, last_name, email, mobile_number, address_line1, address_line2, city, state, postal_code, country, date_of_birth, gender, latitude, longitude, status, is_active, is_verified, created_at, updated_at, created_by, updated_by) VALUES
('John', 'Doe', 'john.doe@customer.com', '+919876543210', '123 MG Road', 'Near Metro Station', 'Bangalore', 'Karnataka', '560001', 'India', '1985-06-15', 'MALE', 12.9716, 77.5946, 'ACTIVE', true, true, NOW(), NOW(), 'system', 'system'),
('Jane', 'Smith', 'jane.smith@customer.com', '+919876543211', '456 Brigade Road', 'Commercial Street Area', 'Bangalore', 'Karnataka', '560002', 'India', '1990-03-20', 'FEMALE', 12.9750, 77.6010, 'ACTIVE', true, true, NOW(), NOW(), 'system', 'system'),
('Mike', 'Johnson', 'mike.johnson@customer.com', '+919876543212', '789 Commercial Street', 'Near Forum Mall', 'Bangalore', 'Karnataka', '560003', 'India', '1988-12-05', 'MALE', 12.9800, 77.6050, 'ACTIVE', true, true, NOW(), NOW(), 'system', 'system'),
('Sarah', 'Wilson', 'sarah.wilson@customer.com', '+919876543213', '321 Koramangala', '5th Block', 'Bangalore', 'Karnataka', '560034', 'India', '1992-09-18', 'FEMALE', 12.9352, 77.6245, 'ACTIVE', true, true, NOW(), NOW(), 'system', 'system'),
('David', 'Brown', 'david.brown@customer.com', '+919876543214', '654 Whitefield', 'ITPL Road', 'Bangalore', 'Karnataka', '560066', 'India', '1987-04-12', 'MALE', 12.9698, 77.7500, 'ACTIVE', true, true, NOW(), NOW(), 'system', 'system');

-- ========================================
-- 3. INSERT TEST DELIVERY PARTNERS (Corrected Schema)
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
('DP001', 
 (SELECT id FROM users WHERE username = 'delivery1'),
 'Raj Kumar', '+919876543210', 'raj.kumar@delivery.com', '1990-01-15', 'MALE',
 '123 Electronic City', 'Phase 1', 'Bangalore', 'Karnataka', '560100', 'India',
 'BIKE', 'KA05AB1234', 'Honda CB Shine', 'Red',
 'KA1234567890', '2025-12-31',
 '123456789012', 'HDFC0001234', 'HDFC Bank', 'Raj Kumar',
 15.00, 'ACTIVE', 'VERIFIED',
 true, true, 4.8, 150, 145, 25000.00,
 12.9700, 77.5930, NOW() - INTERVAL '2 minutes', NOW() - INTERVAL '1 minute',
 NOW(), NOW(), 'system', 'system'),
('DP002',
 (SELECT id FROM users WHERE username = 'delivery2'),
 'Priya Devi', '+919876543211', 'priya.delivery@gmail.com', '1992-03-20', 'FEMALE',
 '456 Whitefield', 'Main Road', 'Bangalore', 'Karnataka', '560066', 'India',
 'SCOOTER', 'KA05CD5678', 'Honda Activa', 'Blue',
 'KA2345678901', '2025-10-31',
 '234567890123', 'ICICI0002345', 'ICICI Bank', 'Priya Devi',
 12.00, 'ACTIVE', 'VERIFIED',
 true, true, 4.9, 200, 195, 35000.00,
 12.9716, 77.5946, NOW() - INTERVAL '1 minute', NOW() - INTERVAL '30 seconds',
 NOW(), NOW(), 'system', 'system'),
('DP003',
 (SELECT id FROM users WHERE username = 'delivery3'),
 'Amit Gupta', '+919876543212', 'amit.delivery@gmail.com', '1988-07-10', 'MALE',
 '789 Koramangala', '5th Block', 'Bangalore', 'Karnataka', '560034', 'India',
 'BIKE', 'KA05EF9012', 'Bajaj Pulsar', 'Black',
 'KA3456789012', '2025-08-31',
 '345678901234', 'SBI0003456', 'State Bank of India', 'Amit Gupta',
 20.00, 'ACTIVE', 'VERIFIED',
 false, false, 4.7, 100, 98, 18000.00,
 12.9500, 77.6000, NOW() - INTERVAL '5 minutes', NOW() - INTERVAL '3 minutes',
 NOW(), NOW(), 'system', 'system');

-- ========================================
-- 4. INSERT TEST DELIVERY ZONES
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
-- 5. CREATE SOME TEST ORDERS (Simple version)
-- ========================================

-- First check if we have any existing orders
SELECT COUNT(*) as existing_orders FROM orders;

-- Insert basic test order data if table structure permits
-- Note: Actual order insertion may need to be done through the application
-- due to complex relationships and business logic

-- ========================================
-- 6. VERIFICATION QUERIES
-- ========================================

-- Show summary of inserted data
SELECT 'USERS' as table_name, COUNT(*) as record_count FROM users
UNION ALL
SELECT 'CUSTOMERS', COUNT(*) FROM customers
UNION ALL  
SELECT 'DELIVERY_PARTNERS', COUNT(*) FROM delivery_partners
UNION ALL
SELECT 'DELIVERY_ZONES', COUNT(*) FROM delivery_zones
UNION ALL
SELECT 'ORDERS', COUNT(*) FROM orders
UNION ALL
SELECT 'ORDER_ASSIGNMENTS', COUNT(*) FROM order_assignments
UNION ALL
SELECT 'DELIVERY_TRACKING', COUNT(*) FROM delivery_tracking;

-- Show test users by role
SELECT 'TEST USERS BY ROLE:' as info;
SELECT role, COUNT(*) as user_count, STRING_AGG(username, ', ') as usernames
FROM users 
GROUP BY role 
ORDER BY role;

-- Show test customers
SELECT 'TEST CUSTOMERS:' as info;
SELECT first_name || ' ' || last_name as full_name, email, mobile_number, city, status
FROM customers 
ORDER BY first_name;

-- Show delivery partners
SELECT 'DELIVERY PARTNERS:' as info;
SELECT dp.partner_id, dp.full_name, dp.vehicle_type, dp.status, dp.is_online, dp.is_available, dp.rating
FROM delivery_partners dp
ORDER BY dp.partner_id;

-- Show delivery zones
SELECT 'DELIVERY ZONES:' as info;
SELECT zone_code, zone_name, delivery_fee, min_order_amount, is_active
FROM delivery_zones
ORDER BY zone_code;

-- Test login credentials information
SELECT 'TEST LOGIN CREDENTIALS:' as info;
SELECT 'All test accounts use password: password (encrypted as: $2a$10$N9qo8uLOickgx2ZMRJWqNOeWGuyqvvrVt3p/C4.WQ5FHC5yNEVJ/6)' as note;
SELECT role, username, email, first_name || ' ' || last_name as full_name
FROM users 
WHERE username IN ('superadmin', 'admin1', 'admin2', 'shopowner1', 'shopowner2', 'shopowner3', 'manager1', 'manager2', 'delivery1', 'delivery2', 'delivery3', 'cs1', 'user1')
ORDER BY role, username;