CREATE TABLE IF NOT EXISTS travel_posts (
    id BIGSERIAL PRIMARY KEY,
    title VARCHAR(200) NOT NULL,
    phone VARCHAR(20) NOT NULL,
    vehicle_type VARCHAR(30) NOT NULL,
    from_location VARCHAR(200),
    to_location VARCHAR(200),
    price VARCHAR(50),
    seats_available INTEGER,
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
    CONSTRAINT fk_travel_posts_seller FOREIGN KEY (seller_user_id) REFERENCES users(id)
);

CREATE INDEX IF NOT EXISTS idx_travel_posts_status ON travel_posts(status);
CREATE INDEX IF NOT EXISTS idx_travel_posts_vehicle_type ON travel_posts(vehicle_type);
CREATE INDEX IF NOT EXISTS idx_travel_posts_seller ON travel_posts(seller_user_id);
CREATE INDEX IF NOT EXISTS idx_travel_posts_created_at ON travel_posts(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_travel_posts_location ON travel_posts(latitude, longitude) WHERE latitude IS NOT NULL;

-- Insert default settings for travels
INSERT INTO settings (setting_key, setting_value, description, category, setting_type, scope, is_active, is_required, is_read_only, default_value, created_by, updated_by, created_at, updated_at)
VALUES ('travels.post.duration_days', '60', 'Number of days a travel listing stays visible', 'TRAVELS', 'INTEGER', 'GLOBAL', true, true, false, '60', 'system', 'system', NOW(), NOW())
ON CONFLICT (setting_key) DO NOTHING;

INSERT INTO settings (setting_key, setting_value, description, category, setting_type, scope, is_active, is_required, is_read_only, default_value, created_by, updated_by, created_at, updated_at)
VALUES ('travels.post.auto_approve', 'false', 'Auto-approve new travel listings without admin review', 'TRAVELS', 'BOOLEAN', 'GLOBAL', true, true, false, 'false', 'system', 'system', NOW(), NOW())
ON CONFLICT (setting_key) DO NOTHING;

INSERT INTO settings (setting_key, setting_value, description, category, setting_type, scope, is_active, is_required, is_read_only, default_value, created_by, updated_by, created_at, updated_at)
VALUES ('travels.post.visible_statuses', '["APPROVED"]', 'Which travel listing statuses are visible to public', 'TRAVELS', 'JSON', 'GLOBAL', true, true, false, '["APPROVED"]', 'system', 'system', NOW(), NOW())
ON CONFLICT (setting_key) DO NOTHING;

INSERT INTO settings (setting_key, setting_value, description, category, setting_type, scope, is_active, is_required, is_read_only, default_value, created_by, updated_by, created_at, updated_at)
VALUES ('travels.post.report_threshold', '3', 'Number of reports before auto-flagging a travel listing', 'TRAVELS', 'INTEGER', 'GLOBAL', true, true, false, '3', 'system', 'system', NOW(), NOW())
ON CONFLICT (setting_key) DO NOTHING;

INSERT INTO settings (setting_key, setting_value, description, category, setting_type, scope, is_active, is_required, is_read_only, default_value, created_by, updated_by, created_at, updated_at)
VALUES ('travels.post.user_limit', '0', 'Maximum active travel listings per user (0 = unlimited)', 'TRAVELS', 'INTEGER', 'GLOBAL', true, true, false, '0', 'system', 'system', NOW(), NOW())
ON CONFLICT (setting_key) DO NOTHING;
