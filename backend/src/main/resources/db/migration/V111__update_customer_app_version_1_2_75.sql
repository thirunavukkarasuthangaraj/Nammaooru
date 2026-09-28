-- Update Customer App version to 1.2.75 (build 112) - optional update, does
-- not touch minimum_version so it stays whatever it already was.
UPDATE app_version
SET
    current_version = '1.2.75',
    is_mandatory = false,
    release_notes = 'Version 1.2.75 Release Notes:
- Clearer checkout error messages (e.g. out-of-stock now says exactly which product and why)
- Village/town name search now works when adding a delivery address
- Redesigned shop home screen with category browsing
- Minor bug fixes and UI polish',
    updated_at = CURRENT_TIMESTAMP
WHERE app_name = 'CUSTOMER_APP' AND platform = 'ANDROID';
