-- Quick insert for test users with correct roles
INSERT INTO users (username, email, password, first_name, last_name, role, status, email_verified, mobile_verified, two_factor_enabled, failed_login_attempts, password_change_required, is_temporary_password, created_at, updated_at, created_by, updated_by) VALUES
-- Super Admin  
('superadmin', 'superadmin@shopmanagement.com', '$2a$10$N9qo8uLOickgx2ZMRJWqNOeWGuyqvvrVt3p/C4.WQ5FHC5yNEVJ/6', 'Super', 'Admin', 'SUPER_ADMIN', 'ACTIVE', true, true, false, 0, false, false, NOW(), NOW(), 'system', 'system'),
-- Admins
('admin1', 'admin1@shopmanagement.com', '$2a$10$N9qo8uLOickgx2ZMRJWqNOeWGuyqvvrVt3p/C4.WQ5FHC5yNEVJ/6', 'Admin', 'One', 'ADMIN', 'ACTIVE', true, true, false, 0, false, false, NOW(), NOW(), 'system', 'system'),
-- Shop Owners
('shopowner1', 'owner1@electronics.com', '$2a$10$N9qo8uLOickgx2ZMRJWqNOeWGuyqvvrVt3p/C4.WQ5FHC5yNEVJ/6', 'Rajesh', 'Kumar', 'SHOP_OWNER', 'ACTIVE', true, true, false, 0, false, false, NOW(), NOW(), 'system', 'system'),
('shopowner2', 'owner2@grocery.com', '$2a$10$N9qo8uLOickgx2ZMRJWqNOeWGuyqvvrVt3p/C4.WQ5FHC5yNEVJ/6', 'Priya', 'Sharma', 'SHOP_OWNER', 'ACTIVE', true, true, false, 0, false, false, NOW(), NOW(), 'system', 'system'),
-- Managers
('manager1', 'manager1@electronics.com', '$2a$10$N9qo8uLOickgx2ZMRJWqNOeWGuyqvvrVt3p/C4.WQ5FHC5yNEVJ/6', 'Suresh', 'Reddy', 'MANAGER', 'ACTIVE', true, true, false, 0, false, false, NOW(), NOW(), 'system', 'system'),
-- Delivery Partners (correct role name)
('delivery1', 'raj.kumar@delivery.com', '$2a$10$N9qo8uLOickgx2ZMRJWqNOeWGuyqvvrVt3p/C4.WQ5FHC5yNEVJ/6', 'Raj', 'Kumar', 'DELIVERY_PARTNER', 'ACTIVE', true, true, false, 0, false, false, NOW(), NOW(), 'system', 'system'),
('delivery2', 'priya.delivery@gmail.com', '$2a$10$N9qo8uLOickgx2ZMRJWqNOeWGuyqvvrVt3p/C4.WQ5FHC5yNEVJ/6', 'Priya', 'Devi', 'DELIVERY_PARTNER', 'ACTIVE', true, true, false, 0, false, false, NOW(), NOW(), 'system', 'system'),
('delivery3', 'amit.delivery@gmail.com', '$2a$10$N9qo8uLOickgx2ZMRJWqNOeWGuyqvvrVt3p/C4.WQ5FHC5yNEVJ/6', 'Amit', 'Gupta', 'DELIVERY_PARTNER', 'ACTIVE', true, true, false, 0, false, false, NOW(), NOW(), 'system', 'system'),
-- Customer Service
('cs1', 'cs1@shopmanagement.com', '$2a$10$N9qo8uLOickgx2ZMRJWqNOeWGuyqvvrVt3p/C4.WQ5FHC5yNEVJ/6', 'Customer', 'Service', 'CUSTOMER_SERVICE', 'ACTIVE', true, true, false, 0, false, false, NOW(), NOW(), 'system', 'system'),
-- Regular Users
('user1', 'user1@example.com', '$2a$10$N9qo8uLOickgx2ZMRJWqNOeWGuyqvvrVt3p/C4.WQ5FHC5yNEVJ/6', 'Regular', 'User', 'USER', 'ACTIVE', true, true, false, 0, false, false, NOW(), NOW(), 'system', 'system');

-- Show test users by role
SELECT 'TEST USERS BY ROLE:' as info;
SELECT role, COUNT(*) as user_count, STRING_AGG(username, ', ') as usernames
FROM users 
GROUP BY role 
ORDER BY role;

-- Show test login credentials
SELECT 'TEST LOGIN CREDENTIALS:' as info;
SELECT 'All test accounts use password: password' as note;
SELECT role, username, email, first_name || ' ' || last_name as full_name
FROM users 
ORDER BY role, username;