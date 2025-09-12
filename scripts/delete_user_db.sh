#!/bin/bash

# Database User Deletion Script (Excludes Super Admin)
# Usage: ./delete_user_db.sh <user_id> [db_password]

DB_HOST="localhost"
DB_PORT="5432"
DB_NAME="shop_management"
DB_USER="shop_user"
DB_PASSWORD=${2:-"shop_password"}
USER_ID=$1

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

# Check if user ID is provided
if [ -z "$USER_ID" ]; then
    print_error "User ID is required!"
    echo "Usage: $0 <user_id> [db_password]"
    echo "Example: $0 5"
    echo "Example: $0 5 mypassword"
    exit 1
fi

print_status "Starting database user deletion for User ID: $USER_ID"

# Set PostgreSQL password
export PGPASSWORD="$DB_PASSWORD"

# Step 1: Check if user exists and get details
print_status "Checking if user exists..."
USER_QUERY="SELECT id, username, email, role, status FROM users WHERE id = $USER_ID;"
USER_INFO=$(psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -t -c "$USER_QUERY" 2>/dev/null)

if [ $? -ne 0 ]; then
    print_error "Failed to connect to database"
    print_error "Check your database credentials and connection"
    exit 1
fi

if [ -z "$USER_INFO" ]; then
    print_error "User with ID $USER_ID not found in database"
    exit 1
fi

# Parse user information
USER_ROLE=$(echo "$USER_INFO" | awk -F'|' '{print $4}' | tr -d ' ')
USER_NAME=$(echo "$USER_INFO" | awk -F'|' '{print $2}' | tr -d ' ')
USER_EMAIL=$(echo "$USER_INFO" | awk -F'|' '{print $3}' | tr -d ' ')
USER_STATUS=$(echo "$USER_INFO" | awk -F'|' '{print $5}' | tr -d ' ')

print_status "Found user details:"
echo "  - ID: $USER_ID"
echo "  - Username: $USER_NAME"
echo "  - Email: $USER_EMAIL"
echo "  - Role: $USER_ROLE"
echo "  - Status: $USER_STATUS"

# Step 2: Check if user is SUPER_ADMIN
if [ "$USER_ROLE" == "SUPER_ADMIN" ]; then
    print_error "Cannot delete SUPER_ADMIN users!"
    print_warning "Super Admin users are protected from deletion"
    exit 1
fi

# Step 3: Show related data that will be affected
print_status "Checking related data..."

# Check shops owned by this user
SHOP_COUNT=$(psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -t -c "SELECT COUNT(*) FROM shops WHERE created_by = '$USER_NAME';" 2>/dev/null | tr -d ' ')
if [ "$SHOP_COUNT" -gt 0 ]; then
    print_warning "User owns $SHOP_COUNT shop(s) - these will become orphaned"
fi

# Check user permissions
PERM_COUNT=$(psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -t -c "SELECT COUNT(*) FROM user_permissions WHERE user_id = $USER_ID;" 2>/dev/null | tr -d ' ')
if [ "$PERM_COUNT" -gt 0 ]; then
    print_warning "User has $PERM_COUNT permission(s) - these will be deleted"
fi

# Step 4: Confirmation prompt
print_warning "Are you sure you want to delete this user from the database? (y/N)"
print_error "This action is IRREVERSIBLE!"
read -r CONFIRM

if [ "$CONFIRM" != "y" ] && [ "$CONFIRM" != "Y" ]; then
    print_status "User deletion cancelled"
    exit 0
fi

# Step 5: Begin deletion process
print_status "Starting deletion process..."

# Start transaction and delete related data first
print_status "Deleting user permissions..."
DELETE_PERMISSIONS="DELETE FROM user_permissions WHERE user_id = $USER_ID;"
psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -c "$DELETE_PERMISSIONS" >/dev/null 2>&1

# Update shops to remove owner reference (optional - you might want to keep this)
print_status "Updating owned shops..."
UPDATE_SHOPS="UPDATE shops SET created_by = 'DELETED_USER', updated_by = 'SYSTEM' WHERE created_by = '$USER_NAME';"
psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -c "$UPDATE_SHOPS" >/dev/null 2>&1

# Delete the user
print_status "Deleting user from database..."
DELETE_USER="DELETE FROM users WHERE id = $USER_ID AND role != 'SUPER_ADMIN';"
RESULT=$(psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -c "$DELETE_USER" 2>&1)

if [ $? -eq 0 ]; then
    # Check if any rows were affected
    if echo "$RESULT" | grep -q "DELETE 1"; then
        print_success "User deleted successfully from database!"
        print_status "Deleted user details:"
        echo "  - ID: $USER_ID"
        echo "  - Username: $USER_NAME"
        echo "  - Email: $USER_EMAIL"
        echo "  - Role: $USER_ROLE"
        if [ "$PERM_COUNT" -gt 0 ]; then
            echo "  - Removed $PERM_COUNT permission(s)"
        fi
        if [ "$SHOP_COUNT" -gt 0 ]; then
            echo "  - Updated $SHOP_COUNT owned shop(s)"
        fi
    else
        print_error "No user was deleted (user might not exist or is protected)"
    fi
else
    print_error "Failed to delete user"
    echo "$RESULT"
    exit 1
fi

print_success "Database user deletion process completed"