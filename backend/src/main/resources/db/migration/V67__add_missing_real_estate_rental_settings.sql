-- Add missing auto_approve and report_threshold settings for Real Estate and Rental modules
-- These services already read from settings with defaults, but the DB rows were missing

-- Real Estate auto_approve
INSERT INTO settings (setting_key, setting_value, description, category, setting_type, scope, is_active, is_required, is_read_only, default_value, display_order, created_by, updated_by, created_at, updated_at)
SELECT 'real_estate.post.auto_approve', 'false', 'Auto-approve real estate posts', 'REAL_ESTATE', 'BOOLEAN', 'GLOBAL', true, false, false, 'false', 1, 'system', 'system', NOW(), NOW()
WHERE NOT EXISTS (SELECT 1 FROM settings WHERE setting_key = 'real_estate.post.auto_approve');

-- Real Estate report_threshold
INSERT INTO settings (setting_key, setting_value, description, category, setting_type, scope, is_active, is_required, is_read_only, default_value, display_order, created_by, updated_by, created_at, updated_at)
SELECT 'real_estate.post.report_threshold', '3', 'Number of reports before auto-hiding real estate posts', 'REAL_ESTATE', 'INTEGER', 'GLOBAL', true, false, false, '3', 2, 'system', 'system', NOW(), NOW()
WHERE NOT EXISTS (SELECT 1 FROM settings WHERE setting_key = 'real_estate.post.report_threshold');

-- Rental auto_approve
INSERT INTO settings (setting_key, setting_value, description, category, setting_type, scope, is_active, is_required, is_read_only, default_value, display_order, created_by, updated_by, created_at, updated_at)
SELECT 'rental.post.auto_approve', 'false', 'Auto-approve rental posts', 'RENTAL', 'BOOLEAN', 'GLOBAL', true, false, false, 'false', 1, 'system', 'system', NOW(), NOW()
WHERE NOT EXISTS (SELECT 1 FROM settings WHERE setting_key = 'rental.post.auto_approve');

-- Rental report_threshold
INSERT INTO settings (setting_key, setting_value, description, category, setting_type, scope, is_active, is_required, is_read_only, default_value, display_order, created_by, updated_by, created_at, updated_at)
SELECT 'rental.post.report_threshold', '3', 'Number of reports before auto-hiding rental posts', 'RENTAL', 'INTEGER', 'GLOBAL', true, false, false, '3', 2, 'system', 'system', NOW(), NOW()
WHERE NOT EXISTS (SELECT 1 FROM settings WHERE setting_key = 'rental.post.report_threshold');

-- Processing fee percentage (currently hardcoded as 2.36 in PostPaymentService)
INSERT INTO settings (setting_key, setting_value, description, category, setting_type, scope, is_active, is_required, is_read_only, default_value, display_order, created_by, updated_by, created_at, updated_at)
SELECT 'paid_post.processing_fee_percent', '2.36', 'Processing fee percentage (Razorpay 2% + 18% GST)', 'PAID_POSTS', 'DECIMAL', 'GLOBAL', true, false, false, '2.36', 8, 'system', 'system', NOW(), NOW()
WHERE NOT EXISTS (SELECT 1 FROM settings WHERE setting_key = 'paid_post.processing_fee_percent');
