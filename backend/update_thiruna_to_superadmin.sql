-- Update thiruna user to SUPER_ADMIN role
-- This script updates the existing user thiruna2394@gmail.com to have SUPER_ADMIN privileges

UPDATE users 
SET 
    role = 'SUPER_ADMIN',
    status = 'ACTIVE',
    is_active = true,
    email_verified = true,
    updated_at = NOW(),
    updated_by = 'system'
WHERE email = 'thiruna2394@gmail.com' OR username = 'thiruna';

-- Verify the update
SELECT 
    id, 
    username, 
    email, 
    role, 
    status,
    is_active,
    email_verified,
    created_at,
    updated_at
FROM users 
WHERE email = 'thiruna2394@gmail.com' OR username = 'thiruna';