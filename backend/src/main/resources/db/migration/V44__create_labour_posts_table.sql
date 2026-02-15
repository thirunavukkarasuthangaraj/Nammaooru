CREATE TABLE labour_posts (
    id BIGSERIAL PRIMARY KEY,
    name VARCHAR(200) NOT NULL,
    phone VARCHAR(20) NOT NULL,
    category VARCHAR(30) NOT NULL,
    experience VARCHAR(100),
    location VARCHAR(200),
    description VARCHAR(1000),
    image_url VARCHAR(500),
    seller_user_id BIGINT NOT NULL,
    seller_name VARCHAR(200),
    report_count INTEGER DEFAULT 0,
    status VARCHAR(30) DEFAULT 'PENDING_APPROVAL',
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP,
    CONSTRAINT fk_labour_posts_seller FOREIGN KEY (seller_user_id) REFERENCES users(id)
);

CREATE INDEX idx_labour_posts_status ON labour_posts(status);
CREATE INDEX idx_labour_posts_category ON labour_posts(category);
CREATE INDEX idx_labour_posts_seller ON labour_posts(seller_user_id);
CREATE INDEX idx_labour_posts_created_at ON labour_posts(created_at DESC);

-- Insert default settings for labours
INSERT INTO settings (setting_key, setting_value, description, category, setting_type, scope, is_active, is_required, is_read_only, default_value, created_by, updated_by, created_at, updated_at)
VALUES ('labours.post.duration_days', '60', 'Number of days a labour listing stays visible', 'LABOURS', 'INTEGER', 'GLOBAL', true, true, false, '60', 'system', 'system', NOW(), NOW())
ON CONFLICT (setting_key) DO NOTHING;

INSERT INTO settings (setting_key, setting_value, description, category, setting_type, scope, is_active, is_required, is_read_only, default_value, created_by, updated_by, created_at, updated_at)
VALUES ('labours.post.auto_approve', 'true', 'Auto-approve new labour listings without admin review', 'LABOURS', 'BOOLEAN', 'GLOBAL', true, true, false, 'true', 'system', 'system', NOW(), NOW())
ON CONFLICT (setting_key) DO NOTHING;

INSERT INTO settings (setting_key, setting_value, description, category, setting_type, scope, is_active, is_required, is_read_only, default_value, created_by, updated_by, created_at, updated_at)
VALUES ('labours.post.visible_statuses', '["APPROVED"]', 'Which labour listing statuses are visible to public', 'LABOURS', 'JSON', 'GLOBAL', true, true, false, '["APPROVED"]', 'system', 'system', NOW(), NOW())
ON CONFLICT (setting_key) DO NOTHING;

INSERT INTO settings (setting_key, setting_value, description, category, setting_type, scope, is_active, is_required, is_read_only, default_value, created_by, updated_by, created_at, updated_at)
VALUES ('labours.post.report_threshold', '3', 'Number of reports before auto-flagging a labour listing', 'LABOURS', 'INTEGER', 'GLOBAL', true, true, false, '3', 'system', 'system', NOW(), NOW())
ON CONFLICT (setting_key) DO NOTHING;
