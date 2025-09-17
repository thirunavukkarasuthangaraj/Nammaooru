-- Test data for Auto Assignment API demonstration
-- Insert some test delivery partners
INSERT INTO users (username, email, password, first_name, last_name, mobile_number, role,
                   is_online, is_available, ride_status, email_verified, mobile_verified, created_at)
VALUES
    ('testpartner1', 'partner1@test.com', '$2a$10$example', 'John', 'Smith', '+919876543210', 'DELIVERY_PARTNER',
     true, true, 'AVAILABLE', true, true, CURRENT_TIMESTAMP),
    ('testpartner2', 'partner2@test.com', '$2a$10$example', 'Sarah', 'Wilson', '+919876543211', 'DELIVERY_PARTNER',
     true, true, 'AVAILABLE', true, true, CURRENT_TIMESTAMP),
    ('testpartner3', 'partner3@test.com', '$2a$10$example', 'Mike', 'Johnson', '+919876543212', 'DELIVERY_PARTNER',
     false, false, 'OFFLINE', true, true, CURRENT_TIMESTAMP);

-- Insert a test customer
INSERT INTO users (username, email, password, first_name, last_name, mobile_number, role,
                   email_verified, mobile_verified, created_at)
VALUES
    ('testcustomer', 'customer@test.com', '$2a$10$example', 'Test', 'Customer', '+919999999999', 'USER',
     true, true, CURRENT_TIMESTAMP);

-- Insert a test shop owner
INSERT INTO users (username, email, password, first_name, last_name, mobile_number, role,
                   email_verified, mobile_verified, created_at)
VALUES
    ('testshopowner', 'shopowner@test.com', '$2a$10$example', 'Shop', 'Owner', '+918888888888', 'SHOP_OWNER',
     true, true, CURRENT_TIMESTAMP);

-- Insert a test shop
INSERT INTO shops (name, owner_phone, address_line1, city, state, postal_code, latitude, longitude,
                   approval_status, created_at)
VALUES
    ('Test Shop', '+918888888888', '123 Test Street', 'Chennai', 'Tamil Nadu', '600001',
     13.0827, 80.2707, 'APPROVED', CURRENT_TIMESTAMP);

-- Insert a test order ready for pickup
INSERT INTO orders (order_number, customer_id, shop_id, status, total_amount, delivery_address,
                    delivery_fee, payment_method, created_at)
VALUES
    ('TEST-ORD-001',
     (SELECT id FROM users WHERE email = 'customer@test.com'),
     (SELECT id FROM shops WHERE name = 'Test Shop'),
     'READY_FOR_PICKUP',
     850.00,
     '456 Customer Street, T.Nagar, Chennai - 600017',
     50.00,
     'COD',
     CURRENT_TIMESTAMP);