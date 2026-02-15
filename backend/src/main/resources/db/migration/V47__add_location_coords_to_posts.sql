-- Add GPS coordinates to labour_posts for location-based filtering
ALTER TABLE labour_posts ADD COLUMN latitude NUMERIC(10, 8);
ALTER TABLE labour_posts ADD COLUMN longitude NUMERIC(11, 8);

-- Partial index for location queries (only index rows with coordinates)
CREATE INDEX idx_labour_posts_location ON labour_posts(latitude, longitude) WHERE latitude IS NOT NULL;

-- Add user_limit setting for labours
INSERT INTO settings (setting_key, setting_value, description, category, setting_type, scope, is_active, is_required, is_read_only, default_value, created_by, updated_by, created_at, updated_at)
VALUES ('labours.post.user_limit', '0', 'Maximum active labour listings per user (0 = unlimited)', 'LABOURS', 'INTEGER', 'GLOBAL', true, true, false, '0', 'system', 'system', NOW(), NOW())
ON CONFLICT (setting_key) DO NOTHING;
