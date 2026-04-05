-- =====================================================
-- Local Shops Module Migration
-- Run this on the production database
-- =====================================================

-- 1. Create the local_shop_posts table
CREATE TABLE IF NOT EXISTS local_shop_posts (
    id                    BIGSERIAL PRIMARY KEY,
    shop_name             VARCHAR(200) NOT NULL,
    phone                 VARCHAR(20) NOT NULL,
    category              VARCHAR(30) NOT NULL,
    address               VARCHAR(500),
    timings               VARCHAR(200),
    description           VARCHAR(1000),
    image_urls            VARCHAR(1500),
    latitude              DECIMAL(10, 8),
    longitude             DECIMAL(11, 8),
    seller_user_id        BIGINT NOT NULL,
    seller_name           VARCHAR(200),
    featured              BOOLEAN DEFAULT FALSE,
    report_count          INTEGER DEFAULT 0,
    status                VARCHAR(30) DEFAULT 'PENDING_APPROVAL',
    is_paid               BOOLEAN DEFAULT FALSE,
    valid_from            TIMESTAMP,
    valid_to              TIMESTAMP,
    expiry_reminder_sent  BOOLEAN DEFAULT FALSE,
    created_at            TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at            TIMESTAMP
);

-- 2. Indexes for performance
CREATE INDEX IF NOT EXISTS idx_local_shop_posts_status ON local_shop_posts(status);
CREATE INDEX IF NOT EXISTS idx_local_shop_posts_seller ON local_shop_posts(seller_user_id);
CREATE INDEX IF NOT EXISTS idx_local_shop_posts_category ON local_shop_posts(category);
CREATE INDEX IF NOT EXISTS idx_local_shop_posts_created ON local_shop_posts(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_local_shop_posts_location ON local_shop_posts(latitude, longitude);

-- 3. Add feature_config entry (insert only if not exists)
INSERT INTO feature_configs (feature_name, display_name, display_name_tamil, icon, color, route, is_active, display_order, description, created_at, updated_at)
SELECT 'LOCAL_SHOPS', 'Local Shops', 'கடைகள்', 'store', '#FF6F00', '/local-shops', true, 10, 'Post your local shop for everyone to find', NOW(), NOW()
WHERE NOT EXISTS (SELECT 1 FROM feature_configs WHERE feature_name = 'LOCAL_SHOPS');

-- 4. Default settings
INSERT INTO settings (setting_key, setting_value, description, created_at, updated_at)
SELECT 'local_shops.post.auto_approve', 'false', 'Auto approve local shop posts', NOW(), NOW()
WHERE NOT EXISTS (SELECT 1 FROM settings WHERE setting_key = 'local_shops.post.auto_approve');

INSERT INTO settings (setting_key, setting_value, description, created_at, updated_at)
SELECT 'local_shops.post.duration_days', '60', 'How many days a local shop post is valid', NOW(), NOW()
WHERE NOT EXISTS (SELECT 1 FROM settings WHERE setting_key = 'local_shops.post.duration_days');

INSERT INTO settings (setting_key, setting_value, description, created_at, updated_at)
SELECT 'local_shops.post.report_threshold', '3', 'Reports needed to auto-flag a local shop post', NOW(), NOW()
WHERE NOT EXISTS (SELECT 1 FROM settings WHERE setting_key = 'local_shops.post.report_threshold');

INSERT INTO settings (setting_key, setting_value, description, created_at, updated_at)
SELECT 'local_shops.post.visible_statuses', '["APPROVED"]', 'Statuses visible in local shops feed', NOW(), NOW()
WHERE NOT EXISTS (SELECT 1 FROM settings WHERE setting_key = 'local_shops.post.visible_statuses');
