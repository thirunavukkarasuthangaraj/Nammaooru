CREATE TABLE IF NOT EXISTS parcel_service_posts (
    id BIGSERIAL PRIMARY KEY,
    service_name VARCHAR(200) NOT NULL,
    phone VARCHAR(20) NOT NULL,
    service_type VARCHAR(30) NOT NULL,
    from_location VARCHAR(200),
    to_location VARCHAR(200),
    price_info VARCHAR(200),
    address VARCHAR(500),
    timings VARCHAR(200),
    description VARCHAR(1000),
    image_urls VARCHAR(1500),
    latitude NUMERIC(10, 8),
    longitude NUMERIC(11, 8),
    seller_user_id BIGINT NOT NULL,
    seller_name VARCHAR(200),
    report_count INTEGER DEFAULT 0,
    status VARCHAR(30) DEFAULT 'PENDING_APPROVAL',
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP,
    CONSTRAINT fk_parcel_posts_seller FOREIGN KEY (seller_user_id) REFERENCES users(id)
);

CREATE INDEX IF NOT EXISTS idx_parcel_posts_status ON parcel_service_posts(status);
CREATE INDEX IF NOT EXISTS idx_parcel_posts_service_type ON parcel_service_posts(service_type);
CREATE INDEX IF NOT EXISTS idx_parcel_posts_seller ON parcel_service_posts(seller_user_id);
CREATE INDEX IF NOT EXISTS idx_parcel_posts_created_at ON parcel_service_posts(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_parcel_posts_location ON parcel_service_posts(latitude, longitude) WHERE latitude IS NOT NULL;

-- Insert default settings for parcels
INSERT INTO settings (setting_key, setting_value, description, category, setting_type, scope, is_active, is_required, is_read_only, default_value, created_by, updated_by, created_at, updated_at)
VALUES ('parcels.post.duration_days', '60', 'Number of days a parcel service listing stays visible', 'PARCELS', 'INTEGER', 'GLOBAL', true, true, false, '60', 'system', 'system', NOW(), NOW())
ON CONFLICT (setting_key) DO NOTHING;

INSERT INTO settings (setting_key, setting_value, description, category, setting_type, scope, is_active, is_required, is_read_only, default_value, created_by, updated_by, created_at, updated_at)
VALUES ('parcels.post.auto_approve', 'true', 'Auto-approve new parcel service listings without admin review', 'PARCELS', 'BOOLEAN', 'GLOBAL', true, true, false, 'true', 'system', 'system', NOW(), NOW())
ON CONFLICT (setting_key) DO NOTHING;

INSERT INTO settings (setting_key, setting_value, description, category, setting_type, scope, is_active, is_required, is_read_only, default_value, created_by, updated_by, created_at, updated_at)
VALUES ('parcels.post.visible_statuses', '["APPROVED"]', 'Which parcel service listing statuses are visible to public', 'PARCELS', 'JSON', 'GLOBAL', true, true, false, '["APPROVED"]', 'system', 'system', NOW(), NOW())
ON CONFLICT (setting_key) DO NOTHING;

INSERT INTO settings (setting_key, setting_value, description, category, setting_type, scope, is_active, is_required, is_read_only, default_value, created_by, updated_by, created_at, updated_at)
VALUES ('parcels.post.report_threshold', '3', 'Number of reports before auto-flagging a parcel service listing', 'PARCELS', 'INTEGER', 'GLOBAL', true, true, false, '3', 'system', 'system', NOW(), NOW())
ON CONFLICT (setting_key) DO NOTHING;

INSERT INTO settings (setting_key, setting_value, description, category, setting_type, scope, is_active, is_required, is_read_only, default_value, created_by, updated_by, created_at, updated_at)
VALUES ('parcels.post.user_limit', '0', 'Maximum active parcel service listings per user (0 = unlimited)', 'PARCELS', 'INTEGER', 'GLOBAL', true, true, false, '0', 'system', 'system', NOW(), NOW())
ON CONFLICT (setting_key) DO NOTHING;
