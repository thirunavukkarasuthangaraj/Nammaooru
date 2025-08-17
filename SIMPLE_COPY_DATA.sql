-- =====================================================
-- SIMPLE METHOD TO COPY DATA
-- =====================================================
-- Step 1: First connect to postgres database in pgAdmin
-- Step 2: Run this query to see all data:

-- IN POSTGRES DATABASE:
SELECT * FROM users;
SELECT * FROM customers;
SELECT * FROM delivery_zones;
SELECT * FROM delivery_partners;

-- Step 3: Export each table to CSV using pgAdmin (right-click table -> Export)
-- Step 4: Connect to shop_management_db database
-- Step 5: Import the CSV files into shop_management_db

-- OR USE THIS SIMPLER APPROACH:
-- =====================================================
-- RUN IN shop_management_db DATABASE
-- This directly inserts the test data
-- =====================================================

-- Clear existing data first (optional)
DELETE FROM delivery_tracking;
DELETE FROM order_assignments;
DELETE FROM delivery_partners;
DELETE FROM delivery_zones;
DELETE FROM orders;
DELETE FROM customers;
DELETE FROM users;

-- Insert test users with ALL fields properly set
INSERT INTO users (username, email, password, first_name, last_name, role, status, is_active, email_verified, mobile_verified, two_factor_enabled, failed_login_attempts, password_change_required, is_temporary_password, created_at, updated_at, created_by, updated_by) VALUES
-- Super Admin (password: password)
('superadmin', 'superadmin@shopmanagement.com', '$2a$10$N9qo8uLOickgx2ZMRJWqNOeWGuyqvvrVt3p/C4.WQ5FHC5yNEVJ/6', 'Super', 'Admin', 'SUPER_ADMIN', 'ACTIVE', true, true, true, false, 0, false, false, NOW(), NOW(), 'system', 'system'),
-- Admin
('admin1', 'admin1@shopmanagement.com', '$2a$10$N9qo8uLOickgx2ZMRJWqNOeWGuyqvvrVt3p/C4.WQ5FHC5yNEVJ/6', 'Admin', 'One', 'ADMIN', 'ACTIVE', true, true, true, false, 0, false, false, NOW(), NOW(), 'system', 'system'),
-- Shop Owners
('shopowner1', 'owner1@electronics.com', '$2a$10$N9qo8uLOickgx2ZMRJWqNOeWGuyqvvrVt3p/C4.WQ5FHC5yNEVJ/6', 'Rajesh', 'Kumar', 'SHOP_OWNER', 'ACTIVE', true, true, true, false, 0, false, false, NOW(), NOW(), 'system', 'system'),
('shopowner2', 'owner2@grocery.com', '$2a$10$N9qo8uLOickgx2ZMRJWqNOeWGuyqvvrVt3p/C4.WQ5FHC5yNEVJ/6', 'Priya', 'Sharma', 'SHOP_OWNER', 'ACTIVE', true, true, true, false, 0, false, false, NOW(), NOW(), 'system', 'system'),
-- Manager
('manager1', 'manager1@electronics.com', '$2a$10$N9qo8uLOickgx2ZMRJWqNOeWGuyqvvrVt3p/C4.WQ5FHC5yNEVJ/6', 'Suresh', 'Reddy', 'MANAGER', 'ACTIVE', true, true, true, false, 0, false, false, NOW(), NOW(), 'system', 'system'),
-- Delivery Partners
('delivery1', 'raj.kumar@delivery.com', '$2a$10$N9qo8uLOickgx2ZMRJWqNOeWGuyqvvrVt3p/C4.WQ5FHC5yNEVJ/6', 'Raj', 'Kumar', 'DELIVERY_PARTNER', 'ACTIVE', true, true, true, false, 0, false, false, NOW(), NOW(), 'system', 'system'),
('delivery2', 'priya.delivery@gmail.com', '$2a$10$N9qo8uLOickgx2ZMRJWqNOeWGuyqvvrVt3p/C4.WQ5FHC5yNEVJ/6', 'Priya', 'Devi', 'DELIVERY_PARTNER', 'ACTIVE', true, true, true, false, 0, false, false, NOW(), NOW(), 'system', 'system'),
-- Regular User
('user1', 'user1@example.com', '$2a$10$N9qo8uLOickgx2ZMRJWqNOeWGuyqvvrVt3p/C4.WQ5FHC5yNEVJ/6', 'Regular', 'User', 'USER', 'ACTIVE', true, true, true, false, 0, false, false, NOW(), NOW(), 'system', 'system');

-- Insert test customers
INSERT INTO customers (first_name, last_name, email, mobile_number, address_line1, address_line2, city, state, postal_code, country, date_of_birth, gender, latitude, longitude, status, is_active, is_verified, created_at, updated_at, created_by, updated_by) VALUES
('John', 'Doe', 'john.doe@customer.com', '+919876543210', '123 MG Road', 'Near Metro Station', 'Bangalore', 'Karnataka', '560001', 'India', '1985-06-15', 'MALE', 12.9716, 77.5946, 'ACTIVE', true, true, NOW(), NOW(), 'system', 'system'),
('Jane', 'Smith', 'jane.smith@customer.com', '+919876543211', '456 Brigade Road', 'Commercial Street Area', 'Bangalore', 'Karnataka', '560002', 'India', '1990-03-20', 'FEMALE', 12.9750, 77.6010, 'ACTIVE', true, true, NOW(), NOW(), 'system', 'system'),
('Mike', 'Johnson', 'mike.johnson@customer.com', '+919876543212', '789 Commercial Street', 'Near Forum Mall', 'Bangalore', 'Karnataka', '560003', 'India', '1988-12-05', 'MALE', 12.9800, 77.6050, 'ACTIVE', true, true, NOW(), NOW(), 'system', 'system');

-- Insert delivery zones
INSERT INTO delivery_zones (zone_code, zone_name, boundaries, delivery_fee, min_order_amount, max_delivery_time, is_active, service_start_time, service_end_time, created_at, updated_at) VALUES
('BLR_CENTRAL', 'Bangalore Central', '{"type":"Polygon","coordinates":[[[77.5800,12.9600],[77.6000,12.9600],[77.6000,12.9800],[77.5800,12.9800],[77.5800,12.9600]]]}', 30.00, 200.00, 45, true, '09:00:00', '23:00:00', NOW(), NOW()),
('BLR_NORTH', 'Bangalore North', '{"type":"Polygon","coordinates":[[[77.5600,12.9800],[77.6200,12.9800],[77.6200,13.0200],[77.5600,13.0200],[77.5600,12.9800]]]}', 40.00, 250.00, 60, true, '08:00:00', '22:00:00', NOW(), NOW()),
('BLR_SOUTH', 'Bangalore South', '{"type":"Polygon","coordinates":[[[77.5500,12.8500],[77.6500,12.8500],[77.6500,12.9500],[77.5500,12.9500],[77.5500,12.8500]]]}', 35.00, 300.00, 50, true, '09:00:00', '21:00:00', NOW(), NOW());

-- Insert delivery partners
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
 12.9700, 77.5930, NOW(), NOW(),
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
 12.9716, 77.5946, NOW(), NOW(),
 NOW(), NOW(), 'system', 'system');

-- Verify data
SELECT 'DATA INSERTED SUCCESSFULLY!' as status;
SELECT 'Users: ' || COUNT(*) as count FROM users;
SELECT 'Customers: ' || COUNT(*) as count FROM customers;
SELECT 'Delivery Zones: ' || COUNT(*) as count FROM delivery_zones;
SELECT 'Delivery Partners: ' || COUNT(*) as count FROM delivery_partners;

-- Show login credentials
SELECT '===== LOGIN CREDENTIALS =====' as info;
SELECT 'All passwords are: password' as note;
SELECT username, role, email, is_active FROM users WHERE is_active = true ORDER BY role;