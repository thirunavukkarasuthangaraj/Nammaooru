-- Create settings table if it doesn't exist (normally auto-created by Hibernate)
CREATE TABLE IF NOT EXISTS settings (
    id BIGSERIAL PRIMARY KEY,
    setting_key VARCHAR(100) NOT NULL UNIQUE,
    setting_value TEXT NOT NULL,
    description VARCHAR(200),
    category VARCHAR(50),
    setting_type VARCHAR(20) NOT NULL,
    scope VARCHAR(20) NOT NULL,
    shop_id BIGINT,
    user_id BIGINT,
    is_active BOOLEAN DEFAULT TRUE,
    is_required BOOLEAN DEFAULT FALSE,
    is_read_only BOOLEAN DEFAULT FALSE,
    default_value TEXT,
    validation_rules TEXT,
    display_order INTEGER,
    created_at TIMESTAMP,
    updated_at TIMESTAMP,
    created_by VARCHAR(100),
    updated_by VARCHAR(100)
);

-- Insert default marketplace settings
INSERT INTO settings (setting_key, setting_value, description, category, setting_type, scope, is_active, is_required, is_read_only, default_value, created_by, updated_by, created_at, updated_at)
VALUES ('marketplace.post.duration_days', '30', 'How many days a post stays visible (0 = no expiry)', 'MARKETPLACE', 'INTEGER', 'GLOBAL', true, true, false, '30', 'system', 'system', NOW(), NOW())
ON CONFLICT (setting_key) DO NOTHING;

INSERT INTO settings (setting_key, setting_value, description, category, setting_type, scope, is_active, is_required, is_read_only, default_value, created_by, updated_by, created_at, updated_at)
VALUES ('marketplace.post.auto_approve', 'false', 'Auto-approve new marketplace posts (skip pending approval)', 'MARKETPLACE', 'BOOLEAN', 'GLOBAL', true, true, false, 'false', 'system', 'system', NOW(), NOW())
ON CONFLICT (setting_key) DO NOTHING;

INSERT INTO settings (setting_key, setting_value, description, category, setting_type, scope, is_active, is_required, is_read_only, default_value, created_by, updated_by, created_at, updated_at)
VALUES ('marketplace.post.visible_statuses', '["APPROVED"]', 'Which post statuses are visible to the public', 'MARKETPLACE', 'JSON', 'GLOBAL', true, true, false, '["APPROVED"]', 'system', 'system', NOW(), NOW())
ON CONFLICT (setting_key) DO NOTHING;

INSERT INTO settings (setting_key, setting_value, description, category, setting_type, scope, is_active, is_required, is_read_only, default_value, created_by, updated_by, created_at, updated_at)
VALUES ('marketplace.post.report_threshold', '3', 'Number of reports needed before auto-flagging a post', 'MARKETPLACE', 'INTEGER', 'GLOBAL', true, true, false, '3', 'system', 'system', NOW(), NOW())
ON CONFLICT (setting_key) DO NOTHING;

-- Insert default farmer products settings
INSERT INTO settings (setting_key, setting_value, description, category, setting_type, scope, is_active, is_required, is_read_only, default_value, created_by, updated_by, created_at, updated_at)
VALUES ('farmer_products.post.duration_days', '30', 'How many days a farmer product post stays visible (0 = no expiry)', 'FARMER_PRODUCTS', 'INTEGER', 'GLOBAL', true, true, false, '30', 'system', 'system', NOW(), NOW())
ON CONFLICT (setting_key) DO NOTHING;

INSERT INTO settings (setting_key, setting_value, description, category, setting_type, scope, is_active, is_required, is_read_only, default_value, created_by, updated_by, created_at, updated_at)
VALUES ('farmer_products.post.auto_approve', 'false', 'Auto-approve new farmer product posts (skip pending approval)', 'FARMER_PRODUCTS', 'BOOLEAN', 'GLOBAL', true, true, false, 'false', 'system', 'system', NOW(), NOW())
ON CONFLICT (setting_key) DO NOTHING;

INSERT INTO settings (setting_key, setting_value, description, category, setting_type, scope, is_active, is_required, is_read_only, default_value, created_by, updated_by, created_at, updated_at)
VALUES ('farmer_products.post.visible_statuses', '["APPROVED"]', 'Which farmer product post statuses are visible to the public', 'FARMER_PRODUCTS', 'JSON', 'GLOBAL', true, true, false, '["APPROVED"]', 'system', 'system', NOW(), NOW())
ON CONFLICT (setting_key) DO NOTHING;

INSERT INTO settings (setting_key, setting_value, description, category, setting_type, scope, is_active, is_required, is_read_only, default_value, created_by, updated_by, created_at, updated_at)
VALUES ('farmer_products.post.report_threshold', '3', 'Number of reports needed before auto-flagging a farmer product post', 'FARMER_PRODUCTS', 'INTEGER', 'GLOBAL', true, true, false, '3', 'system', 'system', NOW(), NOW())
ON CONFLICT (setting_key) DO NOTHING;
