#!/usr/bin/env python3
"""
PostgreSQL SQL Executor to Update Thiruna User Role
This script connects to PostgreSQL and updates thiruna user to SUPER_ADMIN role
"""

import psycopg2
import sys

def update_thiruna_role():
    # Database connection parameters
    connection_params = {
        'host': 'localhost',
        'port': 5432,
        'database': 'shop_management_db',
        'user': 'postgres',
        'password': 'postgres'
    }
    
    # SQL to update thiruna user role
    update_sql = """
    UPDATE users 
    SET 
        role = 'SUPER_ADMIN',
        status = 'ACTIVE',
        is_active = true,
        email_verified = true,
        updated_at = NOW(),
        updated_by = 'system'
    WHERE email = 'thiruna2394@gmail.com' OR username = 'thiruna';
    """
    
    verify_sql = """
    SELECT id, username, email, role, status, is_active, email_verified, created_at, updated_at
    FROM users WHERE email = 'thiruna2394@gmail.com' OR username = 'thiruna';
    """
    
    try:
        # Connect to PostgreSQL
        print("Connecting to PostgreSQL database...")
        conn = psycopg2.connect(**connection_params)
        cursor = conn.cursor()
        
        # Execute the update script
        print("Updating thiruna user role to SUPER_ADMIN...")
        cursor.execute(update_sql)
        rows_affected = cursor.rowcount
        conn.commit()
        
        print(f"Rows updated: {rows_affected}")
        
        # Verify the result
        print("Verifying thiruna user...")
        cursor.execute(verify_sql)
        result = cursor.fetchone()
        
        if result:
            print("\n✅ SUCCESS! Thiruna user details:")
            print(f"ID: {result[0]}")
            print(f"Username: {result[1]}")
            print(f"Email: {result[2]}")
            print(f"Role: {result[3]}")
            print(f"Status: {result[4]}")
            print(f"Active: {result[5]}")
            print(f"Email Verified: {result[6]}")
            print(f"Created: {result[7]}")
            print(f"Updated: {result[8]}")
            print("\n🔐 Login Credentials:")
            print("Email: thiruna2394@gmail.com")
            print("Role: SUPER_ADMIN")
        else:
            print("❌ ERROR: Thiruna user not found")
            
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
    success = update_thiruna_role()
    sys.exit(0 if success else 1)