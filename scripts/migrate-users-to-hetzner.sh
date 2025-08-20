#!/bin/bash

# Migration script for users table data from local to Hetzner Docker PostgreSQL
# Usage: ./migrate-users-to-hetzner.sh <server_ip>

SERVER_IP=$1
SSH_USER="root"  # Change if different

if [ -z "$SERVER_IP" ]; then
    echo "Usage: ./migrate-users-to-hetzner.sh <server_ip>"
    echo "Example: ./migrate-users-to-hetzner.sh 123.456.789.0"
    exit 1
fi

echo "========================================="
echo "  Migrating Users Data to Hetzner"
echo "========================================="

# Check if export file exists
if [ ! -f "users_data_export.sql" ]; then
    echo "❌ Error: users_data_export.sql not found!"
    echo "Please run the export command first."
    exit 1
fi

echo "📤 Transferring data to server..."
scp users_data_export.sql $SSH_USER@$SERVER_IP:/tmp/

echo "📥 Importing data into Docker PostgreSQL..."
ssh $SSH_USER@$SERVER_IP << 'EOF'
    # First, backup existing users table (if any)
    echo "🔒 Backing up existing users data..."
    docker exec shop-postgres pg_dump -U postgres -d shop_management_db -t users --data-only > /tmp/users_backup_$(date +%Y%m%d_%H%M%S).sql
    
    # Clear existing users (optional - comment out if you want to append)
    echo "🧹 Clearing existing users table..."
    docker exec shop-postgres psql -U postgres -d shop_management_db -c "TRUNCATE TABLE users CASCADE;"
    
    # Import new users data
    echo "💾 Importing new users data..."
    docker cp /tmp/users_data_export.sql shop-postgres:/tmp/
    docker exec shop-postgres psql -U postgres -d shop_management_db < /tmp/users_data_export.sql
    
    # Verify import
    echo "✅ Verifying import..."
    docker exec shop-postgres psql -U postgres -d shop_management_db -c "SELECT COUNT(*) as user_count, STRING_AGG(DISTINCT role, ', ') as roles FROM users;"
    
    # Clean up
    rm /tmp/users_data_export.sql
    docker exec shop-postgres rm /tmp/users_data_export.sql
EOF

echo ""
echo "✅ Migration complete!"
echo ""
echo "Note: Users have been migrated with their existing passwords."
echo "Make sure your application JWT_SECRET matches between environments."