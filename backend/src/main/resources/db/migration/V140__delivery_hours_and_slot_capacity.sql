-- Delivery hours, kept separate from shop opening hours.
--
-- A shop open 9 to 9 may deliver only 10 to 7, so "is the shop open" cannot answer "can
-- this be delivered". Until now nothing in the schema distinguished them: shops holds
-- only a radius and a self-delivery flag, and partner_availability (driver schedules)
-- has never had a single row. Scheduled delivery windows are generated from THIS table,
-- not from business_hours.
--
-- Mirrors business_hours deliberately, including break windows, so the shop owner screen
-- and the slot generator can treat the two the same way.
CREATE TABLE IF NOT EXISTS delivery_hours (
    id              BIGSERIAL PRIMARY KEY,
    shop_id         BIGINT NOT NULL REFERENCES shops(id) ON DELETE CASCADE,
    day_of_week     VARCHAR(20) NOT NULL,
    open_time       TIME,
    close_time      TIME,
    break_start_time TIME,
    break_end_time  TIME,
    is_open         BOOLEAN NOT NULL DEFAULT TRUE,
    is24hours       BOOLEAN NOT NULL DEFAULT FALSE,
    special_note    VARCHAR(255),
    created_at      TIMESTAMP DEFAULT NOW(),
    updated_at      TIMESTAMP DEFAULT NOW(),
    created_by      VARCHAR(100),
    updated_by      VARCHAR(100),
    CONSTRAINT uq_delivery_hours_shop_day UNIQUE (shop_id, day_of_week)
);

CREATE INDEX IF NOT EXISTS idx_delivery_hours_shop ON delivery_hours (shop_id);

COMMENT ON TABLE delivery_hours IS
    'When a shop can deliver, as opposed to when it is open. Scheduled delivery slots are generated from these rows.';

-- Seed from existing opening hours so no shop loses delivery the moment this ships.
-- A shop that never touches the setting keeps behaving exactly as it does today; the
-- point of the table is that it CAN now differ, not that it must.
INSERT INTO delivery_hours (
    shop_id, day_of_week, open_time, close_time, break_start_time, break_end_time,
    is_open, is24hours, created_by, updated_by
)
SELECT
    bh.shop_id, bh.day_of_week, bh.open_time, bh.close_time,
    bh.break_start_time, bh.break_end_time,
    COALESCE(bh.is_open, TRUE), COALESCE(bh.is24hours, FALSE),
    'system', 'system'
FROM business_hours bh
ON CONFLICT (shop_id, day_of_week) DO NOTHING;

-- How many scheduled orders one window may hold. Without a cap a single 9-11 slot takes
-- fifty orders and the shop cannot deliver any of them, which is worse than refusing.
-- Per shop because a one-person shop and a larger one differ wildly.
ALTER TABLE shops
    ADD COLUMN IF NOT EXISTS max_orders_per_slot INTEGER NOT NULL DEFAULT 10;

COMMENT ON COLUMN shops.max_orders_per_slot IS
    'Maximum scheduled orders accepted into a single delivery window. Full windows are shown greyed out, not hidden.';

-- Slot shape. Settings rather than constants so these can be tuned without a release.
INSERT INTO settings (setting_key, setting_value, description, category, setting_type, scope, is_active, is_required, is_read_only, default_value, display_order, created_by, updated_by, created_at, updated_at)
SELECT 'order.slot.length_minutes', '120', 'Length of each delivery window offered to customers', 'ORDER', 'INTEGER', 'GLOBAL', true, false, false, '120', 3, 'system', 'system', NOW(), NOW()
WHERE NOT EXISTS (SELECT 1 FROM settings WHERE setting_key = 'order.slot.length_minutes');

INSERT INTO settings (setting_key, setting_value, description, category, setting_type, scope, is_active, is_required, is_read_only, default_value, display_order, created_by, updated_by, created_at, updated_at)
SELECT 'order.slot.days_ahead', '3', 'How many days of delivery windows to offer, including today', 'ORDER', 'INTEGER', 'GLOBAL', true, false, false, '3', 4, 'system', 'system', NOW(), NOW()
WHERE NOT EXISTS (SELECT 1 FROM settings WHERE setting_key = 'order.slot.days_ahead');
