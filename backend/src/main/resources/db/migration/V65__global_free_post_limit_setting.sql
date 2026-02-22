-- Add configurable global free post limit setting
-- 0 = no free posts (all paid), 1 = one free post then pay, -1 = unlimited (all free)
INSERT INTO settings (setting_key, setting_value, description, category, setting_type, scope, is_active, is_required, is_read_only, default_value, display_order, created_by, updated_by, created_at, updated_at)
SELECT 'global.free_post_limit', '1', 'Number of free posts allowed across all modules before payment is required. 0 = all posts paid, -1 = unlimited (all free)', 'POST_LIMITS', 'INTEGER', 'GLOBAL', true, false, false, '1', 0, 'system', 'system', NOW(), NOW()
WHERE NOT EXISTS (SELECT 1 FROM settings WHERE setting_key = 'global.free_post_limit');
