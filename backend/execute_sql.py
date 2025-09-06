#!/usr/bin/env python3
"""
PostgreSQL SQL Executor for Superadmin Insert
This script connects to PostgreSQL and executes the superadmin insert/update SQL
"""

import psycopg2
import sys

def execute_superadmin_sql():
    # Database connection parameters
    connection_params = {
        'host': 'localhost',
        'port': 5432,
        'database': 'shop_management_db',
        'user': 'postgres',
        'password': 'postgres'
    }
    
    # SQL to execute
    sql_script = """
    -- Superadmin Insert/Update Script
    DO $$
    BEGIN
        -- Check if superadmin user exists
        IF EXISTS (SELECT 1 FROM users WHERE username = 'superadmin') THEN
            -- Update existing superadmin user
            UPDATE users 
            SET 
                email = 'superadmin@shopmanagement.com',
                password = '$2a$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi',
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
                username, email, password, first_name, last_name, mobile_number,
                role, status, is_active, email_verified, mobile_verified, 
                two_factor_enabled, is_temporary_password, password_change_required, 
                failed_login_attempts, created_at, updated_at, created_by, updated_by
            ) VALUES (
                'superadmin', 'superadmin@shopmanagement.com',
                '$2a$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi',
                'Super', 'Admin', '9999999999', 'SUPER_ADMIN', 'ACTIVE',
                true, true, false, false, false, false, 0,
                NOW(), NOW(), 'system', 'system'
            );
            
            RAISE NOTICE 'Superadmin user created successfully';
        END IF;
    END $$;
    """
    
    verify_sql = """
    SELECT id, username, email, first_name, last_name, role, status, is_active, email_verified
    FROM users WHERE username = 'superadmin';
    """
    
    try:
        # Connect to PostgreSQL
        print("Connecting to PostgreSQL database...")
        conn = psycopg2.connect(**connection_params)
        cursor = conn.cursor()
        
        # Execute the insert/update script
        print("Executing superadmin insert/update script...")
        cursor.execute(sql_script)
        conn.commit()
        
        # Verify the result
        print("Verifying superadmin user...")
        cursor.execute(verify_sql)
        result = cursor.fetchone()
        
        if result:
            print("\n✅ SUCCESS! Superadmin user details:")
            print(f"ID: {result[0]}")
            print(f"Username: {result[1]}")
            print(f"Email: {result[2]}")
            print(f"Name: {result[3]} {result[4]}")
            print(f"Role: {result[5]}")
            print(f"Status: {result[6]}")
            print(f"Active: {result[7]}")
            print(f"Email Verified: {result[8]}")
            print("\n🔐 Login Credentials:")
            print("Email: superadmin@shopmanagement.com")
            print("Password: password")
        else:
            print("❌ ERROR: Superadmin user not found after execution")
            
        cursor.close()
        conn.close()
        return True
        
    except psycopg2.Error as e:
        print(f"❌ PostgreSQL Error: {e}")
        return False
    except Exception as e:
        print(f"❌ General Error: {e}")
        return False

if __name__ == "__main__":
    success = execute_superadmin_sql()
    sys.exit(0 if success else 1)