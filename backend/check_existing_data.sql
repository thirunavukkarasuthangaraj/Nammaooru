-- Check existing data in the system for auto-assignment demonstration

-- 1. Check existing delivery partners
SELECT
    id,
    email,
    first_name,
    last_name,
    mobile_number,
    role,
    is_online,
    is_available,
    ride_status,
    last_activity,
    created_at
FROM users
WHERE role = 'DELIVERY_PARTNER'
ORDER BY created_at DESC;

-- 2. Check existing orders that can be assigned
SELECT
    o.id,
    o.order_number,
    o.status,
    o.total_amount,
    o.delivery_fee,
    o.delivery_address,
    o.payment_method,
    c.first_name || ' ' || c.last_name as customer_name,
    c.mobile_number as customer_phone,
    s.name as shop_name,
    o.created_at
FROM orders o
JOIN users c ON o.customer_id = c.id
JOIN shops s ON o.shop_id = s.id
WHERE o.status IN ('READY_FOR_PICKUP', 'CONFIRMED', 'PREPARING')
ORDER BY o.created_at DESC;

-- 3. Check existing assignments
SELECT
    oa.id,
    oa.status,
    oa.assignment_type,
    oa.delivery_fee,
    oa.partner_commission,
    oa.assigned_at,
    oa.accepted_at,
    oa.pickup_time,
    oa.delivery_completed_at,
    o.order_number,
    dp.first_name || ' ' || dp.last_name as partner_name,
    dp.email as partner_email,
    dp.mobile_number as partner_phone
FROM order_assignments oa
JOIN orders o ON oa.order_id = o.id
JOIN users dp ON oa.delivery_partner_id = dp.id
ORDER BY oa.assigned_at DESC;

-- 4. Check shop owners for assignment authorization
SELECT
    id,
    email,
    first_name,
    last_name,
    role,
    created_at
FROM users
WHERE role IN ('SHOP_OWNER', 'ADMIN', 'SUPER_ADMIN')
ORDER BY created_at DESC;

-- 5. Count summary for auto-assignment readiness
SELECT
    'Available Partners' as metric,
    COUNT(*) as count
FROM users
WHERE role = 'DELIVERY_PARTNER'
    AND is_online = true
    AND is_available = true
    AND ride_status = 'AVAILABLE'

UNION ALL

SELECT
    'Orders Ready for Pickup' as metric,
    COUNT(*) as count
FROM orders
WHERE status = 'READY_FOR_PICKUP'

UNION ALL

SELECT
    'Active Assignments' as metric,
    COUNT(*) as count
FROM order_assignments
WHERE status IN ('ASSIGNED', 'ACCEPTED', 'PICKED_UP', 'IN_TRANSIT')

UNION ALL

SELECT
    'Total Delivery Partners' as metric,
    COUNT(*) as count
FROM users
WHERE role = 'DELIVERY_PARTNER'

UNION ALL

SELECT
    'Total Orders' as metric,
    COUNT(*) as count
FROM orders;

-- 6. Auto-assignment simulation query
-- This shows which orders can be auto-assigned to which partners
SELECT
    o.id as order_id,
    o.order_number,
    o.status as order_status,
    o.total_amount,
    o.delivery_address,
    dp.id as partner_id,
    dp.first_name || ' ' || dp.last_name as partner_name,
    dp.email as partner_email,
    dp.is_online,
    dp.is_available,
    dp.ride_status,
    dp.last_activity,
    CASE
        WHEN dp.is_online = true AND dp.is_available = true AND dp.ride_status = 'AVAILABLE'
        THEN 'READY FOR ASSIGNMENT'
        ELSE 'NOT AVAILABLE'
    END as assignment_eligibility
FROM orders o
CROSS JOIN users dp
WHERE o.status = 'READY_FOR_PICKUP'
    AND dp.role = 'DELIVERY_PARTNER'
    AND NOT EXISTS (
        SELECT 1 FROM order_assignments oa
        WHERE oa.order_id = o.id
        AND oa.status IN ('ASSIGNED', 'ACCEPTED', 'PICKED_UP', 'IN_TRANSIT')
    )
ORDER BY o.id, dp.id;