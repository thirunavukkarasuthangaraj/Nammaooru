-- Add missing RENTAL pricing and duration settings
INSERT INTO settings (setting_key, setting_value, description, category, setting_type, scope, is_active, is_required, is_read_only, default_value, display_order, created_by, updated_by, created_at, updated_at)
SELECT 'paid_post.price.RENTAL', '10', 'Price for rental posts (₹)', 'PAID_POSTS', 'INTEGER', 'GLOBAL', true, false, false, '10', 7, 'system', 'system', NOW(), NOW()
WHERE NOT EXISTS (SELECT 1 FROM settings WHERE setting_key = 'paid_post.price.RENTAL');

INSERT INTO settings (setting_key, setting_value, description, category, setting_type, scope, is_active, is_required, is_read_only, default_value, display_order, created_by, updated_by, created_at, updated_at)
SELECT 'rental.post.duration_days', '30', 'Duration in days for rental posts', 'POST_SETTINGS', 'INTEGER', 'GLOBAL', true, false, false, '30', 7, 'system', 'system', NOW(), NOW()
WHERE NOT EXISTS (SELECT 1 FROM settings WHERE setting_key = 'rental.post.duration_days');
