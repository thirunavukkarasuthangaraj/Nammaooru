-- Create app_version table for managing mobile app versions
CREATE TABLE IF NOT EXISTS app_version (
    id BIGSERIAL PRIMARY KEY,
    app_name VARCHAR(50) NOT NULL, -- 'CUSTOMER_APP', 'SHOP_OWNER_APP', 'DELIVERY_PARTNER_APP'
    platform VARCHAR(20) NOT NULL, -- 'ANDROID', 'IOS'
    current_version VARCHAR(20) NOT NULL, -- e.g., '1.0.0'
    minimum_version VARCHAR(20) NOT NULL, -- Minimum required version
    update_url TEXT NOT NULL, -- Play Store / App Store URL
    is_mandatory BOOLEAN DEFAULT false, -- If true, force update
    release_notes TEXT, -- What's new in this version
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(app_name, platform)
);

-- Insert initial versions for all apps
INSERT INTO app_version (app_name, platform, current_version, minimum_version, update_url, is_mandatory, release_notes) VALUES
('CUSTOMER_APP', 'ANDROID', '1.0.0', '1.0.0', 'https://play.google.com/store/apps/details?id=com.nammaooru.app', false, 'Initial release with shop browsing, cart, checkout, and order tracking'),
('SHOP_OWNER_APP', 'ANDROID', '1.0.0', '1.0.0', 'https://play.google.com/store/apps/details?id=com.nammaooru.shop_owner_app', false, 'Initial release with order management, inventory, and analytics'),
('DELIVERY_PARTNER_APP', 'ANDROID', '1.0.0', '1.0.0', 'https://play.google.com/store/apps/details?id=com.nammaooru.delivery_partner', false, 'Initial release with order assignment, navigation, and delivery completion');

-- Create index for faster lookups
CREATE INDEX idx_app_version_lookup ON app_version(app_name, platform);
