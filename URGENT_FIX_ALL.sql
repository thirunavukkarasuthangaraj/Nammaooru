-- URGENT: RUN THIS IN PGADMIN ON shop_management_db DATABASE
-- This will fix ALL database issues immediately

-- 1. Fix is_active field for all users (CRITICAL - fixes login)
UPDATE users SET is_active = true WHERE is_active IS NULL;

-- 2. Fix any other nullable boolean fields that might cause issues
UPDATE users SET email_verified = true WHERE email_verified IS NULL;
UPDATE users SET mobile_verified = false WHERE mobile_verified IS NULL;
UPDATE users SET two_factor_enabled = false WHERE two_factor_enabled IS NULL;
UPDATE users SET password_change_required = false WHERE password_change_required IS NULL;
UPDATE users SET is_temporary_password = false WHERE is_temporary_password IS NULL;

-- 3. Set default values for numeric fields
UPDATE users SET failed_login_attempts = 0 WHERE failed_login_attempts IS NULL;

-- 4. Ensure all delivery partners have proper fields set
UPDATE delivery_partners SET is_online = false WHERE is_online IS NULL;
UPDATE delivery_partners SET is_available = false WHERE is_available IS NULL;
UPDATE delivery_partners SET rating = 0.0 WHERE rating IS NULL;
UPDATE delivery_partners SET total_deliveries = 0 WHERE total_deliveries IS NULL;
UPDATE delivery_partners SET successful_deliveries = 0 WHERE successful_deliveries IS NULL;
UPDATE delivery_partners SET total_earnings = 0.0 WHERE total_earnings IS NULL;

-- 5. Set current location for delivery partners (Bangalore coordinates)
UPDATE delivery_partners 
SET current_latitude = 12.9716, 
    current_longitude = 77.5946,
    last_location_update = NOW(),
    last_seen = NOW()
WHERE current_latitude IS NULL OR current_longitude IS NULL;

-- 6. Verify all fixes
SELECT '=== USER STATUS CHECK ===' as check_type;
SELECT username, role, is_active, status, email_verified, mobile_verified 
FROM users 
ORDER BY role, username;

SELECT '=== DELIVERY PARTNER STATUS CHECK ===' as check_type;
SELECT partner_id, full_name, is_online, is_available, current_latitude, current_longitude 
FROM delivery_partners;

-- 7. Show ready-to-login users
SELECT '=== READY TO LOGIN ===' as check_type;
SELECT 'Username: ' || username || ' | Password: password' as login_credentials, role
FROM users 
WHERE is_active = true AND status = 'ACTIVE'
ORDER BY role;