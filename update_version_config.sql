-- ====================================================================
-- UPDATE VERSION CONFIGURATION SCRIPT
-- Run this script to update the force update settings
-- ====================================================================

-- Option 1: Update to version 1.2.3 (matches what dialog showed)
UPDATE app_version
SET
    current_version = '1.2.3',
    minimum_version = '1.1.8',
    is_mandatory = true,
    release_notes = 'Version 1.2.3 Release:
• Fixed voice search ADD button issue
• Fixed false shop conflict detection
• Voice search now uses correct shopId
• Enhanced cart validation
• Bug fixes and performance improvements',
    updated_at = CURRENT_TIMESTAMP
WHERE app_name = 'CUSTOMER_APP' AND platform = 'ANDROID';

-- Option 2: Update to version 1.1.9 (as originally planned)
-- Uncomment below if you want to use 1.1.9 instead:
/*
UPDATE app_version
SET
    current_version = '1.1.9',
    minimum_version = '1.1.8',
    is_mandatory = true,
    release_notes = 'Version 1.1.9 Release:
• Fixed voice search ADD button issue
• Fixed false shop conflict detection
• Voice search now uses correct shopId
• Enhanced cart validation
• Bug fixes and performance improvements',
    updated_at = CURRENT_TIMESTAMP
WHERE app_name = 'CUSTOMER_APP' AND platform = 'ANDROID';
*/

-- Option 3: Disable force update (allow users to skip)
-- Uncomment below to make update optional:
/*
UPDATE app_version
SET
    is_mandatory = false,
    updated_at = CURRENT_TIMESTAMP
WHERE app_name = 'CUSTOMER_APP' AND platform = 'ANDROID';
*/

-- Option 4: Turn off update check (same version as current)
-- Uncomment below to stop showing update dialog:
/*
UPDATE app_version
SET
    current_version = '1.1.8',
    minimum_version = '1.1.8',
    is_mandatory = false,
    updated_at = CURRENT_TIMESTAMP
WHERE app_name = 'CUSTOMER_APP' AND platform = 'ANDROID';
*/

-- Verify the update
SELECT
    app_name,
    platform,
    current_version,
    minimum_version,
    is_mandatory,
    SUBSTRING(release_notes, 1, 100) as release_notes_preview,
    updated_at
FROM app_version
WHERE app_name = 'CUSTOMER_APP' AND platform = 'ANDROID';

COMMIT;
