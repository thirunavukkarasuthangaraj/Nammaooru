# Password Hash Generator

This tool generates BCrypt password hashes that are 100% compatible with your Spring Boot application.

## Why Use This Tool?

- ✅ **100% Compatible**: Uses the exact same BCryptPasswordEncoder as your production system
- ✅ **Handles Special Characters**: Works with any password pattern including @, #, $, etc.
- ✅ **Secure**: Uses BCrypt with 10 rounds (Spring Boot default)
- ✅ **Easy to Use**: Simple command-line interface

## Usage

### Method 1: Windows Batch Script (Easiest)
```bash
# Run the batch file
generate-password-hash.bat

# Or pass password as argument
generate-password-hash.bat "MySecurePass@123"
```

### Method 2: Maven Command
```bash
# Navigate to backend directory
cd backend

# Generate hash for any password
mvn exec:java -Dexec.mainClass="com.shopmanagement.util.PasswordHashGenerator" -Dexec.args="YourPasswordHere"
```

### Method 3: Edit the Java File
1. Open `backend/src/main/java/com/shopmanagement/util/PasswordHashGenerator.java`
2. Change the default password on line 10
3. Run: `mvn exec:java -Dexec.mainClass="com.shopmanagement.util.PasswordHashGenerator"`

## Example Output

```
=== Secure Password Hash Generator ===
Compatible with Spring Boot BCryptPasswordEncoder

📋 Results:
Password: nammaooru@2025
BCrypt Hash: $2a$10$FXwpqC4yds1OKbZz.v2vCeQQe8Dzm7zDMlpreo1lbPRvNxbho2yCW

📝 SQL Commands:
UPDATE users SET password = '$2a$10$FXwpqC4yds1OKbZz.v2vCeQQe8Dzm7zDMlpreo1lbPRvNxbho2yCW' WHERE username = 'superadmin';
UPDATE users SET password = '$2a$10$FXwpqC4yds1OKbZz.v2vCeQQe8Dzm7zDMlpreo1lbPRvNxbho2yCW' WHERE username = 'admin';

✅ Hash generated successfully!
This hash is 100% compatible with your production system.
```

## Password Requirements

- Minimum 8 characters
- Can contain any characters including special symbols (@, #, $, %, etc.)
- Recommended: Mix of uppercase, lowercase, numbers, and symbols

## Troubleshooting

**Q: Why don't manually generated BCrypt hashes work?**
A: Different BCrypt implementations use different settings. This tool uses the exact same BCryptPasswordEncoder configuration as your Spring Boot application.

**Q: Can I use this for any user?**
A: Yes! Just change the username in the generated SQL command from 'superadmin' to any username you want.

**Q: Is this secure?**
A: Yes! BCrypt with 10 rounds is industry standard. Each password gets a unique salt, so identical passwords will have different hashes.