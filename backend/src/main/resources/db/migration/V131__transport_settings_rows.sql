-- Transport timing settings editable from Admin > Settings (no deploy needed).
INSERT INTO settings (setting_key, setting_value, description, category, setting_type, scope, is_active, is_required, is_read_only, default_value, display_order, created_by, updated_by, created_at, updated_at)
SELECT k, v, d, 'TRANSPORT', t, 'GLOBAL', true, false, false, v, o, 'system', 'system', NOW(), NOW()
FROM (VALUES
  ('transport.gps_interval_bus_sec',     '5',    'Driver app: seconds between GPS sends for BUS while moving',                       'INTEGER', 10),
  ('transport.gps_interval_default_sec', '10',   'Driver app: seconds between GPS sends for other vehicle types while moving',       'INTEGER', 11),
  ('transport.gps_idle_interval_sec',    '30',   'Driver app: seconds between GPS sends while the vehicle is stationary (battery)', 'INTEGER', 12),
  ('transport.poll_interval_sec',        '5',    'App & website: seconds between live position refreshes',                          'INTEGER', 13),
  ('transport.stale_after_sec',          '120',  'Seconds without a GPS point before a vehicle is shown as offline',                'INTEGER', 14),
  ('transport.public_tracking',          'true', 'Show public buses on Where is Bus (true/false)',                                   'BOOLEAN', 15)
) AS s(k, v, d, t, o)
WHERE NOT EXISTS (SELECT 1 FROM settings WHERE setting_key = s.k);
