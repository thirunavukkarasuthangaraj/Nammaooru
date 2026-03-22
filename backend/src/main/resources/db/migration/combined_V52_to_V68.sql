-- Combined migrations V52 to V68
-- Run this AFTER restoring the Feb 16 backup if Flyway doesn't auto-apply

-- ========== V52: create_post_payments_table ==========

CREATE TABLE IF NOT EXISTS post_payments (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL,
    razorpay_order_id VARCHAR(100) NOT NULL,
    razorpay_payment_id VARCHAR(100),
    razorpay_signature VARCHAR(255),
    amount INTEGER NOT NULL,
    currency VARCHAR(10) NOT NULL DEFAULT 'INR',
    post_type VARCHAR(50) NOT NULL,
    status VARCHAR(30) NOT NULL DEFAULT 'CREATED',
    consumed BOOLEAN NOT NULL DEFAULT FALSE,
    consumed_post_id BIGINT,
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    paid_at TIMESTAMP,
    consumed_at TIMESTAMP,
    CONSTRAINT fk_post_payments_user FOREIGN KEY (user_id) REFERENCES users(id)
);

CREATE INDEX IF NOT EXISTS idx_post_payments_user_id ON post_payments(user_id);
CREATE INDEX IF NOT EXISTS idx_post_payments_razorpay_order_id ON post_payments(razorpay_order_id);
CREATE INDEX IF NOT EXISTS idx_post_payments_status ON post_payments(status);

INSERT INTO settings (setting_key, setting_value, description, category, setting_type, scope, is_active, is_required, is_read_only, default_value, created_by, updated_by, created_at, updated_at)
SELECT 'paid_post.enabled', 'true', 'Enable pay-per-post when limit is reached', 'PAID_POSTS', 'BOOLEAN', 'GLOBAL', true, true, false, 'true', 'system', 'system', NOW(), NOW()
WHERE NOT EXISTS (SELECT 1 FROM settings WHERE setting_key = 'paid_post.enabled');

INSERT INTO settings (setting_key, setting_value, description, category, setting_type, scope, is_active, is_required, is_read_only, default_value, created_by, updated_by, created_at, updated_at)
SELECT 'paid_post.price', '10', 'Price per paid post in INR', 'PAID_POSTS', 'INTEGER', 'GLOBAL', true, true, false, '10', 'system', 'system', NOW(), NOW()
WHERE NOT EXISTS (SELECT 1 FROM settings WHERE setting_key = 'paid_post.price');

INSERT INTO settings (setting_key, setting_value, description, category, setting_type, scope, is_active, is_required, is_read_only, default_value, created_by, updated_by, created_at, updated_at)
SELECT 'paid_post.currency', 'INR', 'Currency for paid posts', 'PAID_POSTS', 'STRING', 'GLOBAL', true, true, false, 'INR', 'system', 'system', NOW(), NOW()
WHERE NOT EXISTS (SELECT 1 FROM settings WHERE setting_key = 'paid_post.currency');

-- ========== V53: add_location_to_marketplace_and_farmer ==========

ALTER TABLE marketplace_posts ADD COLUMN IF NOT EXISTS latitude DECIMAL(10, 8);
ALTER TABLE marketplace_posts ADD COLUMN IF NOT EXISTS longitude DECIMAL(11, 8);
ALTER TABLE farmer_products ADD COLUMN IF NOT EXISTS latitude DECIMAL(10, 8);
ALTER TABLE farmer_products ADD COLUMN IF NOT EXISTS longitude DECIMAL(11, 8);

-- ========== V54: add_location_indexes_for_posts ==========

CREATE INDEX IF NOT EXISTS idx_marketplace_posts_status_location ON marketplace_posts(status, latitude, longitude);
CREATE INDEX IF NOT EXISTS idx_farmer_products_status_location ON farmer_products(status, latitude, longitude);
CREATE INDEX IF NOT EXISTS idx_labour_posts_status_location ON labour_posts(status, latitude, longitude);
CREATE INDEX IF NOT EXISTS idx_travel_posts_status_location ON travel_posts(status, latitude, longitude);
CREATE INDEX IF NOT EXISTS idx_parcel_service_posts_status_location ON parcel_service_posts(status, latitude, longitude);
CREATE INDEX IF NOT EXISTS idx_users_location ON users(current_latitude, current_longitude) WHERE current_latitude IS NOT NULL AND current_longitude IS NOT NULL;

-- ========== V55: add_processing_fee_to_post_payments ==========

ALTER TABLE post_payments ADD COLUMN IF NOT EXISTS processing_fee INTEGER DEFAULT 0;
ALTER TABLE post_payments ADD COLUMN IF NOT EXISTS total_amount INTEGER;
UPDATE post_payments SET total_amount = amount * 100 WHERE total_amount IS NULL;

-- ========== V56: add_is_paid_and_per_type_pricing ==========

ALTER TABLE marketplace_posts ADD COLUMN IF NOT EXISTS is_paid BOOLEAN DEFAULT FALSE;
ALTER TABLE farmer_products ADD COLUMN IF NOT EXISTS is_paid BOOLEAN DEFAULT FALSE;
ALTER TABLE labour_posts ADD COLUMN IF NOT EXISTS is_paid BOOLEAN DEFAULT FALSE;
ALTER TABLE travel_posts ADD COLUMN IF NOT EXISTS is_paid BOOLEAN DEFAULT FALSE;
ALTER TABLE parcel_service_posts ADD COLUMN IF NOT EXISTS is_paid BOOLEAN DEFAULT FALSE;
ALTER TABLE real_estate_posts ADD COLUMN IF NOT EXISTS is_paid BOOLEAN DEFAULT FALSE;

INSERT INTO settings (setting_key, setting_value, description, category, setting_type, scope, is_active, is_required, is_read_only, default_value, display_order, created_by, updated_by, created_at, updated_at)
VALUES
('paid_post.price.MARKETPLACE', '10', 'Price for marketplace posts', 'PAID_POSTS', 'INTEGER', 'GLOBAL', true, false, false, '10', 1, 'system', 'system', NOW(), NOW()),
('paid_post.price.FARM_PRODUCTS', '10', 'Price for farmer product posts', 'PAID_POSTS', 'INTEGER', 'GLOBAL', true, false, false, '10', 2, 'system', 'system', NOW(), NOW()),
('paid_post.price.LABOURS', '5', 'Price for labour posts', 'PAID_POSTS', 'INTEGER', 'GLOBAL', true, false, false, '5', 3, 'system', 'system', NOW(), NOW()),
('paid_post.price.TRAVELS', '10', 'Price for travel posts', 'PAID_POSTS', 'INTEGER', 'GLOBAL', true, false, false, '10', 4, 'system', 'system', NOW(), NOW()),
('paid_post.price.PARCEL_SERVICE', '10', 'Price for parcel service posts', 'PAID_POSTS', 'INTEGER', 'GLOBAL', true, false, false, '10', 5, 'system', 'system', NOW(), NOW()),
('paid_post.price.REAL_ESTATE', '20', 'Price for real estate posts', 'PAID_POSTS', 'INTEGER', 'GLOBAL', true, false, false, '20', 6, 'system', 'system', NOW(), NOW())
ON CONFLICT (setting_key) DO NOTHING;

-- ========== V57: add_post_validity_and_expiry ==========

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

UPDATE marketplace_posts SET valid_from = created_at, valid_to = created_at + INTERVAL '30 days' WHERE valid_from IS NULL;
UPDATE farmer_products SET valid_from = created_at, valid_to = created_at + INTERVAL '60 days' WHERE valid_from IS NULL;
UPDATE labour_posts SET valid_from = created_at, valid_to = created_at + INTERVAL '60 days' WHERE valid_from IS NULL;
UPDATE travel_posts SET valid_from = created_at, valid_to = created_at + INTERVAL '30 days' WHERE valid_from IS NULL;
UPDATE parcel_service_posts SET valid_from = created_at, valid_to = created_at + INTERVAL '60 days' WHERE valid_from IS NULL;
UPDATE real_estate_posts SET valid_from = created_at, valid_to = created_at + INTERVAL '90 days' WHERE valid_from IS NULL;

CREATE INDEX IF NOT EXISTS idx_marketplace_posts_valid_to ON marketplace_posts(valid_to);
CREATE INDEX IF NOT EXISTS idx_farmer_products_valid_to ON farmer_products(valid_to);
CREATE INDEX IF NOT EXISTS idx_labour_posts_valid_to ON labour_posts(valid_to);
CREATE INDEX IF NOT EXISTS idx_travel_posts_valid_to ON travel_posts(valid_to);
CREATE INDEX IF NOT EXISTS idx_parcel_service_posts_valid_to ON parcel_service_posts(valid_to);
CREATE INDEX IF NOT EXISTS idx_real_estate_posts_valid_to ON real_estate_posts(valid_to);

INSERT INTO settings (setting_key, setting_value, description, category, setting_type, scope, is_active, is_required, is_read_only, default_value, display_order, created_by, updated_by, created_at, updated_at)
VALUES
('marketplace.post.duration_days', '30', 'Duration in days for marketplace posts', 'POST_SETTINGS', 'INTEGER', 'GLOBAL', true, false, false, '30', 1, 'system', 'system', NOW(), NOW()),
('farm_products.post.duration_days', '60', 'Duration in days for farmer product posts', 'POST_SETTINGS', 'INTEGER', 'GLOBAL', true, false, false, '60', 2, 'system', 'system', NOW(), NOW()),
('labours.post.duration_days', '60', 'Duration in days for labour posts', 'POST_SETTINGS', 'INTEGER', 'GLOBAL', true, false, false, '60', 3, 'system', 'system', NOW(), NOW()),
('travels.post.duration_days', '30', 'Duration in days for travel posts', 'POST_SETTINGS', 'INTEGER', 'GLOBAL', true, false, false, '30', 4, 'system', 'system', NOW(), NOW()),
('parcel_service.post.duration_days', '60', 'Duration in days for parcel service posts', 'POST_SETTINGS', 'INTEGER', 'GLOBAL', true, false, false, '60', 5, 'system', 'system', NOW(), NOW()),
('real_estate.post.duration_days', '90', 'Duration in days for real estate posts', 'POST_SETTINGS', 'INTEGER', 'GLOBAL', true, false, false, '90', 6, 'system', 'system', NOW(), NOW()),
('post.expiry.reminder_days_before', '3', 'Days before expiry to send reminder', 'POST_SETTINGS', 'INTEGER', 'GLOBAL', true, false, false, '3', 10, 'system', 'system', NOW(), NOW()),
('post.expiry.grace_period_days', '7', 'Days after expiry before auto-deletion', 'POST_SETTINGS', 'INTEGER', 'GLOBAL', true, false, false, '7', 11, 'system', 'system', NOW(), NOW())
ON CONFLICT (setting_key) DO NOTHING;

-- ========== V58: create_health_tip_queue_table ==========

CREATE TABLE IF NOT EXISTS health_tip_queue (
    id BIGSERIAL PRIMARY KEY,
    message TEXT NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'PENDING',
    scheduled_date DATE,
    sent_at TIMESTAMP,
    approved_by VARCHAR(100),
    approved_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_health_tip_queue_status ON health_tip_queue(status);
CREATE INDEX IF NOT EXISTS idx_health_tip_queue_scheduled_date ON health_tip_queue(scheduled_date);

-- ========== V59: add_health_tip_notifications_enabled_to_users ==========

ALTER TABLE users ADD COLUMN IF NOT EXISTS health_tip_notifications_enabled BOOLEAN DEFAULT true;

-- ========== V60: add_fssai_grocery_license_to_shops ==========

ALTER TABLE shops ADD COLUMN IF NOT EXISTS fssai_certificate_number VARCHAR(20);
ALTER TABLE shops ADD COLUMN IF NOT EXISTS grocery_license_number VARCHAR(30);

-- ========== V61: fix_health_tip_notifications_enabled_null_values ==========

UPDATE users SET health_tip_notifications_enabled = true WHERE health_tip_notifications_enabled IS NULL;

-- ========== V62: add_rental_and_real_estate_feature_configs ==========

INSERT INTO feature_configs (feature_name, display_name, display_name_tamil, icon, color, route, latitude, longitude, radius_km, is_active, display_order, max_posts_per_user)
VALUES
('RENTAL', 'Rentals', 'வாடகை', 'vpn_key_rounded', '#795548', '/customer/rentals', 12.4966000, 78.5729000, 100, true, 9, 0),
('REAL_ESTATE', 'Real Estate', 'ரியல் எஸ்டேட்', 'home_work_rounded', '#607D8B', '/customer/real-estate', 12.4966000, 78.5729000, 100, true, 10, 0)
ON CONFLICT (feature_name) DO NOTHING;

-- ========== V63: Insert_privacy_policy ==========

INSERT INTO settings (setting_key, setting_value, description, category, setting_type, scope, is_active, is_required, is_read_only, default_value, display_order, created_at, updated_at, created_by, updated_by)
VALUES (
    'PRIVACY_POLICY_EN',
    'Privacy Policy - English version (see V63 migration file for full text)',
    'Privacy Policy - English',
    'LEGAL', 'STRING', 'GLOBAL', true, false, false, NULL, 1, NOW(), NOW(), 'system', 'system'
) ON CONFLICT (setting_key) DO NOTHING;

INSERT INTO settings (setting_key, setting_value, description, category, setting_type, scope, is_active, is_required, is_read_only, default_value, display_order, created_at, updated_at, created_by, updated_by)
VALUES (
    'PRIVACY_POLICY_TA',
    'Privacy Policy - Tamil version (see V63 migration file for full text)',
    'Privacy Policy - Tamil',
    'LEGAL', 'STRING', 'GLOBAL', true, false, false, NULL, 2, NOW(), NOW(), 'system', 'system'
) ON CONFLICT (setting_key) DO NOTHING;

-- ========== V64: Rename_parcel_to_packers_movers ==========

UPDATE feature_configs
SET display_name = 'Packers & Movers',
    display_name_tamil = 'பேக்கர்ஸ் & மூவர்ஸ்',
    updated_at = NOW()
WHERE feature_name = 'PARCEL_SERVICE';

-- ========== V65: global_free_post_limit_setting ==========

INSERT INTO settings (setting_key, setting_value, description, category, setting_type, scope, is_active, is_required, is_read_only, default_value, display_order, created_by, updated_by, created_at, updated_at)
SELECT 'global.free_post_limit', '1', 'Number of free posts allowed across all modules before payment is required', 'POST_LIMITS', 'INTEGER', 'GLOBAL', true, false, false, '1', 0, 'system', 'system', NOW(), NOW()
WHERE NOT EXISTS (SELECT 1 FROM settings WHERE setting_key = 'global.free_post_limit');

-- ========== V66: add_rental_pricing_and_duration_settings ==========

INSERT INTO settings (setting_key, setting_value, description, category, setting_type, scope, is_active, is_required, is_read_only, default_value, display_order, created_by, updated_by, created_at, updated_at)
SELECT 'paid_post.price.RENTAL', '10', 'Price for rental posts', 'PAID_POSTS', 'INTEGER', 'GLOBAL', true, false, false, '10', 7, 'system', 'system', NOW(), NOW()
WHERE NOT EXISTS (SELECT 1 FROM settings WHERE setting_key = 'paid_post.price.RENTAL');

INSERT INTO settings (setting_key, setting_value, description, category, setting_type, scope, is_active, is_required, is_read_only, default_value, display_order, created_by, updated_by, created_at, updated_at)
SELECT 'rental.post.duration_days', '30', 'Duration in days for rental posts', 'POST_SETTINGS', 'INTEGER', 'GLOBAL', true, false, false, '30', 7, 'system', 'system', NOW(), NOW()
WHERE NOT EXISTS (SELECT 1 FROM settings WHERE setting_key = 'rental.post.duration_days');

-- ========== V67: add_missing_real_estate_rental_settings ==========

INSERT INTO settings (setting_key, setting_value, description, category, setting_type, scope, is_active, is_required, is_read_only, default_value, display_order, created_by, updated_by, created_at, updated_at)
SELECT 'real_estate.post.auto_approve', 'false', 'Auto-approve real estate posts', 'REAL_ESTATE', 'BOOLEAN', 'GLOBAL', true, false, false, 'false', 1, 'system', 'system', NOW(), NOW()
WHERE NOT EXISTS (SELECT 1 FROM settings WHERE setting_key = 'real_estate.post.auto_approve');

INSERT INTO settings (setting_key, setting_value, description, category, setting_type, scope, is_active, is_required, is_read_only, default_value, display_order, created_by, updated_by, created_at, updated_at)
SELECT 'real_estate.post.report_threshold', '3', 'Reports before auto-hiding real estate posts', 'REAL_ESTATE', 'INTEGER', 'GLOBAL', true, false, false, '3', 2, 'system', 'system', NOW(), NOW()
WHERE NOT EXISTS (SELECT 1 FROM settings WHERE setting_key = 'real_estate.post.report_threshold');

INSERT INTO settings (setting_key, setting_value, description, category, setting_type, scope, is_active, is_required, is_read_only, default_value, display_order, created_by, updated_by, created_at, updated_at)
SELECT 'rental.post.auto_approve', 'false', 'Auto-approve rental posts', 'RENTAL', 'BOOLEAN', 'GLOBAL', true, false, false, 'false', 1, 'system', 'system', NOW(), NOW()
WHERE NOT EXISTS (SELECT 1 FROM settings WHERE setting_key = 'rental.post.auto_approve');

INSERT INTO settings (setting_key, setting_value, description, category, setting_type, scope, is_active, is_required, is_read_only, default_value, display_order, created_by, updated_by, created_at, updated_at)
SELECT 'rental.post.report_threshold', '3', 'Reports before auto-hiding rental posts', 'RENTAL', 'INTEGER', 'GLOBAL', true, false, false, '3', 2, 'system', 'system', NOW(), NOW()
WHERE NOT EXISTS (SELECT 1 FROM settings WHERE setting_key = 'rental.post.report_threshold');

INSERT INTO settings (setting_key, setting_value, description, category, setting_type, scope, is_active, is_required, is_read_only, default_value, display_order, created_by, updated_by, created_at, updated_at)
SELECT 'paid_post.processing_fee_percent', '2.36', 'Processing fee percentage (Razorpay 2% + 18% GST)', 'PAID_POSTS', 'DECIMAL', 'GLOBAL', true, false, false, '2.36', 8, 'system', 'system', NOW(), NOW()
WHERE NOT EXISTS (SELECT 1 FROM settings WHERE setting_key = 'paid_post.processing_fee_percent');

-- ========== V68: add_service_area_settings ==========

INSERT INTO settings (setting_key, setting_value, description, category, setting_type, scope, is_active, is_required, is_read_only, default_value, display_order, created_by, updated_by, created_at, updated_at)
VALUES
('service.area.enabled', 'false', 'Enable geographic service area restriction', 'SERVICE_AREA', 'BOOLEAN', 'GLOBAL', true, false, false, 'false', 1, 'system', 'system', NOW(), NOW()),
('service.area.center.latitude', '12.4955', 'Service area center latitude', 'SERVICE_AREA', 'STRING', 'GLOBAL', true, false, false, '12.4955', 2, 'system', 'system', NOW(), NOW()),
('service.area.center.longitude', '78.5514', 'Service area center longitude', 'SERVICE_AREA', 'STRING', 'GLOBAL', true, false, false, '78.5514', 3, 'system', 'system', NOW(), NOW()),
('service.area.radius.km', '50', 'Service area radius in kilometers', 'SERVICE_AREA', 'INTEGER', 'GLOBAL', true, false, false, '50', 4, 'system', 'system', NOW(), NOW())
ON CONFLICT (setting_key) DO NOTHING;
