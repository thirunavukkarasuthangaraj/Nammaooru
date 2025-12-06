-- ============================================
-- Super Admin User Insertion Script
-- ============================================
-- This script creates a SUPER_ADMIN user with full permissions
--
-- Credentials:
-- Username: superadmin
-- Password: superadmin123
-- Email: superadmin@nammaooru.com
-- Mobile: +919999999999
--
-- Note: Change the password immediately after first login
-- ============================================

-- Step 1: Create permissions table if not exists
CREATE TABLE IF NOT EXISTS permissions (
    id BIGSERIAL PRIMARY KEY,
    name VARCHAR(100) UNIQUE NOT NULL,
    description VARCHAR(200),
    category VARCHAR(100),
    resource_type VARCHAR(50),
    action_type VARCHAR(50),
    active BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by VARCHAR(100),
    updated_by VARCHAR(100)
);

-- Step 2: Create user_permissions table if not exists
CREATE TABLE IF NOT EXISTS user_permissions (
    user_id BIGINT NOT NULL,
    permission_id BIGINT NOT NULL,
    PRIMARY KEY (user_id, permission_id),
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (permission_id) REFERENCES permissions(id) ON DELETE CASCADE
);

-- Step 3: Insert Super Admin User
-- Password: superadmin123 (BCrypt hashed)
INSERT INTO users (
    username,
    email,
    password,
    first_name,
    last_name,
    gender,
    mobile_number,
    role,
    status,
    profile_image_url,
    last_login,
    failed_login_attempts,
    account_locked_until,
    email_verified,
    mobile_verified,
    two_factor_enabled,
    department,
    designation,
    reports_to,
    is_active,
    is_temporary_password,
    password_change_required,
    last_password_change,
    created_at,
    updated_at,
    created_by,
    updated_by,
    is_online,
    is_available,
    ride_status,
    current_latitude,
    current_longitude,
    last_location_update,
    last_activity
) VALUES (
    'superadmin',                                                                   -- username
    'superadmin@nammaooru.com',                                                    -- email
    '$2a$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi',              -- password (BCrypt hash of 'superadmin123')
    'Super',                                                                        -- first_name
    'Admin',                                                                        -- last_name
    'Other',                                                                        -- gender
    '+919999999999',                                                               -- mobile_number
    'SUPER_ADMIN',                                                                 -- role
    'ACTIVE',                                                                       -- status
    NULL,                                                                           -- profile_image_url
    NULL,                                                                           -- last_login
    0,                                                                              -- failed_login_attempts
    NULL,                                                                           -- account_locked_until
    true,                                                                           -- email_verified
    true,                                                                           -- mobile_verified
    false,                                                                          -- two_factor_enabled
    'Administration',                                                               -- department
    'System Administrator',                                                         -- designation
    NULL,                                                                           -- reports_to
    true,                                                                           -- is_active
    false,                                                                          -- is_temporary_password
    false,                                                                          -- password_change_required
    CURRENT_TIMESTAMP,                                                             -- last_password_change
    CURRENT_TIMESTAMP,                                                             -- created_at
    CURRENT_TIMESTAMP,                                                             -- updated_at
    'SYSTEM',                                                                       -- created_by
    'SYSTEM',                                                                       -- updated_by
    false,                                                                          -- is_online
    false,                                                                          -- is_available
    'AVAILABLE',                                                                    -- ride_status
    NULL,                                                                           -- current_latitude
    NULL,                                                                           -- current_longitude
    NULL,                                                                           -- last_location_update
    NULL                                                                            -- last_activity
);

-- Step 4: Insert Common Permissions for Super Admin
INSERT INTO permissions (name, description, category, resource_type, action_type, active, created_by, updated_by) VALUES
-- User Management Permissions
('USER_CREATE', 'Create new users', 'User Management', 'USER', 'CREATE', true, 'SYSTEM', 'SYSTEM'),
('USER_READ', 'View user details', 'User Management', 'USER', 'READ', true, 'SYSTEM', 'SYSTEM'),
('USER_UPDATE', 'Update user information', 'User Management', 'USER', 'UPDATE', true, 'SYSTEM', 'SYSTEM'),
('USER_DELETE', 'Delete users', 'User Management', 'USER', 'DELETE', true, 'SYSTEM', 'SYSTEM'),
('USER_MANAGE_ROLES', 'Manage user roles', 'User Management', 'USER', 'MANAGE_ROLES', true, 'SYSTEM', 'SYSTEM'),

-- Thiru Software Permissions
('SHOP_CREATE', 'Create new shops', 'Thiru Software', 'SHOP', 'CREATE', true, 'SYSTEM', 'SYSTEM'),
('SHOP_READ', 'View shop details', 'Thiru Software', 'SHOP', 'READ', true, 'SYSTEM', 'SYSTEM'),
('SHOP_UPDATE', 'Update shop information', 'Thiru Software', 'SHOP', 'UPDATE', true, 'SYSTEM', 'SYSTEM'),
('SHOP_DELETE', 'Delete shops', 'Thiru Software', 'SHOP', 'DELETE', true, 'SYSTEM', 'SYSTEM'),
('SHOP_APPROVE', 'Approve shop registrations', 'Thiru Software', 'SHOP', 'APPROVE', true, 'SYSTEM', 'SYSTEM'),
('SHOP_SUSPEND', 'Suspend shops', 'Thiru Software', 'SHOP', 'SUSPEND', true, 'SYSTEM', 'SYSTEM'),

-- Product Management Permissions
('PRODUCT_CREATE', 'Create new products', 'Product Management', 'PRODUCT', 'CREATE', true, 'SYSTEM', 'SYSTEM'),
('PRODUCT_READ', 'View product details', 'Product Management', 'PRODUCT', 'READ', true, 'SYSTEM', 'SYSTEM'),
('PRODUCT_UPDATE', 'Update product information', 'Product Management', 'PRODUCT', 'UPDATE', true, 'SYSTEM', 'SYSTEM'),
('PRODUCT_DELETE', 'Delete products', 'Product Management', 'PRODUCT', 'DELETE', true, 'SYSTEM', 'SYSTEM'),

-- Order Management Permissions
('ORDER_CREATE', 'Create new orders', 'Order Management', 'ORDER', 'CREATE', true, 'SYSTEM', 'SYSTEM'),
('ORDER_READ', 'View order details', 'Order Management', 'ORDER', 'READ', true, 'SYSTEM', 'SYSTEM'),
('ORDER_UPDATE', 'Update order information', 'Order Management', 'ORDER', 'UPDATE', true, 'SYSTEM', 'SYSTEM'),
('ORDER_CANCEL', 'Cancel orders', 'Order Management', 'ORDER', 'CANCEL', true, 'SYSTEM', 'SYSTEM'),
('ORDER_REFUND', 'Process order refunds', 'Order Management', 'ORDER', 'REFUND', true, 'SYSTEM', 'SYSTEM'),

-- Payment Management Permissions
('PAYMENT_READ', 'View payment details', 'Payment Management', 'PAYMENT', 'READ', true, 'SYSTEM', 'SYSTEM'),
('PAYMENT_PROCESS', 'Process payments', 'Payment Management', 'PAYMENT', 'PROCESS', true, 'SYSTEM', 'SYSTEM'),
('PAYMENT_REFUND', 'Process payment refunds', 'Payment Management', 'PAYMENT', 'REFUND', true, 'SYSTEM', 'SYSTEM'),

-- Delivery Management Permissions
('DELIVERY_ASSIGN', 'Assign delivery partners', 'Delivery Management', 'DELIVERY', 'ASSIGN', true, 'SYSTEM', 'SYSTEM'),
('DELIVERY_TRACK', 'Track deliveries', 'Delivery Management', 'DELIVERY', 'TRACK', true, 'SYSTEM', 'SYSTEM'),
('DELIVERY_UPDATE', 'Update delivery status', 'Delivery Management', 'DELIVERY', 'UPDATE', true, 'SYSTEM', 'SYSTEM'),

-- Report Permissions
('REPORT_SALES', 'View sales reports', 'Reporting', 'REPORT', 'SALES', true, 'SYSTEM', 'SYSTEM'),
('REPORT_FINANCIAL', 'View financial reports', 'Reporting', 'REPORT', 'FINANCIAL', true, 'SYSTEM', 'SYSTEM'),
('REPORT_INVENTORY', 'View inventory reports', 'Reporting', 'REPORT', 'INVENTORY', true, 'SYSTEM', 'SYSTEM'),
('REPORT_USER', 'View user reports', 'Reporting', 'REPORT', 'USER', true, 'SYSTEM', 'SYSTEM'),

-- System Permissions
('SYSTEM_CONFIG', 'Configure system settings', 'System', 'SYSTEM', 'CONFIG', true, 'SYSTEM', 'SYSTEM'),
('SYSTEM_BACKUP', 'Perform system backup', 'System', 'SYSTEM', 'BACKUP', true, 'SYSTEM', 'SYSTEM'),
('SYSTEM_LOGS', 'View system logs', 'System', 'SYSTEM', 'LOGS', true, 'SYSTEM', 'SYSTEM'),
('SYSTEM_AUDIT', 'View audit trails', 'System', 'SYSTEM', 'AUDIT', true, 'SYSTEM', 'SYSTEM')

ON CONFLICT (name) DO NOTHING;

-- Step 5: Assign All Permissions to Super Admin
INSERT INTO user_permissions (user_id, permission_id)
SELECT u.id, p.id
FROM users u
CROSS JOIN permissions p
WHERE u.username = 'superadmin' AND u.role = 'SUPER_ADMIN'
ON CONFLICT DO NOTHING;

-- Verification Query
SELECT
    u.id,
    u.username,
    u.email,
    u.first_name,
    u.last_name,
    u.mobile_number,
    u.role,
    u.status,
    u.is_active,
    u.email_verified,
    u.mobile_verified,
    COUNT(up.permission_id) as permission_count,
    u.created_at
FROM users u
LEFT JOIN user_permissions up ON u.id = up.user_id
WHERE u.username = 'superadmin'
GROUP BY u.id, u.username, u.email, u.first_name, u.last_name, u.mobile_number,
         u.role, u.status, u.is_active, u.email_verified, u.mobile_verified, u.created_at;

-- ============================================
-- End of Script
-- ============================================
--
-- To execute this script:
-- 1. Connect to your PostgreSQL database
-- 2. Run: psql -U your_username -d your_database -f insert_super_admin.sql
--
-- Or execute via application:
-- 1. Copy and paste into your SQL client
-- 2. Execute the script
--
-- IMPORTANT SECURITY NOTES:
-- 1. Change the password immediately after first login
-- 2. Enable two-factor authentication if available
-- 3. Review and adjust permissions based on your needs
-- 4. Keep this script secure - it contains sensitive information
-- ============================================
