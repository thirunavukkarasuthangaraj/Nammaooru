-- Update user with email thiruna2394@gmail.com
-- Set password to Test@123 and role to SUPER_ADMIN

-- Update by email
UPDATE users
SET
    password = '$2a$10$4P8VxXrSU7KlpZPvyBbTzuLbKxwLJWfMGzPZRNKwGVDfQ8QxI9Khu', -- Password: Test@123
    role = 'SUPER_ADMIN',
    is_active = true,
    email_verified = true,
    mobile_verified = true,
    password_change_required = false,
    is_temporary_password = false,
    failed_login_attempts = 0,
    status = 'ACTIVE',
    updated_at = NOW()
WHERE email = 'thiruna2394@gmail.com';

-- Alternative: Update by mobile number
UPDATE users
SET
    password = '$2a$10$4P8VxXrSU7KlpZPvyBbTzuLbKxwLJWfMGzPZRNKwGVDfQ8QxI9Khu', -- Password: Test@123
    role = 'SUPER_ADMIN',
    email = 'thiruna2394@gmail.com',
    is_active = true,
    email_verified = true,
    mobile_verified = true,
    password_change_required = false,
    is_temporary_password = false,
    failed_login_attempts = 0,
    status = 'ACTIVE',
    updated_at = NOW()
WHERE mobile_number = '9999999999';

-- Verify the update
SELECT id, username, email, role, mobile_number, is_active, status
FROM users
WHERE email = 'thiruna2394@gmail.com' OR mobile_number = '9999999999';