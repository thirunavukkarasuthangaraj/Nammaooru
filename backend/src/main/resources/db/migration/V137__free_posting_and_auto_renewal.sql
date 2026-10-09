-- Free posting + automatic free renewal, all driven by settings so it can be reversed later.
--
-- The single master switch is paid_post.enabled:
--   false -> posting is free and unlimited, no post limit is enforced anywhere, and the app
--            never opens a payment screen (there would be no way to complete it).
--   true  -> the old pay-per-post behaviour returns and global.free_post_limit applies again.
-- global.free_post_limit is deliberately left as-is so the limit is ready when paid posting
-- is switched back on.

-- Auto-renew: posts extend themselves instead of expiring and asking the seller to pay.
-- While this is on, the nightly cleanup job does NOT delete expired posts or their image
-- files, and expiry reminder notifications are not sent.
INSERT INTO settings (setting_key, setting_value, description, category, setting_type, scope, is_active, is_required, is_read_only, default_value, display_order, created_by, updated_by, created_at, updated_at)
SELECT 'post.auto_renew.enabled', 'true', 'Automatically renew posts for free instead of expiring them (also disables expired-post deletion)', 'POST_CONFIG', 'BOOLEAN', 'GLOBAL', true, false, false, 'true', 1, 'system', 'system', NOW(), NOW()
WHERE NOT EXISTS (SELECT 1 FROM settings WHERE setting_key = 'post.auto_renew.enabled');

-- Jobs auto-approve: the admin screen has always shown this toggle and written this key,
-- but no backend code read it, so job posts stayed pending whatever the toggle said.
INSERT INTO settings (setting_key, setting_value, description, category, setting_type, scope, is_active, is_required, is_read_only, default_value, display_order, created_by, updated_by, created_at, updated_at)
SELECT 'jobs.post.auto_approve', 'true', 'Auto-approve new job posts (skip pending approval)', 'JOBS', 'BOOLEAN', 'GLOBAL', true, false, false, 'false', 1, 'system', 'system', NOW(), NOW()
WHERE NOT EXISTS (SELECT 1 FROM settings WHERE setting_key = 'jobs.post.auto_approve');

-- Local Shops rows were never created, so the module silently fell back to its code defaults.
INSERT INTO settings (setting_key, setting_value, description, category, setting_type, scope, is_active, is_required, is_read_only, default_value, display_order, created_by, updated_by, created_at, updated_at)
SELECT 'local_shops.post.auto_approve', 'true', 'Auto-approve new local shop listings (skip pending approval)', 'LOCAL_SHOPS', 'BOOLEAN', 'GLOBAL', true, false, false, 'false', 1, 'system', 'system', NOW(), NOW()
WHERE NOT EXISTS (SELECT 1 FROM settings WHERE setting_key = 'local_shops.post.auto_approve');

INSERT INTO settings (setting_key, setting_value, description, category, setting_type, scope, is_active, is_required, is_read_only, default_value, display_order, created_by, updated_by, created_at, updated_at)
SELECT 'local_shops.post.duration_days', '30', 'How many days a local shop listing stays visible (0 = no expiry)', 'LOCAL_SHOPS', 'INTEGER', 'GLOBAL', true, false, false, '30', 2, 'system', 'system', NOW(), NOW()
WHERE NOT EXISTS (SELECT 1 FROM settings WHERE setting_key = 'local_shops.post.duration_days');

-- Turn auto-approve on for every module. Previously only marketplace, labour, rental and
-- women's corner were on, because the admin screen saves one tab at a time and the other tabs
-- were never saved — which is why posts kept arriving as pending.
UPDATE settings SET setting_value = 'true', updated_by = 'system', updated_at = NOW()
WHERE setting_key IN (
    'marketplace.post.auto_approve',
    'farmer.post.auto_approve',
    'labour.post.auto_approve',
    'travel.post.auto_approve',
    'parcel.post.auto_approve',
    'realestate.post.auto_approve',
    'rental.post.auto_approve',
    'womens_corner.post.auto_approve',
    'local_shops.post.auto_approve',
    'jobs.post.auto_approve'
) AND setting_value <> 'true';

-- Make sure the master switch exists; it stays off so posting is free right now.
INSERT INTO settings (setting_key, setting_value, description, category, setting_type, scope, is_active, is_required, is_read_only, default_value, display_order, created_by, updated_by, created_at, updated_at)
SELECT 'paid_post.enabled', 'false', 'Master switch for paid posting. false = posting and renewal are free and unlimited', 'PAID_POSTS', 'BOOLEAN', 'GLOBAL', true, false, false, 'true', 1, 'system', 'system', NOW(), NOW()
WHERE NOT EXISTS (SELECT 1 FROM settings WHERE setting_key = 'paid_post.enabled');
