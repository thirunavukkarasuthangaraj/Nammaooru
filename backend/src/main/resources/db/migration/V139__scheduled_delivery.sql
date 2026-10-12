-- Scheduled delivery: accept an order while the shop is closed and deliver it in the
-- shop's next available window, instead of refusing it outright.
--
-- A scheduled order is an ordinary order that stays invisible until its time. It is held
-- in SCHEDULED, released to PENDING shortly before the window, and from then on travels
-- the existing pipeline unchanged - preparation, driver assignment, delivery.

-- Window the customer was promised. A start and an end, so "10 to 11 AM" can be shown
-- rather than a single instant. NULL on both means deliver now, which is every existing
-- order, so nothing already in the table changes meaning.
ALTER TABLE orders
    ADD COLUMN IF NOT EXISTS scheduled_from TIMESTAMP,
    ADD COLUMN IF NOT EXISTS scheduled_until TIMESTAMP;

COMMENT ON COLUMN orders.scheduled_from IS
    'Start of the delivery window the customer chose. NULL means deliver as soon as possible.';
COMMENT ON COLUMN orders.scheduled_until IS
    'End of that window. Shown to the customer as a range; not a deadline the system enforces.';

-- SCHEDULED sits before PENDING. It is not cosmetic: the shop owner app rings like an
-- incoming call for each pending order, so without a separate status a midnight order for
-- a 10 AM slot would ring the till at midnight and then sit looking ten hours overdue.
ALTER TABLE orders DROP CONSTRAINT IF EXISTS orders_status_check;
ALTER TABLE orders ADD CONSTRAINT orders_status_check CHECK (
    (status)::text = ANY (ARRAY[
        'SCHEDULED'::text,
        'PENDING'::text,
        'CONFIRMED'::text,
        'PREPARING'::text,
        'READY'::text,
        'READY_FOR_PICKUP'::text,
        'OUT_FOR_DELIVERY'::text,
        'DELIVERED'::text,
        'COMPLETED'::text,
        'CANCELLED'::text,
        'REFUNDED'::text,
        'SELF_PICKUP_COLLECTED'::text,
        'RETURNING_TO_SHOP'::text,
        'RETURNED_TO_SHOP'::text
    ])
);

-- The release job scans for due scheduled orders every few minutes; without this it is a
-- full table scan of every order ever placed.
CREATE INDEX IF NOT EXISTS idx_orders_scheduled_release
    ON orders (scheduled_from)
    WHERE status = 'SCHEDULED';

-- How long before the window the till should be told, so the shop can prepare. A 10 AM
-- delivery reaching the shop at 10 AM is useless.
INSERT INTO settings (setting_key, setting_value, description, category, setting_type, scope, is_active, is_required, is_read_only, default_value, display_order, created_by, updated_by, created_at, updated_at)
SELECT 'order.scheduled.release_lead_minutes', '60', 'How many minutes before a scheduled delivery window the order is released to the shop', 'ORDER', 'INTEGER', 'GLOBAL', true, false, false, '60', 1, 'system', 'system', NOW(), NOW()
WHERE NOT EXISTS (SELECT 1 FROM settings WHERE setting_key = 'order.scheduled.release_lead_minutes');

INSERT INTO settings (setting_key, setting_value, description, category, setting_type, scope, is_active, is_required, is_read_only, default_value, display_order, created_by, updated_by, created_at, updated_at)
SELECT 'order.scheduled.enabled', 'true', 'Allow customers to schedule a delivery when the shop is closed', 'ORDER', 'BOOLEAN', 'GLOBAL', true, false, false, 'true', 2, 'system', 'system', NOW(), NOW()
WHERE NOT EXISTS (SELECT 1 FROM settings WHERE setting_key = 'order.scheduled.enabled');
