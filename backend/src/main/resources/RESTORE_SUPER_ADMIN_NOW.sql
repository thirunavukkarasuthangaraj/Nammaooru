-- IMMEDIATE SUPER ADMIN RESTORATION
-- This script will restore your SUPER_ADMIN account RIGHT NOW
-- Password for all accounts: Test@123

-- 1. Delete any existing conflicting accounts
DELETE FROM users WHERE email IN ('thiruna2394@gmail.com', 'thirunacse75@gmail.com', 'admin@nammaooru.com');
DELETE FROM users WHERE mobile_number IN ('9999999999', '9999999998', '9876543210');

-- 2. Create YOUR SUPER_ADMIN account
INSERT INTO users (
    username,
    email,
    password,
    role,
    mobile_number,
    first_name,
    last_name,
    is_active,
    email_verified,
    mobile_verified,
    password_change_required,
    is_temporary_password,
    failed_login_attempts,
    two_factor_enabled,
    is_online,
    is_available,
    status,
    ride_status,
    created_at,
    updated_at
) VALUES (
    'thiruna2394',
    'thiruna2394@gmail.com',
    '$2a$10$4P8VxXrSU7KlpZPvyBbTzuLbKxwLJWfMGzPZRNKwGVDfQ8QxI9Khu', -- Password: Test@123
    'SUPER_ADMIN',
    '9999999999',
    'Thiru',
    'Admin',
    true,
    true,
    true,
    false,
    false,
    0,
    false,
    false,
    true,
    'ACTIVE',
    'AVAILABLE',
    NOW(),
    NOW()
);

-- 3. Create backup SUPER_ADMIN account
INSERT INTO users (
    username,
    email,
    password,
    role,
    mobile_number,
    first_name,
    last_name,
    is_active,
    email_verified,
    mobile_verified,
    password_change_required,
    is_temporary_password,
    failed_login_attempts,
    two_factor_enabled,
    is_online,
    is_available,
    status,
    ride_status,
    created_at,
    updated_at
) VALUES (
    'thirunacse75',
    'thirunacse75@gmail.com',
    '$2a$10$4P8VxXrSU7KlpZPvyBbTzuLbKxwLJWfMGzPZRNKwGVDfQ8QxI9Khu', -- Password: Test@123
    'SUPER_ADMIN',
    '9876543210',
    'Thiru',
    'Admin',
    true,
    true,
    true,
    false,
    false,
    0,
    false,
    false,
    true,
    'ACTIVE',
    'AVAILABLE',
    NOW(),
    NOW()
);

-- 4. Create default super admin
INSERT INTO users (
    username,
    email,
    password,
    role,
    mobile_number,
    first_name,
    last_name,
    is_active,
    email_verified,
    mobile_verified,
    password_change_required,
    is_temporary_password,
    failed_login_attempts,
    two_factor_enabled,
    is_online,
    is_available,
    status,
    ride_status,
    created_at,
    updated_at
) VALUES (
    'superadmin',
    'admin@nammaooru.com',
    '$2a$10$4P8VxXrSU7KlpZPvyBbTzuLbKxwLJWfMGzPZRNKwGVDfQ8QxI9Khu', -- Password: Test@123
    'SUPER_ADMIN',
    '9999999998',
    'Super',
    'Admin',
    true,
    true,
    true,
    false,
    false,
    0,
    false,
    false,
    true,
    'ACTIVE',
    'AVAILABLE',
    NOW(),
    NOW()
);

-- 5. VERIFY SUPER_ADMIN ACCOUNTS
SELECT
    id,
    username,
    email,
    role,
    mobile_number,
    is_active,
    status,
    '*** Password: Test@123 ***' as password_info
FROM users
WHERE role = 'SUPER_ADMIN'
ORDER BY created_at DESC;

-- 6. FIX ANY EXISTING ACCOUNTS WITH WRONG ROLE
UPDATE users
SET
    role = 'SUPER_ADMIN',
    password = '$2a$10$4P8VxXrSU7KlpZPvyBbTzuLbKxwLJWfMGzPZRNKwGVDfQ8QxI9Khu',
    is_active = true,
    status = 'ACTIVE',
    updated_at = NOW()
WHERE email IN ('thiruna2394@gmail.com', 'thirunacse75@gmail.com')
AND role != 'SUPER_ADMIN';

-- IMPORTANT: Run this script in your PostgreSQL database
-- Command: psql -U postgres -d shop_management -f RESTORE_SUPER_ADMIN_NOW.sql
-- OR use pgAdmin and paste this script

-- LOGIN CREDENTIALS AFTER RUNNING THIS SCRIPT:
-- =============================================
-- Email: thiruna2394@gmail.com
-- Password: Test@123
-- Role: SUPER_ADMIN
--
-- Email: thirunacse75@gmail.com
-- Password: Test@123
-- Role: SUPER_ADMIN
--
-- Email: admin@nammaooru.com
-- Password: Test@123
-- Role: SUPER_ADMIN