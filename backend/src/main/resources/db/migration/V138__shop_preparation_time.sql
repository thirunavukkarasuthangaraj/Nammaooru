-- Per-shop preparation time, so the delivery estimate stops being a fixed number.
--
-- Until now every order promised "now + 30 minutes", written as a constant in
-- OrderService. No shop could change it, so a shop two streets away and one eight
-- kilometres out made the identical promise. The travel half of the estimate is already
-- calculable (the delivery fee is distance-based); this supplies the other half.
--
-- 20 minutes is a deliberately ordinary default: it keeps existing shops close to the
-- old 30 minute promise once travel time is added, so nothing changes sharply for a
-- shop that never touches the setting.
ALTER TABLE shops
    ADD COLUMN IF NOT EXISTS preparation_time_minutes INTEGER NOT NULL DEFAULT 20;

COMMENT ON COLUMN shops.preparation_time_minutes IS
    'Minutes the shop needs to prepare an order before it is ready for pickup by a driver. Set by the shop owner; the customer-facing estimate is this plus travel time.';
