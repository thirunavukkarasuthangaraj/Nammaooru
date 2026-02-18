-- Add isPaid column to all post tables
ALTER TABLE marketplace_posts ADD COLUMN IF NOT EXISTS is_paid BOOLEAN DEFAULT FALSE;
ALTER TABLE farmer_products ADD COLUMN IF NOT EXISTS is_paid BOOLEAN DEFAULT FALSE;
ALTER TABLE labour_posts ADD COLUMN IF NOT EXISTS is_paid BOOLEAN DEFAULT FALSE;
ALTER TABLE travel_posts ADD COLUMN IF NOT EXISTS is_paid BOOLEAN DEFAULT FALSE;
ALTER TABLE parcel_service_posts ADD COLUMN IF NOT EXISTS is_paid BOOLEAN DEFAULT FALSE;
ALTER TABLE real_estate_posts ADD COLUMN IF NOT EXISTS is_paid BOOLEAN DEFAULT FALSE;

-- Backfill paid posts from post_payments
UPDATE marketplace_posts SET is_paid = TRUE WHERE id IN (SELECT consumed_post_id FROM post_payments WHERE status = 'PAID' AND consumed = TRUE AND post_type = 'MARKETPLACE');
UPDATE farmer_products SET is_paid = TRUE WHERE id IN (SELECT consumed_post_id FROM post_payments WHERE status = 'PAID' AND consumed = TRUE AND post_type = 'FARM_PRODUCTS');
UPDATE labour_posts SET is_paid = TRUE WHERE id IN (SELECT consumed_post_id FROM post_payments WHERE status = 'PAID' AND consumed = TRUE AND post_type = 'LABOURS');
UPDATE travel_posts SET is_paid = TRUE WHERE id IN (SELECT consumed_post_id FROM post_payments WHERE status = 'PAID' AND consumed = TRUE AND post_type = 'TRAVELS');
UPDATE parcel_service_posts SET is_paid = TRUE WHERE id IN (SELECT consumed_post_id FROM post_payments WHERE status = 'PAID' AND consumed = TRUE AND post_type = 'PARCEL_SERVICE');

-- Seed per-type pricing settings
INSERT INTO settings (setting_key, setting_value, description, category, setting_type, scope, is_active, is_required, is_read_only, default_value, display_order, created_by, updated_by, created_at, updated_at)
VALUES
('paid_post.price.MARKETPLACE', '10', 'Price for marketplace posts (₹)', 'PAID_POSTS', 'INTEGER', 'GLOBAL', true, false, false, '10', 1, 'system', 'system', NOW(), NOW()),
('paid_post.price.FARM_PRODUCTS', '10', 'Price for farmer product posts (₹)', 'PAID_POSTS', 'INTEGER', 'GLOBAL', true, false, false, '10', 2, 'system', 'system', NOW(), NOW()),
('paid_post.price.LABOURS', '5', 'Price for labour posts (₹)', 'PAID_POSTS', 'INTEGER', 'GLOBAL', true, false, false, '5', 3, 'system', 'system', NOW(), NOW()),
('paid_post.price.TRAVELS', '10', 'Price for travel posts (₹)', 'PAID_POSTS', 'INTEGER', 'GLOBAL', true, false, false, '10', 4, 'system', 'system', NOW(), NOW()),
('paid_post.price.PARCEL_SERVICE', '10', 'Price for parcel service posts (₹)', 'PAID_POSTS', 'INTEGER', 'GLOBAL', true, false, false, '10', 5, 'system', 'system', NOW(), NOW()),
('paid_post.price.REAL_ESTATE', '20', 'Price for real estate posts (₹)', 'PAID_POSTS', 'INTEGER', 'GLOBAL', true, false, false, '20', 6, 'system', 'system', NOW(), NOW())
ON CONFLICT (setting_key) DO NOTHING;
