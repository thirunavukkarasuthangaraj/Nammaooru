-- Service Area Restriction Settings
-- Admin can restrict the app to a geographic area (center point + radius)

INSERT INTO settings (setting_key, setting_value, description, category, setting_type, scope, is_active, is_required, is_read_only, default_value, display_order, created_by, updated_by, created_at, updated_at)
VALUES
('service.area.enabled', 'false', 'Enable geographic service area restriction', 'SERVICE_AREA', 'BOOLEAN', 'GLOBAL', true, false, false, 'false', 1, 'system', 'system', NOW(), NOW()),
('service.area.center.latitude', '12.4955', 'Service area center latitude (Tirupattur default)', 'SERVICE_AREA', 'STRING', 'GLOBAL', true, false, false, '12.4955', 2, 'system', 'system', NOW(), NOW()),
('service.area.center.longitude', '78.5514', 'Service area center longitude (Tirupattur default)', 'SERVICE_AREA', 'STRING', 'GLOBAL', true, false, false, '78.5514', 3, 'system', 'system', NOW(), NOW()),
('service.area.radius.km', '50', 'Service area radius in kilometers', 'SERVICE_AREA', 'INTEGER', 'GLOBAL', true, false, false, '50', 4, 'system', 'system', NOW(), NOW())
ON CONFLICT (setting_key) DO NOTHING;
