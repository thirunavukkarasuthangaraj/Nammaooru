-- Fix Super Admin Password
-- This will update the password to Test@123 for your account

-- Check if user exists
SELECT id, email, username, role, is_active, status
FROM users
WHERE email = 'thiruna2394@gmail.com';

-- Update password to Test@123 (BCrypt hash)
UPDATE users
SET
    password = '$2a$10$4P8VxXrSU7KlpZPvyBbTzuLbKxwLJWfMGzPZRNKwGVDfQ8QxI9Khu',
    is_active = true,
    status = 'ACTIVE',
    email_verified = true,
    mobile_verified = true,
    failed_login_attempts = 0,
    account_locked_until = NULL,
    updated_at = NOW()
WHERE email = 'thiruna2394@gmail.com';

-- Verify the update
SELECT
    id,
    email,
    username,
    role,
    is_active,
    status,
    'Password updated to: Test@123' as password_info
FROM users
WHERE email = 'thiruna2394@gmail.com';