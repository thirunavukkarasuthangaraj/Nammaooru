-- Test data for shop management system delivery functionality  
-- Run this in pgAdmin query editor for postgres database

-- First, let's check existing tables
SELECT table_name FROM information_schema.tables WHERE table_schema = 'public' ORDER BY table_name;

-- Insert test users (delivery partners will reference these)
INSERT INTO users (username, email, password, first_name, last_name, role, status, email_verified, mobile_verified, two_factor_enabled, failed_login_attempts, password_change_required, is_temporary_password, created_at, updated_at) VALUES
('partner1', 'raj.kumar@delivery.com', '$2a$10$N9qo8uLOickgx2ZMRJWqNOeWGuyqvvrVt3p/C4.WQ5FHC5yNEVJ/6', 'Raj', 'Kumar', 'DELIVERY_PARTNER', 'ACTIVE', true, true, false, 0, false, false, NOW(), NOW()),
('partner2', 'priya.sharma@delivery.com', '$2a$10$N9qo8uLOickgx2ZMRJWqNOeWGuyqvvrVt3p/C4.WQ5FHC5yNEVJ/6', 'Priya', 'Sharma', 'DELIVERY_PARTNER', 'ACTIVE', true, true, false, 0, false, false, NOW(), NOW()),
('partner3', 'amit.singh@delivery.com', '$2a$10$N9qo8uLOickgx2ZMRJWqNOeWGuyqvvrVt3p/C4.WQ5FHC5yNEVJ/6', 'Amit', 'Singh', 'DELIVERY_PARTNER', 'ACTIVE', true, true, false, 0, false, false, NOW(), NOW());

-- Insert test customers
INSERT INTO customers (name, email, phone, address_line_1, city, state, postal_code, created_at, updated_at) VALUES
('John Doe', 'john.doe@customer.com', '+919876543210', '123 MG Road', 'Bangalore', 'Karnataka', '560001', NOW(), NOW()),
('Jane Smith', 'jane.smith@customer.com', '+919876543211', '456 Brigade Road', 'Bangalore', 'Karnataka', '560002', NOW(), NOW()),
('Mike Johnson', 'mike.johnson@customer.com', '+919876543212', '789 Commercial Street', 'Bangalore', 'Karnataka', '560003', NOW(), NOW());

-- Insert test delivery partners
INSERT INTO delivery_partners (
    partner_id, user_id, full_name, phone_number, email, date_of_birth, gender,
    address_line1, city, state, postal_code, country,
    vehicle_type, vehicle_number, vehicle_model, vehicle_color,
    license_number, license_expiry_date,
    bank_account_number, bank_ifsc_code, bank_name, account_holder_name,
    max_delivery_radius, status, verification_status,
    is_online, is_available, rating, total_deliveries, successful_deliveries, total_earnings,
    current_latitude, current_longitude, last_location_update, last_seen,
    created_at, updated_at, created_by, updated_by
) VALUES
(
    'DP00000001', 
    (SELECT id FROM users WHERE username = 'partner1'),
    'Raj Kumar', '+919876543210', 'raj.kumar@delivery.com', '1990-01-15', 'MALE',
    '123 Electronic City', 'Bangalore', 'Karnataka', '560100', 'India',
    'BIKE', 'KA05AB1234', 'Honda CB Shine', 'Red',
    'KA1234567890', '2025-12-31',
    '1234567890', 'HDFC0001234', 'HDFC Bank', 'Raj Kumar',
    15.00, 'ACTIVE', 'VERIFIED',
    true, true, 4.8, 150, 145, 25000.00,
    12.9700, 77.5930, NOW() - INTERVAL '2 minutes', NOW() - INTERVAL '1 minute',
    NOW(), NOW(), 'system', 'system'
),
(
    'DP00000002',
    (SELECT id FROM users WHERE username = 'partner2'),
    'Priya Sharma', '+919876543211', 'priya.sharma@delivery.com', '1992-03-20', 'FEMALE',
    '456 Whitefield', 'Bangalore', 'Karnataka', '560066', 'India',
    'SCOOTER', 'KA05CD5678', 'Honda Activa', 'Blue',
    'KA2345678901', '2025-10-31',
    '2345678901', 'ICICI0002345', 'ICICI Bank', 'Priya Sharma',
    12.00, 'ACTIVE', 'VERIFIED',
    true, true, 4.9, 200, 195, 35000.00,
    12.9716, 77.5946, NOW() - INTERVAL '1 minute', NOW() - INTERVAL '30 seconds',
    NOW(), NOW(), 'system', 'system'
),
(
    'DP00000003',
    (SELECT id FROM users WHERE username = 'partner3'),
    'Amit Singh', '+919876543212', 'amit.singh@delivery.com', '1988-07-10', 'MALE',
    '789 Koramangala', 'Bangalore', 'Karnataka', '560034', 'India',
    'BIKE', 'KA05EF9012', 'Bajaj Pulsar', 'Black',
    'KA3456789012', '2025-08-31',
    '3456789012', 'SBI0003456', 'State Bank of India', 'Amit Singh',
    20.00, 'ACTIVE', 'VERIFIED',
    false, false, 4.7, 100, 98, 18000.00,
    12.9500, 77.6000, NOW() - INTERVAL '5 minutes', NOW() - INTERVAL '3 minutes',
    NOW(), NOW(), 'system', 'system'
);

-- Insert test orders
INSERT INTO orders (
    order_number, customer_id, total_amount, status, delivery_address,
    delivery_latitude, delivery_longitude, order_date, created_at, updated_at
) VALUES
('ORD-2025-001', 
 (SELECT id FROM customers WHERE email = 'john.doe@customer.com'),
 450.00, 'CONFIRMED', '123 MG Road, Bangalore, Karnataka 560001',
 12.9716, 77.5946, NOW(), NOW(), NOW()),
('ORD-2025-002',
 (SELECT id FROM customers WHERE email = 'jane.smith@customer.com'), 
 275.00, 'CONFIRMED', '456 Brigade Road, Bangalore, Karnataka 560002',
 12.9750, 77.6010, NOW(), NOW(), NOW()),
('ORD-2025-003',
 (SELECT id FROM customers WHERE email = 'mike.johnson@customer.com'),
 320.00, 'CONFIRMED', '789 Commercial Street, Bangalore, Karnataka 560003',
 12.9800, 77.6050, NOW(), NOW(), NOW());

-- Insert test order assignments
INSERT INTO order_assignments (
    order_id, partner_id, assigned_at, assignment_type, status,
    delivery_fee, partner_commission,
    pickup_latitude, pickup_longitude, delivery_latitude, delivery_longitude,
    accepted_at, pickup_time, delivery_time,
    created_at, updated_at
) VALUES
(
    (SELECT id FROM orders WHERE order_number = 'ORD-2025-001'),
    (SELECT id FROM delivery_partners WHERE partner_id = 'DP00000001'),
    NOW() - INTERVAL '30 minutes', 'AUTO', 'IN_TRANSIT',
    45.00, 25.00,
    12.9650, 77.5880, 12.9716, 77.5946,
    NOW() - INTERVAL '25 minutes', NOW() - INTERVAL '15 minutes', NULL,
    NOW(), NOW()
),
(
    (SELECT id FROM orders WHERE order_number = 'ORD-2025-002'),
    (SELECT id FROM delivery_partners WHERE partner_id = 'DP00000002'),
    NOW() - INTERVAL '20 minutes', 'AUTO', 'PICKED_UP',
    35.00, 20.00,
    12.9680, 77.5920, 12.9750, 77.6010,
    NOW() - INTERVAL '18 minutes', NOW() - INTERVAL '5 minutes', NULL,
    NOW(), NOW()
),
(
    (SELECT id FROM orders WHERE order_number = 'ORD-2025-003'),
    (SELECT id FROM delivery_partners WHERE partner_id = 'DP00000003'),
    NOW() - INTERVAL '10 minutes', 'MANUAL', 'ASSIGNED',
    40.00, 22.00,
    12.9600, 77.5800, 12.9800, 77.6050,
    NULL, NULL, NULL,
    NOW(), NOW()
);

-- Insert test delivery tracking data
INSERT INTO delivery_tracking (
    assignment_id, latitude, longitude, accuracy, speed, heading,
    tracked_at, battery_level, is_moving, estimated_arrival_time,
    distance_to_destination, distance_traveled, created_at
) VALUES
-- Tracking for Order 1 (IN_TRANSIT)
(
    (SELECT id FROM order_assignments WHERE order_id = (SELECT id FROM orders WHERE order_number = 'ORD-2025-001')),
    12.9700, 77.5930, 5.0, 25.5, 45.0,
    NOW() - INTERVAL '2 minutes', 85, true, NOW() + INTERVAL '15 minutes',
    2.5, 3.2, NOW()
),
(
    (SELECT id FROM order_assignments WHERE order_id = (SELECT id FROM orders WHERE order_number = 'ORD-2025-001')),
    12.9690, 77.5920, 4.5, 28.0, 42.0,
    NOW() - INTERVAL '5 minutes', 83, true, NOW() + INTERVAL '18 minutes',
    2.8, 2.8, NOW()
),
-- Tracking for Order 2 (PICKED_UP)
(
    (SELECT id FROM order_assignments WHERE order_id = (SELECT id FROM orders WHERE order_number = 'ORD-2025-002')),
    12.9716, 77.5946, 6.0, 22.0, 180.0,
    NOW() - INTERVAL '1 minute', 78, true, NOW() + INTERVAL '12 minutes',
    1.8, 4.1, NOW()
),
(
    (SELECT id FROM order_assignments WHERE order_id = (SELECT id FROM orders WHERE order_number = 'ORD-2025-002')),
    12.9705, 77.5935, 5.5, 30.0, 175.0,
    NOW() - INTERVAL '3 minutes', 80, true, NOW() + INTERVAL '15 minutes',
    2.1, 3.8, NOW()
);

-- Insert test delivery zones
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
 40.00, 250.00, 60, true, '08:00:00', '22:00:00', NOW(), NOW());

-- Insert test partner earnings
INSERT INTO partner_earnings (
    partner_id, assignment_id, earning_date, base_amount, bonus_amount,
    incentive_amount, penalty_amount, total_amount, payment_status,
    distance_covered, time_taken, surge_multiplier, created_at, updated_at
) VALUES
(
    (SELECT id FROM delivery_partners WHERE partner_id = 'DP00000001'),
    (SELECT id FROM order_assignments WHERE order_id = (SELECT id FROM orders WHERE order_number = 'ORD-2025-001')),
    CURRENT_DATE, 25.00, 5.00, 0.00, 0.00, 30.00, 'PENDING',
    3.2, 25, 1.00, NOW(), NOW()
),
(
    (SELECT id FROM delivery_partners WHERE partner_id = 'DP00000002'),
    (SELECT id FROM order_assignments WHERE order_id = (SELECT id FROM orders WHERE order_number = 'ORD-2025-002')),
    CURRENT_DATE, 20.00, 3.00, 2.00, 0.00, 25.00, 'PENDING',
    4.1, 18, 1.00, NOW(), NOW()
);

-- Verify the data was inserted correctly
SELECT 'Delivery Partners' as table_name, COUNT(*) as record_count FROM delivery_partners
UNION ALL
SELECT 'Orders', COUNT(*) FROM orders
UNION ALL  
SELECT 'Order Assignments', COUNT(*) FROM order_assignments
UNION ALL
SELECT 'Delivery Tracking', COUNT(*) FROM delivery_tracking
UNION ALL
SELECT 'Delivery Zones', COUNT(*) FROM delivery_zones
UNION ALL
SELECT 'Partner Earnings', COUNT(*) FROM partner_earnings;

-- Show the test data
SELECT 'DELIVERY PARTNERS:' as info;
SELECT dp.partner_id, dp.full_name, dp.phone_number, dp.vehicle_type, dp.vehicle_number, 
       dp.status, dp.is_online, dp.is_available, dp.rating, dp.total_deliveries
FROM delivery_partners dp;

SELECT 'ORDER ASSIGNMENTS:' as info;
SELECT oa.id, o.order_number, dp.full_name as partner_name, oa.status, 
       oa.delivery_fee, oa.assigned_at, oa.accepted_at
FROM order_assignments oa
JOIN orders o ON oa.order_id = o.id
JOIN delivery_partners dp ON oa.partner_id = dp.id;

SELECT 'LATEST TRACKING:' as info;
SELECT dt.id, o.order_number, dp.full_name as partner_name,
       dt.latitude, dt.longitude, dt.speed, dt.tracked_at, dt.battery_level
FROM delivery_tracking dt
JOIN order_assignments oa ON dt.assignment_id = oa.id
JOIN orders o ON oa.order_id = o.id
JOIN delivery_partners dp ON oa.partner_id = dp.id
ORDER BY dt.tracked_at DESC;