-- ==========================================================
-- Force Update Script for NammaOoru App
-- ==========================================================
-- Run on PostgreSQL: psql -U shopuser -d shopmanagement -f force_update_app_version.sql
-- Or via SSH: ssh thiru@65.21.4.236 then docker exec -i shop-postgres psql -U shopuser -d shopmanagement
--
-- How it works:
--   current_version  = Latest version (show "update available")
--   minimum_version  = Anything below this = BLOCKED until updated
--   is_mandatory     = true = force update dialog, can't skip

-- Step 1: Check what exists
SELECT id, app_name, platform, current_version, minimum_version, is_mandatory FROM app_version;

-- Step 2: Update if record exists, else insert
-- ANDROID CUSTOMER_APP
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM app_version WHERE app_name = 'CUSTOMER_APP' AND platform = 'ANDROID') THEN
        UPDATE app_version
        SET current_version = '1.2.28',
            minimum_version = '1.2.28',
            is_mandatory = true,
            update_url = 'https://play.google.com/store/apps/details?id=com.nammaooru.app',
            release_notes = 'Edit/Delete for all posts, image upload fix',
            updated_at = NOW()
        WHERE app_name = 'CUSTOMER_APP' AND platform = 'ANDROID';
        RAISE NOTICE 'UPDATED existing CUSTOMER_APP ANDROID record';
    ELSE
        INSERT INTO app_version (app_name, platform, current_version, minimum_version, update_url, is_mandatory, release_notes, created_at, updated_at)
        VALUES ('CUSTOMER_APP', 'ANDROID', '1.2.28', '1.2.28',
                'https://play.google.com/store/apps/details?id=com.nammaooru.app',
                true, 'Edit/Delete for all posts, image upload fix',
                NOW(), NOW());
        RAISE NOTICE 'INSERTED new CUSTOMER_APP ANDROID record';
    END IF;
END $$;

-- Step 3: Verify
SELECT id, app_name, platform, current_version, minimum_version, is_mandatory, release_notes, updated_at
FROM app_version;
