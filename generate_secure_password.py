#!/usr/bin/env python3
"""
Secure Password Hash Generator for Shop Management System
This tool generates BCrypt hashes compatible with your Spring Boot application.
"""

import bcrypt
import sys
import re

def validate_password(password):
    """Validate password strength."""
    if len(password) < 8:
        return False, "Password must be at least 8 characters long"
    
    # Check for at least one uppercase, one lowercase, and one number
    if not re.search(r'[A-Z]', password):
        return False, "Password must contain at least one uppercase letter"
    
    if not re.search(r'[a-z]', password):
        return False, "Password must contain at least one lowercase letter"
        
    if not re.search(r'\d', password):
        return False, "Password must contain at least one number"
    
    return True, "Password meets requirements"

def generate_bcrypt_hash(password):
    """Generate BCrypt hash using rounds=10 (Spring Boot default)."""
    # Convert password to bytes
    password_bytes = password.encode('utf-8')
    
    # Generate salt and hash with 10 rounds (Spring Boot default)
    salt = bcrypt.gensalt(rounds=10)
    hash_bytes = bcrypt.hashpw(password_bytes, salt)
    
    # Convert back to string
    return hash_bytes.decode('utf-8')

def main():
    print("=== Secure Password Hash Generator ===")
    print("Compatible with Spring Boot BCryptPasswordEncoder")
    print()
    
    if len(sys.argv) > 1:
        password = sys.argv[1]
    else:
        password = input("Enter password: ")
    
    # Validate password
    is_valid, message = validate_password(password)
    if not is_valid:
        print(f"❌ {message}")
        return
    
    print(f"✅ {message}")
    print()
    
    try:
        # Generate hash
        hash_value = generate_bcrypt_hash(password)
        
        print("📋 Results:")
        print(f"Password: {password}")
        print(f"BCrypt Hash: {hash_value}")
        print()
        print("📝 SQL Command:")
        print(f"UPDATE users SET password = '{hash_value}' WHERE username = 'your_username';")
        print()
        print("✅ Hash generated successfully!")
        print("This hash is compatible with your Spring Boot BCryptPasswordEncoder.")
        
    except Exception as e:
        print(f"❌ Error generating hash: {e}")

if __name__ == "__main__":
    main()