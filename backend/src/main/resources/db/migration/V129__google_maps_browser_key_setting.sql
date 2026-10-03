-- Google Maps browser key for the website is served from settings
-- (GET /api/transport/public/maps-key) instead of being hardcoded in index.html.
-- The value is intentionally empty here: paste the real key in Admin > Settings
-- (or set env GOOGLE_MAPS_BROWSER_KEY on the backend). Keep the key restricted
-- to the website's HTTP referrers in Google Cloud Console.
INSERT INTO settings (setting_key, setting_value, description, category, setting_type, scope, is_active, is_required, is_read_only, default_value, display_order, created_by, updated_by, created_at, updated_at)
SELECT 'google.maps.browser_key', '',
       'Google Maps JavaScript API key for the website (restrict to nammaoorudelivary.in in Google Cloud)',
       'INTEGRATION', 'STRING', 'GLOBAL', true, false, false, '', 90, 'system', 'system', NOW(), NOW()
WHERE NOT EXISTS (SELECT 1 FROM settings WHERE setting_key = 'google.maps.browser_key');
