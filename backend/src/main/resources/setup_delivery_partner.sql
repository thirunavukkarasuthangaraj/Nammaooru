-- Setup Delivery Partner to Receive Orders
-- Run this SQL to enable your delivery partner to receive orders

-- 1. Make delivery partner ONLINE and AVAILABLE
UPDATE users
SET
    is_online = true,
    is_available = true,
    is_active = true,
    ride_status = 'AVAILABLE',
    last_activity = NOW()
WHERE role = 'DELIVERY_PARTNER';

-- 2. Verify delivery partner status
SELECT
    id,
    first_name,
    last_name,
    email,
    mobile_number,
    role,
    is_online,
    is_available,
    is_active,
    ride_status,
    last_activity
FROM users
WHERE role = 'DELIVERY_PARTNER';

-- 3. Check if delivery partner has FCM token for notifications
SELECT
    u.id as user_id,
    u.first_name,
    u.email,
    ft.fcm_token,
    ft.device_type,
    ft.is_active as token_active,
    ft.created_at as token_created
FROM users u
LEFT JOIN user_fcm_tokens ft ON u.id = ft.user_id AND ft.is_active = true
WHERE u.role = 'DELIVERY_PARTNER';
