-- Clear existing data and insert fresh test data
DELETE FROM delivery_tracking;
DELETE FROM order_assignments;  
DELETE FROM delivery_partners;
DELETE FROM delivery_zones;
DELETE FROM orders;
DELETE FROM customers;
DELETE FROM users;

-- Insert users with proper is_active field
INSERT INTO users (username, email, password, first_name, last_name, role, status, is_active, email_verified, mobile_verified, two_factor_enabled, failed_login_attempts, password_change_required, is_temporary_password, created_at, updated_at, created_by, updated_by) VALUES
('superadmin', 'superadmin@shopmanagement.com', '$2a$10$N9qo8uLOickgx2ZMRJWqNOeWGuyqvvrVt3p/C4.WQ5FHC5yNEVJ/6', 'Super', 'Admin', 'SUPER_ADMIN', 'ACTIVE', true, true, true, false, 0, false, false, NOW(), NOW(), 'system', 'system'),
('admin1', 'admin1@shopmanagement.com', '$2a$10$N9qo8uLOickgx2ZMRJWqNOeWGuyqvvrVt3p/C4.WQ5FHC5yNEVJ/6', 'Admin', 'One', 'ADMIN', 'ACTIVE', true, true, true, false, 0, false, false, NOW(), NOW(), 'system', 'system'),
('shopowner1', 'owner1@electronics.com', '$2a$10$N9qo8uLOickgx2ZMRJWqNOeWGuyqvvrVt3p/C4.WQ5FHC5yNEVJ/6', 'Rajesh', 'Kumar', 'SHOP_OWNER', 'ACTIVE', true, true, true, false, 0, false, false, NOW(), NOW(), 'system', 'system'),
('delivery1', 'raj.kumar@delivery.com', '$2a$10$N9qo8uLOickgx2ZMRJWqNOeWGuyqvvrVt3p/C4.WQ5FHC5yNEVJ/6', 'Raj', 'Kumar', 'DELIVERY_PARTNER', 'ACTIVE', true, true, true, false, 0, false, false, NOW(), NOW(), 'system', 'system'),
('user1', 'user1@example.com', '$2a$10$N9qo8uLOickgx2ZMRJWqNOeWGuyqvvrVt3p/C4.WQ5FHC5yNEVJ/6', 'Regular', 'User', 'USER', 'ACTIVE', true, true, true, false, 0, false, false, NOW(), NOW(), 'system', 'system');

-- Insert customers
INSERT INTO customers (first_name, last_name, email, mobile_number, address_line1, city, state, postal_code, country, status, is_active, is_verified, created_at, updated_at, created_by, updated_by) VALUES
('John', 'Doe', 'john.doe@customer.com', '+919876543210', '123 MG Road', 'Bangalore', 'Karnataka', '560001', 'India', 'ACTIVE', true, true, NOW(), NOW(), 'system', 'system'),
('Jane', 'Smith', 'jane.smith@customer.com', '+919876543211', '456 Brigade Road', 'Bangalore', 'Karnataka', '560002', 'India', 'ACTIVE', true, true, NOW(), NOW(), 'system', 'system');

SELECT 'Data inserted successfully!' as status;
SELECT COUNT(*) as user_count FROM users;
SELECT username, role, is_active FROM users;