-- User Deletion SQL Script (Excludes Super Admin)
-- Usage: Replace @USER_ID with the actual user ID to delete
-- Example: \set user_id 5
-- Then run: \i delete_user.sql

\set user_id 'REPLACE_WITH_USER_ID'

-- Step 1: Show user details before deletion
\echo '=== USER DELETION SCRIPT ==='
\echo 'Checking user details...'

SELECT 
    id,
    username,
    email,
    role,
    status,
    created_at
FROM users 
WHERE id = :user_id;

-- Step 2: Check if user is SUPER_ADMIN (safety check)
\echo 'Checking if user is SUPER_ADMIN...'

SELECT 
    CASE 
        WHEN role = 'SUPER_ADMIN' THEN 'ERROR: Cannot delete SUPER_ADMIN user!'
        ELSE 'OK: User can be deleted'
    END as deletion_status
FROM users 
WHERE id = :user_id;

-- Step 3: Show related data that will be affected
\echo 'Checking related data...'

\echo 'Shops owned by this user:'
SELECT id, name, created_by 
FROM shops 
WHERE created_by = (SELECT username FROM users WHERE id = :user_id);

\echo 'User permissions:'
SELECT COUNT(*) as permission_count 
FROM user_permissions 
WHERE user_id = :user_id;

-- Step 4: Delete user permissions first (foreign key constraint)
\echo 'Deleting user permissions...'
DELETE FROM user_permissions WHERE user_id = :user_id;

-- Step 5: Update shops to remove owner reference (optional)
\echo 'Updating owned shops...'
UPDATE shops 
SET 
    created_by = 'DELETED_USER',
    updated_by = 'SYSTEM',
    updated_at = CURRENT_TIMESTAMP
WHERE created_by = (SELECT username FROM users WHERE id = :user_id);

-- Step 6: Delete the user (with SUPER_ADMIN protection)
\echo 'Deleting user...'
DELETE FROM users 
WHERE id = :user_id 
  AND role != 'SUPER_ADMIN';

-- Step 7: Confirm deletion
\echo 'Checking deletion result...'
SELECT 
    CASE 
        WHEN COUNT(*) = 0 THEN 'SUCCESS: User deleted successfully'
        ELSE 'WARNING: User still exists (might be SUPER_ADMIN or deletion failed)'
    END as result
FROM users 
WHERE id = :user_id;

\echo '=== DELETION SCRIPT COMPLETED ==='