-- Create Super Admin SQL Script
-- Usage: Replace variables and run with: psql -d shop_management -f create_super_admin.sql
-- Or set variables: \set username 'myuser' \set email 'my@email.com' \set password 'mypass'

\set username 'superadmin'
\set email 'superadmin@nammaooru.com'  
\set password 'Super@123'

-- Step 1: Check if user already exists
\echo '=== SUPER ADMIN CREATION SCRIPT ==='
\echo 'Checking if user already exists...'

SELECT 
    CASE 
        WHEN COUNT(*) > 0 THEN 'WARNING: User already exists with this username or email!'
        ELSE 'OK: Username and email are available'
    END as check_result,
    COUNT(*) as existing_users
FROM users 
WHERE username = :'username' OR email = :'email';

-- Show existing user details if any
\echo 'Existing user details:'
SELECT id, username, email, role, status, created_at 
FROM users 
WHERE username = :'username' OR email = :'email';

-- Step 2: Insert Super Admin (will fail if user exists due to unique constraints)
\echo 'Creating Super Admin user...'
\echo 'Username:' :'username'
\echo 'Email:' :'email' 
\echo 'Password:' :'password'

INSERT INTO users (
    username,
    email,
    password,
    first_name,
    last_name,
    role,
    status,
    is_active,
    email_verified,
    mobile_verified,
    password_change_required,
    failed_login_attempts,
    two_factor_enabled,
    created_at,
    updated_at,
    created_by,
    updated_by
) VALUES (
    :'username',
    :'email',
    '$2a$10$' || encode(digest(:'password', 'sha256'), 'hex'), -- Simple hash (replace with proper bcrypt)
    'Super',
    'Admin', 
    'SUPER_ADMIN',
    'ACTIVE',
    true,
    true,
    false,
    false,
    0,
    false,
    CURRENT_TIMESTAMP,
    CURRENT_TIMESTAMP,
    'SYSTEM',
    'SYSTEM'
)
ON CONFLICT (username) 
DO UPDATE SET 
    role = 'SUPER_ADMIN',
    password = '$2a$10$' || encode(digest(:'password', 'sha256'), 'hex'),
    status = 'ACTIVE',
    is_active = true,
    email_verified = true,
    updated_at = CURRENT_TIMESTAMP,
    updated_by = 'SYSTEM'
WHERE users.username = :'username';

-- Alternative for email conflict
INSERT INTO users (
    username,
    email,
    password,
    first_name,
    last_name,
    role,
    status,
    is_active,
    email_verified,
    mobile_verified,
    password_change_required,
    failed_login_attempts,
    two_factor_enabled,
    created_at,
    updated_at,
    created_by,
    updated_by
) VALUES (
    :'username',
    :'email',
    '$2a$10$' || encode(digest(:'password', 'sha256'), 'hex'),
    'Super',
    'Admin',
    'SUPER_ADMIN', 
    'ACTIVE',
    true,
    true,
    false,
    false,
    0,
    false,
    CURRENT_TIMESTAMP,
    CURRENT_TIMESTAMP,
    'SYSTEM',
    'SYSTEM'
)
ON CONFLICT (email)
DO UPDATE SET
    role = 'SUPER_ADMIN',
    password = '$2a$10$' || encode(digest(:'password', 'sha256'), 'hex'),
    status = 'ACTIVE', 
    is_active = true,
    email_verified = true,
    updated_at = CURRENT_TIMESTAMP,
    updated_by = 'SYSTEM'
WHERE users.email = :'email';

-- Step 3: Show final user details
\echo 'Super Admin user created/updated successfully!'
\echo 'Final user details:'

SELECT 
    id,
    username,
    email,
    first_name,
    last_name,
    role,
    status,
    is_active,
    email_verified,
    created_at,
    updated_at
FROM users 
WHERE username = :'username' OR email = :'email';

-- Step 4: Show login credentials
\echo '=== LOGIN CREDENTIALS ==='
SELECT 
    'Username: ' || username as login_username,
    'Email: ' || email as login_email,
    'Password: ' || :'password' as login_password,
    'Role: ' || role as user_role
FROM users 
WHERE username = :'username' OR email = :'email';

\echo '=== SUPER ADMIN CREATION COMPLETED ==='
\echo 'IMPORTANT: Please change the password after first login!'