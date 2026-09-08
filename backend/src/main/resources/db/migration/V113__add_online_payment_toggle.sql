-- Per-shop opt-in: whether this shop accepts Razorpay online payment at
-- checkout. Defaults true so every existing shop keeps today's behavior.
ALTER TABLE shops
    ADD COLUMN online_payment_enabled BOOLEAN NOT NULL DEFAULT TRUE;

-- Platform-wide kill switch, on top of the per-shop toggle above. Checked
-- server-side alongside the shop's own flag before an ONLINE_PAYMENT order
-- is accepted. Key contains "enabled" so it renders as a toggle in the
-- existing generic admin Settings page (Settings > Payment) with no
-- frontend changes needed - see settings.component.ts's isToggleSetting().
INSERT INTO settings (setting_key, setting_value, description, category, setting_type, scope, is_active, is_required, is_read_only, default_value, created_by, updated_by, created_at, updated_at)
SELECT 'payment.online_payment_enabled', 'true', 'Allow customers to pay online (Razorpay) at checkout, platform-wide', 'Payment', 'BOOLEAN', 'GLOBAL', true, true, false, 'true', 'system', 'system', NOW(), NOW()
WHERE NOT EXISTS (SELECT 1 FROM settings WHERE setting_key = 'payment.online_payment_enabled');
