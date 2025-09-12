#!/bin/bash

# User Deletion Script (Excludes Super Admin)
# Usage: ./delete_user.sh <user_id> [admin_email] [admin_password]

API_URL="http://localhost:8082"
USER_ID=$1
ADMIN_EMAIL=${2:-"admin@example.com"}
ADMIN_PASSWORD=${3:-"admin123"}

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
    echo "Usage: $0 <user_id> [admin_email] [admin_password]"
    echo "Example: $0 5"
    echo "Example: $0 5 admin@example.com admin123"
    exit 1
fi

print_status "Starting user deletion process for User ID: $USER_ID"

# Step 1: Login as admin to get JWT token
print_status "Authenticating as admin..."
AUTH_RESPONSE=$(curl -s -X POST "$API_URL/api/auth/login" \
  -H "Content-Type: application/json" \
  -d "{
    \"email\": \"$ADMIN_EMAIL\",
    \"password\": \"$ADMIN_PASSWORD\"
  }")

# Check if login was successful
if [ $? -ne 0 ]; then
    print_error "Failed to connect to API"
    exit 1
fi

# Extract token from response
TOKEN=$(echo "$AUTH_RESPONSE" | grep -o '"token":"[^"]*' | cut -d'"' -f4)

if [ -z "$TOKEN" ]; then
    print_error "Authentication failed. Check admin credentials."
    echo "Response: $AUTH_RESPONSE"
    exit 1
fi

print_success "Authentication successful"

# Step 2: Get user details first
print_status "Fetching user details for ID: $USER_ID"
USER_RESPONSE=$(curl -s -X GET "$API_URL/api/users/$USER_ID" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json")

if [ $? -ne 0 ]; then
    print_error "Failed to fetch user details"
    exit 1
fi

# Check if user exists
if echo "$USER_RESPONSE" | grep -q '"statusCode":"USER_NOT_FOUND"'; then
    print_error "User with ID $USER_ID not found"
    exit 1
fi

# Extract user role from response
USER_ROLE=$(echo "$USER_RESPONSE" | grep -o '"role":"[^"]*' | cut -d'"' -f4)
USER_NAME=$(echo "$USER_RESPONSE" | grep -o '"username":"[^"]*' | cut -d'"' -f4)
USER_EMAIL=$(echo "$USER_RESPONSE" | grep -o '"email":"[^"]*' | cut -d'"' -f4)

print_status "User Details:"
echo "  - ID: $USER_ID"
echo "  - Username: $USER_NAME"
echo "  - Email: $USER_EMAIL" 
echo "  - Role: $USER_ROLE"

# Step 3: Check if user is SUPER_ADMIN
if [ "$USER_ROLE" == "SUPER_ADMIN" ]; then
    print_error "Cannot delete SUPER_ADMIN users!"
    print_warning "Super Admin users are protected from deletion"
    exit 1
fi

# Step 4: Confirmation prompt
print_warning "Are you sure you want to delete this user? (y/N)"
read -r CONFIRM

if [ "$CONFIRM" != "y" ] && [ "$CONFIRM" != "Y" ]; then
    print_status "User deletion cancelled"
    exit 0
fi

# Step 5: Delete the user
print_status "Deleting user..."
DELETE_RESPONSE=$(curl -s -X DELETE "$API_URL/api/users/$USER_ID" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json")

if [ $? -ne 0 ]; then
    print_error "Failed to delete user"
    exit 1
fi

# Check response for success
if echo "$DELETE_RESPONSE" | grep -q '"statusCode":"0000"'; then
    print_success "User deleted successfully!"
    print_status "Deleted user details:"
    echo "  - ID: $USER_ID"
    echo "  - Username: $USER_NAME"
    echo "  - Email: $USER_EMAIL"
    echo "  - Role: $USER_ROLE"
else
    print_error "Failed to delete user"
    echo "Response: $DELETE_RESPONSE"
    exit 1
fi

print_success "User deletion process completed"