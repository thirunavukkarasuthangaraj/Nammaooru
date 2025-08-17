-- Fix is_active field for all users
-- Run this in pgAdmin query editor for shop_management_db

-- Update all users to have is_active = true
UPDATE users SET is_active = true WHERE is_active IS NULL;

-- Verify the update
SELECT username, role, status, is_active, email_verified, mobile_verified 
FROM users 
ORDER BY role, username;

-- Show count of users by active status
SELECT 'USER ACTIVE STATUS COUNT:' as info;
SELECT is_active, COUNT(*) as user_count 
FROM users 
GROUP BY is_active 
ORDER BY is_active DESC;

-- Test specific users for login
SELECT 'TEST LOGIN READY USERS:' as info;
SELECT username, role, is_active, status, email_verified 
FROM users 
WHERE username IN ('superadmin', 'admin1', 'delivery1', 'shopowner1') 
ORDER BY username;