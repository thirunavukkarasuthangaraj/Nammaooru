-- Per-shop billing duration override (days). NULL = use the global
-- shop_payment_collect.duration_days setting. Lets some shops pay yearly
-- while others pay monthly.
ALTER TABLE shop_payment_prices ADD COLUMN IF NOT EXISTS duration_days INTEGER;
