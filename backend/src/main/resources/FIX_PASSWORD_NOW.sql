-- FIX PASSWORD WITH CORRECT BCRYPT HASH
-- Password: Test@123

-- Update thiruna2394@gmail.com password to Test@123
UPDATE users
SET
    password = '$2a$10$tJIvKCzA9tL4ZYZLT.jzCeRCMPrGP89LAV0djKxAR.71ZZmGv75yS',
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
    'Password: Test@123' as password_info
FROM users
WHERE email = 'thiruna2394@gmail.com';