-- ====================================================================
-- FORCE UPDATE SETUP SCRIPT FOR CUSTOMER APP
-- Run this script in your PostgreSQL database (shop_management_db)
-- ====================================================================

-- Step 1: Create table if it doesn't exist
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

-- Step 2: Insert or Update the version data
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
    '1.1.9',              -- Latest version available (FOR TESTING)
    '1.1.8',              -- Minimum required version (users < 1.1.8 must update)
    'https://play.google.com/store/apps/details?id=com.nammaooru.app',
    true,                 -- MANDATORY - users cannot skip this update
    'Version 1.1.9 Release:
• Fixed voice search ADD button issue
• Fixed false shop conflict detection
• Voice search now uses correct shopId
• Enhanced cart validation
• Bug fixes and performance improvements',
    CURRENT_TIMESTAMP,
    CURRENT_TIMESTAMP
)
ON CONFLICT (app_name, platform)
DO UPDATE SET
    current_version = '1.1.9',
    minimum_version = '1.1.8',
    update_url = 'https://play.google.com/store/apps/details?id=com.nammaooru.app',
    is_mandatory = true,
    release_notes = 'Version 1.1.9 Release:
• Fixed voice search ADD button issue
• Fixed false shop conflict detection
• Voice search now uses correct shopId
• Enhanced cart validation
• Bug fixes and performance improvements',
    updated_at = CURRENT_TIMESTAMP;

-- Step 3: Verify the data was inserted
SELECT
    app_name,
    platform,
    current_version,
    minimum_version,
    is_mandatory,
    SUBSTRING(release_notes, 1, 50) as release_notes_preview,
    updated_at
FROM app_version
WHERE app_name = 'CUSTOMER_APP' AND platform = 'ANDROID';

-- Step 4: Create index if it doesn't exist
CREATE INDEX IF NOT EXISTS idx_app_version_lookup ON app_version(app_name, platform);

COMMIT;
