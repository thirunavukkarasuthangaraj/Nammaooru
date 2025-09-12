#!/bin/bash

# Script to fix image upload directory permissions on the server
# Run this on the Hetzner server as root or with sudo

echo "Fixing image upload directory structure and permissions..."

# Create the upload directory structure
mkdir -p /var/www/shop-management/uploads/products/master
mkdir -p /var/www/shop-management/uploads/products/shop
mkdir -p /var/www/shop-management/uploads/documents/shops

# Set ownership to the application user (adjust 'www-data' to your actual app user)
# If running as systemd service, check the User= in your service file
chown -R www-data:www-data /var/www/shop-management/uploads

# Set proper permissions
# Directories need execute permission for traversal
find /var/www/shop-management/uploads -type d -exec chmod 755 {} \;
# Files should be readable/writable by owner
find /var/www/shop-management/uploads -type f -exec chmod 644 {} \;

echo "Directory structure created and permissions set."
echo ""
echo "Current directory structure:"
ls -la /var/www/shop-management/uploads/

echo ""
echo "If your application runs as a different user (not www-data),"
echo "update the chown command with the correct user."
echo ""
echo "To find the application user, check:"
echo "1. systemctl status your-app-name (look for Main PID and user)"
echo "2. ps aux | grep java (if Spring Boot app)"
echo "3. Check your systemd service file: /etc/systemd/system/shop-management.service"