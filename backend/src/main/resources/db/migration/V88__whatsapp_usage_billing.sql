-- Usage-based billing: shops pay for the WhatsApp messages they send
-- (POS bills to customers) on top of the platform fee, settled with each
-- pay-and-use payment.

CREATE TABLE IF NOT EXISTS shop_whatsapp_usage (
    id BIGSERIAL PRIMARY KEY,
    shop_id BIGINT NOT NULL REFERENCES shops(id) ON DELETE CASCADE,
    message_type VARCHAR(40) NOT NULL,
    settled BOOLEAN NOT NULL DEFAULT FALSE,
    settled_payment_id BIGINT,
    created_at TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_shop_whatsapp_usage_unsettled
    ON shop_whatsapp_usage(shop_id) WHERE settled = FALSE;

-- Per-message rate charged to shops, in paise (superadmin-editable; actual Meta
-- cost is ~12p, the default 45p includes platform margin)
INSERT INTO settings (setting_key, setting_value, description, category, setting_type, scope, is_active, is_required, is_read_only, default_value, created_by, updated_by, created_at, updated_at)
SELECT 'shop_payment_collect.whatsapp_rate_paise', '45', 'Per WhatsApp message charge to shops (paise)', 'SHOP_PAYMENT_COLLECT', 'INTEGER', 'GLOBAL', true, true, false, '45', 'system', 'system', NOW(), NOW()
WHERE NOT EXISTS (SELECT 1 FROM settings WHERE setting_key = 'shop_payment_collect.whatsapp_rate_paise');

INSERT INTO settings (setting_key, setting_value, description, category, setting_type, scope, is_active, is_required, is_read_only, default_value, created_by, updated_by, created_at, updated_at)
SELECT 'shop_payment_collect.gst_percent', '18', 'GST percent applied to pay-and-use invoices', 'SHOP_PAYMENT_COLLECT', 'INTEGER', 'GLOBAL', true, true, false, '18', 'system', 'system', NOW(), NOW()
WHERE NOT EXISTS (SELECT 1 FROM settings WHERE setting_key = 'shop_payment_collect.gst_percent');

-- Breakdown stored on each payment so receipts/history can explain the total
-- (usage_amount and gst_amount are in PAISE; amount stays the platform fee in rupees)
ALTER TABLE shop_payment_collections ADD COLUMN IF NOT EXISTS usage_count INTEGER NOT NULL DEFAULT 0;
ALTER TABLE shop_payment_collections ADD COLUMN IF NOT EXISTS usage_amount INTEGER NOT NULL DEFAULT 0;
ALTER TABLE shop_payment_collections ADD COLUMN IF NOT EXISTS gst_amount INTEGER NOT NULL DEFAULT 0;
-- Instant the usage count was computed at order-creation time; verifyPayment settles
-- messages up to exactly this instant so a message sent mid-checkout is never both
-- charged on this invoice and left unsettled (or settled without being charged).
ALTER TABLE shop_payment_collections ADD COLUMN IF NOT EXISTS usage_cutoff TIMESTAMP;

-- Per-shop rate override (paise); NULL = global setting
ALTER TABLE shop_payment_prices ADD COLUMN IF NOT EXISTS whatsapp_rate_paise INTEGER;
