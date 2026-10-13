-- Make the abandoned-cart reminder delay configurable instead of hardcoded at 2 hours.
--
-- The reminder itself is a LOCAL notification scheduled on the customer's phone: the cart
-- lives only on the device and there is no cart table on the server, so the backend cannot
-- know a cart is waiting and cannot push this over FCM. These rows only tell the app how
-- long to wait; the app reads them from /api/settings/public/category/CART (no auth) and
-- caches them for an hour, so a change here reaches customers without an app release.
--
-- Scope must be GLOBAL and is_active true, or getPublicSettingsByCategory filters the row
-- out and the app silently falls back to its built-in defaults.

INSERT INTO settings (setting_key, setting_value, description, category, setting_type, scope, is_active, is_required, is_read_only, default_value, display_order, created_by, updated_by, created_at, updated_at)
SELECT 'cart.reminder.delay_minutes', '10', 'Minutes of no cart activity before the "your cart is waiting" reminder fires on the customer phone. The timer restarts on every cart change, not on browsing. Android batches short delays while the phone is idle, so values under ~10 can fire several minutes late.', 'CART', 'INTEGER', 'GLOBAL', true, false, false, '10', 1, 'system', 'system', NOW(), NOW()
WHERE NOT EXISTS (SELECT 1 FROM settings WHERE setting_key = 'cart.reminder.delay_minutes');

-- How many reminders one abandoned cart gets, and when. Comma-separated minutes measured
-- from the last cart change, NOT from the previous reminder: "60,1440" means +1h and +24h,
-- which together with the first reminder above makes three. Drop an entry for two, blank the
-- value for one. Bad entries are ignored by the app rather than failing the whole list.
INSERT INTO settings (setting_key, setting_value, description, category, setting_type, scope, is_active, is_required, is_read_only, default_value, display_order, created_by, updated_by, created_at, updated_at)
SELECT 'cart.reminder.followup_minutes', '60,1440', 'Follow-up cart reminders, as comma-separated minutes after the last cart change (e.g. "60,1440" = 1 hour and 24 hours). With the first reminder that is 3 in total; use "1440" for 2, or leave blank for 1. Maximum 4 follow-ups.', 'CART', 'STRING', 'GLOBAL', true, false, false, '60,1440', 2, 'system', 'system', NOW(), NOW()
WHERE NOT EXISTS (SELECT 1 FROM settings WHERE setting_key = 'cart.reminder.followup_minutes');

-- Kill switch, so the reminder can be turned off without pushing a release.
INSERT INTO settings (setting_key, setting_value, description, category, setting_type, scope, is_active, is_required, is_read_only, default_value, display_order, created_by, updated_by, created_at, updated_at)
SELECT 'cart.reminder.enabled', 'true', 'Send abandoned-cart reminder notifications to customers', 'CART', 'BOOLEAN', 'GLOBAL', true, false, false, 'true', 3, 'system', 'system', NOW(), NOW()
WHERE NOT EXISTS (SELECT 1 FROM settings WHERE setting_key = 'cart.reminder.enabled');
