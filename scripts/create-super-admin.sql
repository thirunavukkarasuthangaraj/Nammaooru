-- Create single super admin user and remove others
-- Email: thiruna2394@gmail.com
-- Password: Nammaooru@Thiru123

BEGIN;

-- Remove all existing super admin users
DELETE FROM users WHERE role = 'SUPER_ADMIN';

-- Create the new super admin user with BCrypt hash for 'Nammaooru@Thiru123'
-- BCrypt hash generated with 10 rounds
INSERT INTO users (
    username, 
    email, 
    password, 
    first_name, 
    last_name, 
    role, 
    is_active, 
    status, 
    email_verified,
    created_at, 
    updated_at
) VALUES (
    'superadmin',
    'thiruna2394@gmail.com',
    '$2a$10$rQ7QFkzLuATfVGD9.LgqCeVPnP9SzlX9QY8F8P0EqFkJy3lGlPNjG', -- Nammaooru@Thiru123
    'Thiru',
    'Admin',
    'SUPER_ADMIN',
    true,
    'ACTIVE',
    true,
    CURRENT_TIMESTAMP,
    CURRENT_TIMESTAMP
) ON CONFLICT (username) DO UPDATE SET
    email = EXCLUDED.email,
    password = EXCLUDED.password,
    role = EXCLUDED.role,
    is_active = true,
    status = 'ACTIVE',
    updated_at = CURRENT_TIMESTAMP;

COMMIT;

-- Verify the user was created
SELECT username, email, role, status, is_active FROM users WHERE username = 'superadmin';