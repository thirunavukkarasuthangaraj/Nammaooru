-- Insert Super Admin user script
-- This script creates a superadmin user with the following credentials:
-- Email: superadmin@shopmanagement.com
-- Password: password
-- Role: SUPER_ADMIN

-- First, check if superadmin user already exists
-- If it exists, update it; if not, insert new one

-- Method 1: INSERT with ON CONFLICT (PostgreSQL)
INSERT INTO users (
    username, 
    email, 
    password, 
    first_name, 
    last_name, 
    role, 
    status, 
    is_active, 
    email_verified, 
    mobile_verified, 
    two_factor_enabled, 
    is_temporary_password, 
    password_change_required, 
    failed_login_attempts, 
    created_at, 
    updated_at, 
    created_by
) VALUES (
    'superadmin',
    'superadmin@shopmanagement.com',
    '$2a$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', -- BCrypt hash for "password"
    'Super',
    'Admin',
    'SUPER_ADMIN',
    'ACTIVE',
    true,
    true,
    false,
    false,
    false,
    false,
    0,
    NOW(),
    NOW(),
    'system'
)
ON CONFLICT (username) 
DO UPDATE SET
    email = EXCLUDED.email,
    password = EXCLUDED.password,
    role = EXCLUDED.role,
    updated_at = NOW();

-- Method 2: Alternative approach using UPSERT logic
-- DELETE FROM users WHERE username = 'superadmin';
-- INSERT INTO users (username, email, password, role, status, is_active, email_verified, created_at, updated_at, created_by) 
-- VALUES ('superadmin', 'superadmin@shopmanagement.com', '$2a$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'SUPER_ADMIN', 'ACTIVE', true, true, NOW(), NOW(), 'system');

-- Verify the user was created
SELECT id, username, email, role, is_active FROM users WHERE username = 'superadmin';