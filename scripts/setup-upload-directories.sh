#!/bin/bash
# ============================================
# Setup Upload Directories for Production Server
# ============================================
# This script creates the necessary upload directories
# and sets proper permissions for the application
#
# Run this on your production server (Ubuntu) as root or with sudo
# ============================================

echo "========================================"
echo "Setting up upload directories..."
echo "========================================"

# Define base upload directory
UPLOAD_BASE="/home/ubuntu/uploads"

# Create directory structure
echo "Creating directory structure..."
sudo mkdir -p ${UPLOAD_BASE}/documents/shops
sudo mkdir -p ${UPLOAD_BASE}/documents/delivery-partners
sudo mkdir -p ${UPLOAD_BASE}/products
sudo mkdir -p ${UPLOAD_BASE}/profiles

# Set ownership to the user running the application (usually ubuntu or the app user)
APP_USER="${APP_USER:-ubuntu}"
echo "Setting ownership to ${APP_USER}..."
sudo chown -R ${APP_USER}:${APP_USER} ${UPLOAD_BASE}

# Set proper permissions (755 for directories, 644 for files)
echo "Setting permissions..."
sudo chmod -R 755 ${UPLOAD_BASE}

# Create a test file to verify write permissions
echo "Testing write permissions..."
if sudo -u ${APP_USER} touch ${UPLOAD_BASE}/test-write.txt 2>/dev/null; then
    echo "✓ Write permissions OK"
    sudo -u ${APP_USER} rm ${UPLOAD_BASE}/test-write.txt
else
    echo "✗ Write permissions FAILED"
    exit 1
fi

# Display directory structure
echo ""
echo "Directory structure created:"
tree ${UPLOAD_BASE} 2>/dev/null || find ${UPLOAD_BASE} -type d

echo ""
echo "========================================"
echo "✓ Upload directories setup complete!"
echo "========================================"
echo ""
echo "Directory: ${UPLOAD_BASE}"
echo "Owner: ${APP_USER}"
echo "Permissions: 755"
echo ""
echo "Make sure to set these environment variables in your production server:"
echo "  export DELIVERY_PARTNER_DOCUMENT_PATH=${UPLOAD_BASE}/documents/delivery-partners"
echo "  export DOCUMENT_UPLOAD_PATH=${UPLOAD_BASE}/documents/shops"
echo "  export PRODUCT_IMAGES_PATH=${UPLOAD_BASE}/products"
echo ""
