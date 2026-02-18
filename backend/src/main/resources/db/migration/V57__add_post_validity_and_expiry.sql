-- Add validity columns to all 6 post tables
ALTER TABLE marketplace_posts ADD COLUMN IF NOT EXISTS valid_from TIMESTAMP;
ALTER TABLE marketplace_posts ADD COLUMN IF NOT EXISTS valid_to TIMESTAMP;
ALTER TABLE marketplace_posts ADD COLUMN IF NOT EXISTS expiry_reminder_sent BOOLEAN DEFAULT FALSE;

ALTER TABLE farmer_products ADD COLUMN IF NOT EXISTS valid_from TIMESTAMP;
ALTER TABLE farmer_products ADD COLUMN IF NOT EXISTS valid_to TIMESTAMP;
ALTER TABLE farmer_products ADD COLUMN IF NOT EXISTS expiry_reminder_sent BOOLEAN DEFAULT FALSE;

ALTER TABLE labour_posts ADD COLUMN IF NOT EXISTS valid_from TIMESTAMP;
ALTER TABLE labour_posts ADD COLUMN IF NOT EXISTS valid_to TIMESTAMP;
ALTER TABLE labour_posts ADD COLUMN IF NOT EXISTS expiry_reminder_sent BOOLEAN DEFAULT FALSE;

ALTER TABLE travel_posts ADD COLUMN IF NOT EXISTS valid_from TIMESTAMP;
ALTER TABLE travel_posts ADD COLUMN IF NOT EXISTS valid_to TIMESTAMP;
ALTER TABLE travel_posts ADD COLUMN IF NOT EXISTS expiry_reminder_sent BOOLEAN DEFAULT FALSE;

ALTER TABLE parcel_service_posts ADD COLUMN IF NOT EXISTS valid_from TIMESTAMP;
ALTER TABLE parcel_service_posts ADD COLUMN IF NOT EXISTS valid_to TIMESTAMP;
ALTER TABLE parcel_service_posts ADD COLUMN IF NOT EXISTS expiry_reminder_sent BOOLEAN DEFAULT FALSE;

ALTER TABLE real_estate_posts ADD COLUMN IF NOT EXISTS valid_from TIMESTAMP;
ALTER TABLE real_estate_posts ADD COLUMN IF NOT EXISTS valid_to TIMESTAMP;
ALTER TABLE real_estate_posts ADD COLUMN IF NOT EXISTS expiry_reminder_sent BOOLEAN DEFAULT FALSE;

-- Backfill existing posts: valid_from = created_at, valid_to = created_at + duration_days from settings
-- Default to 30 days if no setting exists
UPDATE marketplace_posts SET valid_from = created_at, valid_to = created_at + INTERVAL '30 days' WHERE valid_from IS NULL;
UPDATE farmer_products SET valid_from = created_at, valid_to = created_at + INTERVAL '60 days' WHERE valid_from IS NULL;
UPDATE labour_posts SET valid_from = created_at, valid_to = created_at + INTERVAL '60 days' WHERE valid_from IS NULL;
UPDATE travel_posts SET valid_from = created_at, valid_to = created_at + INTERVAL '30 days' WHERE valid_from IS NULL;
UPDATE parcel_service_posts SET valid_from = created_at, valid_to = created_at + INTERVAL '60 days' WHERE valid_from IS NULL;
UPDATE real_estate_posts SET valid_from = created_at, valid_to = created_at + INTERVAL '90 days' WHERE valid_from IS NULL;

-- Add indexes on valid_to for scheduler queries
CREATE INDEX IF NOT EXISTS idx_marketplace_posts_valid_to ON marketplace_posts(valid_to);
CREATE INDEX IF NOT EXISTS idx_farmer_products_valid_to ON farmer_products(valid_to);
CREATE INDEX IF NOT EXISTS idx_labour_posts_valid_to ON labour_posts(valid_to);
CREATE INDEX IF NOT EXISTS idx_travel_posts_valid_to ON travel_posts(valid_to);
CREATE INDEX IF NOT EXISTS idx_parcel_service_posts_valid_to ON parcel_service_posts(valid_to);
CREATE INDEX IF NOT EXISTS idx_real_estate_posts_valid_to ON real_estate_posts(valid_to);

-- Seed duration settings for post types that may not have them yet
INSERT INTO settings (setting_key, setting_value, description, category, setting_type, scope, is_active, is_required, is_read_only, default_value, display_order, created_by, updated_by, created_at, updated_at)
VALUES
('marketplace.post.duration_days', '30', 'Duration in days for marketplace posts', 'POST_SETTINGS', 'INTEGER', 'GLOBAL', true, false, false, '30', 1, 'system', 'system', NOW(), NOW()),
('farm_products.post.duration_days', '60', 'Duration in days for farmer product posts', 'POST_SETTINGS', 'INTEGER', 'GLOBAL', true, false, false, '60', 2, 'system', 'system', NOW(), NOW()),
('labours.post.duration_days', '60', 'Duration in days for labour posts', 'POST_SETTINGS', 'INTEGER', 'GLOBAL', true, false, false, '60', 3, 'system', 'system', NOW(), NOW()),
('travels.post.duration_days', '30', 'Duration in days for travel posts', 'POST_SETTINGS', 'INTEGER', 'GLOBAL', true, false, false, '30', 4, 'system', 'system', NOW(), NOW()),
('parcel_service.post.duration_days', '60', 'Duration in days for parcel service posts', 'POST_SETTINGS', 'INTEGER', 'GLOBAL', true, false, false, '60', 5, 'system', 'system', NOW(), NOW()),
('real_estate.post.duration_days', '90', 'Duration in days for real estate posts', 'POST_SETTINGS', 'INTEGER', 'GLOBAL', true, false, false, '90', 6, 'system', 'system', NOW(), NOW())
ON CONFLICT (setting_key) DO NOTHING;

-- Seed expiry config settings
INSERT INTO settings (setting_key, setting_value, description, category, setting_type, scope, is_active, is_required, is_read_only, default_value, display_order, created_by, updated_by, created_at, updated_at)
VALUES
('post.expiry.reminder_days_before', '3', 'Days before expiry to send reminder', 'POST_SETTINGS', 'INTEGER', 'GLOBAL', true, false, false, '3', 10, 'system', 'system', NOW(), NOW()),
('post.expiry.grace_period_days', '7', 'Days after expiry before auto-deletion', 'POST_SETTINGS', 'INTEGER', 'GLOBAL', true, false, false, '7', 11, 'system', 'system', NOW(), NOW())
ON CONFLICT (setting_key) DO NOTHING;
