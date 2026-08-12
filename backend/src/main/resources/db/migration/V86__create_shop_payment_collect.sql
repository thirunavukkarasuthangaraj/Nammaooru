-- Pay-and-use payment collection: superadmin sets a custom price per shop and a global
-- billing duration (in days); shop owner pays via Razorpay to stay usable until the next due date.

CREATE TABLE IF NOT EXISTS shop_payment_prices (
    id BIGSERIAL PRIMARY KEY,
    shop_id BIGINT NOT NULL UNIQUE REFERENCES shops(id) ON DELETE CASCADE,
    amount INTEGER NOT NULL DEFAULT 0,
    currency VARCHAR(10) NOT NULL DEFAULT 'INR',
    updated_by BIGINT,
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS shop_payment_collections (
    id BIGSERIAL PRIMARY KEY,
    shop_id BIGINT NOT NULL REFERENCES shops(id) ON DELETE CASCADE,
    amount INTEGER NOT NULL,
    currency VARCHAR(10) NOT NULL DEFAULT 'INR',
    razorpay_order_id VARCHAR(100) NOT NULL,
    razorpay_payment_id VARCHAR(100),
    razorpay_signature VARCHAR(255),
    status VARCHAR(20) NOT NULL DEFAULT 'CREATED',
    valid_until TIMESTAMP,
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    paid_at TIMESTAMP
);

CREATE INDEX idx_shop_payment_collections_shop_status ON shop_payment_collections(shop_id, status, valid_until);
CREATE INDEX idx_shop_payment_collections_order_id ON shop_payment_collections(razorpay_order_id);

-- Denormalized flag recomputed on payment success and by a daily scheduled job.
-- Drives both the shop-owner hard-lock and customer-app shop visibility.
ALTER TABLE shops ADD COLUMN IF NOT EXISTS payment_blocked BOOLEAN NOT NULL DEFAULT FALSE;

-- Global, superadmin-editable billing duration (days) between payments. Per-shop price lives in shop_payment_prices.
INSERT INTO settings (setting_key, setting_value, description, category, setting_type, scope, is_active, is_required, is_read_only, default_value, created_by, updated_by, created_at, updated_at)
SELECT 'shop_payment_collect.duration_days', '30', 'Days of access granted per pay-and-use payment', 'SHOP_PAYMENT_COLLECT', 'INTEGER', 'GLOBAL', true, true, false, '30', 'system', 'system', NOW(), NOW()
WHERE NOT EXISTS (SELECT 1 FROM settings WHERE setting_key = 'shop_payment_collect.duration_days');
