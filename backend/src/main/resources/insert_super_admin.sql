-- Insert Super Admin User Script
-- This script creates a super admin user with all privileges

-- Password: Admin@123 (BCrypt encoded)
-- Email: admin@nammaooru.com
-- Username: superadmin

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
) ON CONFLICT (email) DO UPDATE SET
    password = EXCLUDED.password,
    role = 'SUPER_ADMIN',
    mobile_number = EXCLUDED.mobile_number,
    is_active = true,
    updated_at = NOW();

-- Alternative: Insert with your email
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
) ON CONFLICT (email) DO UPDATE SET
    password = EXCLUDED.password,
    role = EXCLUDED.role,
    is_active = true,
    updated_at = NOW();

-- Create Shop Owner User
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
    'shopowner',
    'shopowner@example.com',
    '$2a$10$dG5EWTw7YixR2cC7xPGSAOoGvmOoiV5dCzi2R7zELzJgJY0fNGNbW', -- Password: shop123
    'SHOP_OWNER',
    '8888888888',
    'Shop',
    'Owner',
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
) ON CONFLICT (email) DO UPDATE SET
    password = EXCLUDED.password,
    role = EXCLUDED.role,
    is_active = true,
    updated_at = NOW();

-- Create Delivery Partner User
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
    'delivery1',
    'delivery@example.com',
    '$2a$10$K7.eJqPEkXzL9BQmUWFyAeGHQ0tXwRj5Y5VqxQ0jXEKzO8pZqF9gO', -- Password: delivery123
    'DELIVERY_PARTNER',
    '7777777777',
    'Delivery',
    'Partner',
    true,
    true,
    true,
    false,
    false,
    0,
    false,
    true,
    true,
    'ACTIVE',
    'AVAILABLE',
    NOW(),
    NOW()
) ON CONFLICT (email) DO UPDATE SET
    password = EXCLUDED.password,
    role = EXCLUDED.role,
    is_active = true,
    updated_at = NOW();

-- Create Customer User
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
    'customer1',
    'customer@example.com',
    '$2a$10$xmX5KIQQ6ZG8vR7oPW5yW.WPQk5kYLtFqpFYGWxZWG7YxGw6yKHWa', -- Password: customer123
    'USER',
    '6666666666',
    'Customer',
    'User',
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
) ON CONFLICT (email) DO UPDATE SET
    password = EXCLUDED.password,
    role = EXCLUDED.role,
    is_active = true,
    updated_at = NOW();

-- Query to verify users
SELECT id, username, email, role, mobile_number, is_active, created_at
FROM users
WHERE role IN ('ADMIN', 'SHOP_OWNER', 'DELIVERY_PARTNER', 'USER')
ORDER BY created_at DESC;