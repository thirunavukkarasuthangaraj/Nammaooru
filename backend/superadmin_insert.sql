-- Superadmin Insert/Update Script for PostgreSQL
-- Database: shop_management_db
-- This script will insert or update the superadmin user

-- First, let's see if superadmin exists
DO $$
BEGIN
    -- Check if superadmin user exists
    IF EXISTS (SELECT 1 FROM users WHERE username = 'superadmin') THEN
        -- Update existing superadmin user
        UPDATE users 
        SET 
            email = 'superadmin@shopmanagement.com',
            password = '$2a$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', -- BCrypt hash for "password"
            first_name = 'Super',
            last_name = 'Admin',
            role = 'SUPER_ADMIN',
            status = 'ACTIVE',
            is_active = true,
            email_verified = true,
            mobile_verified = false,
            two_factor_enabled = false,
            is_temporary_password = false,
            password_change_required = false,
            failed_login_attempts = 0,
            updated_at = NOW(),
            updated_by = 'system'
        WHERE username = 'superadmin';
        
        RAISE NOTICE 'Superadmin user updated successfully';
    ELSE
        -- Insert new superadmin user
        INSERT INTO users (
            username, 
            email, 
            password, 
            first_name, 
            last_name, 
            mobile_number,
            role, 
            status, 
            is_active, 
            email_verified, 
            mobile_verified, 
            two_factor_enabled, 
            is_temporary_password, 
            password_change_required, 
            failed_login_attempts, 
            created_at, 
            updated_at, 
            created_by,
            updated_by
        ) VALUES (
            'superadmin',
            'superadmin@shopmanagement.com',
            '$2a$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', -- BCrypt hash for "password"
            'Super',
            'Admin',
            '9999999999',
            'SUPER_ADMIN',
            'ACTIVE',
            true,
            true,
            false,
            false,
            false,
            false,
            0,
            NOW(),
            NOW(),
            'system',
            'system'
        );
        
        RAISE NOTICE 'Superadmin user created successfully';
    END IF;
END $$;

-- Verify the superadmin user
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
WHERE username = 'superadmin';