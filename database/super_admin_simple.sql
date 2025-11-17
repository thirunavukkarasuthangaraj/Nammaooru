-- ============================================
-- SIMPLE SUPER ADMIN USER SCRIPT
-- ============================================
-- Username: superadmin
-- Password: Admin@123
-- ============================================

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
    failed_login_attempts,
    email_verified,
    mobile_verified,
    two_factor_enabled,
    department,
    designation,
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
    ride_status
) VALUES (
    'superadmin',
    'thiruna2394@gmail.com',
    '$2a$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi',
    'Super',
    'Admin',
    'Other',
    '+919999999999',
    'SUPER_ADMIN',
    'ACTIVE',
    0,
    true,
    true,
    false,
    'IT',
    'System Administrator',
    true,
    false,
    false,
    CURRENT_TIMESTAMP,
    CURRENT_TIMESTAMP,
    CURRENT_TIMESTAMP,
    'SYSTEM',
    'SYSTEM',
    false,
    false,
    'AVAILABLE'
);

-- Verify the user was created
SELECT id, username, email, first_name, last_name, role, status, is_active, created_at
FROM users
WHERE username = 'superadmin';
