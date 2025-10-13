#!/bin/bash
# Firebase Configuration Setup Script
# Run this on the production server: bash setup-on-server.sh

set -e

echo "=================================================="
echo " Firebase Configuration Setup"
echo "=================================================="
echo ""

# Create firebase-config directory
echo "[1/4] Creating firebase-config directory..."
mkdir -p /opt/shop-management/firebase-config

# Set directory permissions
echo "[2/4] Setting directory permissions..."
chmod 700 /opt/shop-management/firebase-config

# Check for existing files
echo "[3/4] Checking for Firebase configuration files..."
echo ""

FILES_MISSING=0

if [ -f "/opt/shop-management/firebase-config/firebase-service-account.json" ]; then
    echo "✅ firebase-service-account.json - Found"
    chmod 600 /opt/shop-management/firebase-config/firebase-service-account.json
else
    echo "❌ firebase-service-account.json - MISSING"
    echo "   Upload from local: scp /path/to/firebase-service-account.json root@65.21.4.236:/opt/shop-management/firebase-config/"
    FILES_MISSING=1
fi

if [ -f "/opt/shop-management/firebase-config/google-services.json" ]; then
    echo "✅ google-services.json - Found"
    chmod 600 /opt/shop-management/firebase-config/google-services.json
else
    echo "⚠️  google-services.json - MISSING (required for Android app)"
    echo "   Upload from local: scp /path/to/google-services.json root@65.21.4.236:/opt/shop-management/firebase-config/"
fi

if [ -f "/opt/shop-management/firebase-config/firebase-web-config.json" ]; then
    echo "✅ firebase-web-config.json - Found"
    chmod 600 /opt/shop-management/firebase-config/firebase-web-config.json
else
    echo "⚠️  firebase-web-config.json - MISSING (required for web frontend)"
    echo "   Upload from local: scp /path/to/firebase-web-config.json root@65.21.4.236:/opt/shop-management/firebase-config/"
fi

echo ""
echo "[4/4] File permissions and ownership..."
chown -R root:root /opt/shop-management/firebase-config
chmod 700 /opt/shop-management/firebase-config
chmod 600 /opt/shop-management/firebase-config/*.json 2>/dev/null || true

echo ""
echo "=================================================="
echo " Current Firebase Configuration Files"
echo "=================================================="
ls -la /opt/shop-management/firebase-config/

echo ""
if [ $FILES_MISSING -eq 0 ]; then
    echo "✅ Setup complete! All required files present."
else
    echo "⚠️  Setup incomplete - missing required files."
    echo "   Upload the missing files before deploying."
fi

echo ""
echo "=================================================="
echo " How to Upload Files from Local Machine"
echo "=================================================="
echo ""
echo "From Windows PowerShell or Linux terminal:"
echo "  scp C:\\path\\to\\firebase-service-account.json root@65.21.4.236:/opt/shop-management/firebase-config/"
echo ""
echo "After uploading, run this script again to set permissions."
echo ""
