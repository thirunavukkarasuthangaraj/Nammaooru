-- Create app_version table for managing mobile app versions
CREATE TABLE IF NOT EXISTS app_version (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    app_name VARCHAR(50) NOT NULL COMMENT 'CUSTOMER_APP, SHOP_OWNER_APP, DELIVERY_PARTNER_APP',
    platform VARCHAR(20) NOT NULL COMMENT 'ANDROID, IOS',
    current_version VARCHAR(20) NOT NULL COMMENT 'Latest version e.g., 1.0.0',
    minimum_version VARCHAR(20) NOT NULL COMMENT 'Minimum required version',
    update_url TEXT NOT NULL COMMENT 'Play Store / App Store URL',
    is_mandatory BOOLEAN DEFAULT FALSE COMMENT 'If true, force update',
    release_notes TEXT COMMENT 'What is new in this version',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY unique_app_platform (app_name, platform)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Insert initial version data for Customer App
INSERT INTO app_version (app_name, platform, current_version, minimum_version, update_url, is_mandatory, release_notes)
VALUES
('CUSTOMER_APP', 'ANDROID', '1.0.0', '1.0.0', 'https://play.google.com/store/apps/details?id=com.nammaooru.customer', FALSE, 'Initial release with ordering and tracking features'),
('CUSTOMER_APP', 'IOS', '1.0.0', '1.0.0', 'https://apps.apple.com/app/nammaooru-customer/id123456789', FALSE, 'Initial release with ordering and tracking features');

-- Insert initial version data for Shop Owner App

INSERT INTO app_version (app_name, platform, current_version, minimum_version, update_url, is_mandatory, release_notes)
VALUES
('SHOP_OWNER_APP', 'ANDROID', '1.0.0', '1.0.0', 'https://play.google.com/store/apps/details?id=com.nammaooru.shop_owner', FALSE, 'Initial release with shop management features'),
('SHOP_OWNER_APP', 'IOS', '1.0.0', '1.0.0', 'https://apps.apple.com/app/nammaooru-shop-owner/id123456789', FALSE, 'Initial release with shop management features');

-- Insert initial version data for Delivery Partner App
INSERT INTO app_version (app_name, platform, current_version, minimum_version, update_url, is_mandatory, release_notes)
VALUES
('DELIVERY_PARTNER_APP', 'ANDROID', '1.0.3', '1.0.0', 'https://play.google.com/store/apps/details?id=com.nammaooru.delivery_partner', FALSE, 'Enhanced location tracking and order management'),
('DELIVERY_PARTNER_APP', 'IOS', '1.0.3', '1.0.0', 'https://apps.apple.com/app/nammaooru-delivery-partner/id123456789', FALSE, 'Enhanced location tracking and order management');
