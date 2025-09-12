#!/bin/bash

# Create Super Admin Script
# Usage: ./create_super_admin.sh [username] [email] [password] [db_password]

DB_HOST="localhost"
DB_PORT="5432"
DB_NAME="shop_management"
DB_USER="shop_user"
DB_PASSWORD=${4:-"shop_password"}

# Default super admin details
ADMIN_USERNAME=${1:-"superadmin"}
ADMIN_EMAIL=${2:-"superadmin@nammaooru.com"}
ADMIN_PASSWORD=${3:-"Super@123"}

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_status "Creating Super Admin user..."
echo "Details:"
echo "  - Username: $ADMIN_USERNAME"
echo "  - Email: $ADMIN_EMAIL" 
echo "  - Password: $ADMIN_PASSWORD"
echo "  - Role: SUPER_ADMIN"

# Set PostgreSQL password
export PGPASSWORD="$DB_PASSWORD"

# Step 1: Check if user already exists
print_status "Checking if user already exists..."
EXISTING_USER=$(psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -t -c "SELECT COUNT(*) FROM users WHERE username = '$ADMIN_USERNAME' OR email = '$ADMIN_EMAIL';" 2>/dev/null | tr -d ' ')

if [ $? -ne 0 ]; then
    print_error "Failed to connect to database"
    print_error "Check your database credentials and connection"
    exit 1
fi

if [ "$EXISTING_USER" -gt 0 ]; then
    print_warning "User with username '$ADMIN_USERNAME' or email '$ADMIN_EMAIL' already exists!"
    
    # Show existing user details
    print_status "Existing user details:"
    psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -c "SELECT id, username, email, role, status FROM users WHERE username = '$ADMIN_USERNAME' OR email = '$ADMIN_EMAIL';"
    
    print_warning "Do you want to update the existing user to SUPER_ADMIN? (y/N)"
    read -r CONFIRM
    
    if [ "$CONFIRM" = "y" ] || [ "$CONFIRM" = "Y" ]; then
        print_status "Updating existing user to SUPER_ADMIN..."
        UPDATE_QUERY="UPDATE users SET 
            role = 'SUPER_ADMIN',
            password = '\$2a\$10\$' || encode(digest('$ADMIN_PASSWORD', 'sha256'), 'hex'),
            status = 'ACTIVE',
            is_active = true,
            email_verified = true,
            password_change_required = false,
            failed_login_attempts = 0,
            account_locked_until = NULL,
            updated_at = CURRENT_TIMESTAMP,
            updated_by = 'SYSTEM'
        WHERE username = '$ADMIN_USERNAME' OR email = '$ADMIN_EMAIL';"
        
        RESULT=$(psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -c "$UPDATE_QUERY" 2>&1)
        
        if [ $? -eq 0 ]; then
            print_success "User updated to SUPER_ADMIN successfully!"
        else
            print_error "Failed to update user"
            echo "$RESULT"
            exit 1
        fi
    else
        print_status "Operation cancelled"
        exit 0
    fi
else
    # Step 2: Create new super admin user
    print_status "Creating new Super Admin user..."
    
    INSERT_QUERY="INSERT INTO users (
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
        '$ADMIN_USERNAME',
        '$ADMIN_EMAIL',
        '\$2a\$10\$' || encode(digest('$ADMIN_PASSWORD', 'sha256'), 'hex'),
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
    );"
    
    RESULT=$(psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -c "$INSERT_QUERY" 2>&1)
    
    if [ $? -eq 0 ]; then
        if echo "$RESULT" | grep -q "INSERT 0 1"; then
            print_success "Super Admin user created successfully!"
        else
            print_error "Failed to create user"
            echo "$RESULT"
            exit 1
        fi
    else
        print_error "Failed to create user"
        echo "$RESULT"
        exit 1
    fi
fi

# Step 3: Show created/updated user details
print_status "Final user details:"
psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -c "
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
        created_at
    FROM users 
    WHERE username = '$ADMIN_USERNAME' OR email = '$ADMIN_EMAIL';"

print_success "Super Admin setup completed!"
print_warning "Login credentials:"
echo "  - Username: $ADMIN_USERNAME"
echo "  - Email: $ADMIN_EMAIL"
echo "  - Password: $ADMIN_PASSWORD"
print_warning "Please change the password after first login for security!"