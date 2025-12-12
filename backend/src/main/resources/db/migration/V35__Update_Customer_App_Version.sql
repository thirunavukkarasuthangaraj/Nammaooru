-- Update Customer App version to 1.1.4 with voice search and force update features
-- This migration updates the app version for production release

UPDATE app_version
SET
    current_version = '1.1.4',
    minimum_version = '1.0.0', -- Users on 1.0.0+ can still use the app (optional update)
    update_url = 'https://play.google.com/store/apps/details?id=com.nammaooru.app',
    is_mandatory = false, -- Set to true to force update
    release_notes = 'Version 1.1.4 Release Notes:
- Added voice search functionality for shop search
- Enhanced pincode field visibility in checkout
- Improved force update mechanism
- Bug fixes and performance improvements',
    updated_at = CURRENT_TIMESTAMP
WHERE app_name = 'CUSTOMER_APP' AND platform = 'ANDROID';

-- To enable FORCE UPDATE for old versions, run this query:
-- UPDATE app_version
-- SET
--     minimum_version = '1.1.4',  -- Require at least version 1.1.4
--     is_mandatory = true,         -- Force users to update
--     updated_at = CURRENT_TIMESTAMP
-- WHERE app_name = 'CUSTOMER_APP' AND platform = 'ANDROID';
