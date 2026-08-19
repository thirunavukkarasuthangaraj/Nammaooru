-- Mandatory update setup for the customer Android app.
-- Run against the shop_management_db PostgreSQL database after the new
-- version is available in Google Play.

CREATE TABLE IF NOT EXISTS app_version (
    id BIGSERIAL PRIMARY KEY,
    app_name VARCHAR(50) NOT NULL,
    platform VARCHAR(20) NOT NULL,
    current_version VARCHAR(20) NOT NULL,
    minimum_version VARCHAR(20) NOT NULL,
    update_url TEXT NOT NULL,
    is_mandatory BOOLEAN DEFAULT false,
    release_notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(app_name, platform)
);

INSERT INTO app_version (
    app_name,
    platform,
    current_version,
    minimum_version,
    update_url,
    is_mandatory,
    release_notes,
    created_at,
    updated_at
)
VALUES (
    'CUSTOMER_APP',
    'ANDROID',
    '1.2.56',
    '1.2.54',
    'https://play.google.com/store/apps/details?id=com.nammaooru.app',
    false,
    'Version 1.2.56: Bug fixes and performance improvements.',
    CURRENT_TIMESTAMP,
    CURRENT_TIMESTAMP
)
ON CONFLICT (app_name, platform)
DO UPDATE SET
    current_version = EXCLUDED.current_version,
    minimum_version = EXCLUDED.minimum_version,
    update_url = EXCLUDED.update_url,
    is_mandatory = EXCLUDED.is_mandatory,
    release_notes = EXCLUDED.release_notes,
    updated_at = CURRENT_TIMESTAMP;

CREATE INDEX IF NOT EXISTS idx_app_version_lookup
    ON app_version(app_name, platform);

SELECT
    app_name,
    platform,
    current_version,
    minimum_version,
    is_mandatory,
    update_url,
    updated_at
FROM app_version
WHERE app_name = 'CUSTOMER_APP' AND platform = 'ANDROID';

COMMIT;
