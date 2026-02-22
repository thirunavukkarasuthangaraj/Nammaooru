#!/bin/bash
set -e

# Zero Downtime Frontend Deployment Script (v2)
# Run this ON THE SERVER after uploading new build
# Usage: ./zero-downtime-frontend-deploy.sh

echo "🚀 Starting Zero Downtime Frontend Deployment..."

# Configuration
NGINX_ROOT="/var/www"
RELEASE_DIR="$NGINX_ROOT/releases"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
NEW_RELEASE_DIR="$RELEASE_DIR/$TIMESTAMP"
CURRENT_SYMLINK="$NGINX_ROOT/html"
SOURCE_BUILD="/opt/shop-management/frontend/dist/shop-management-frontend"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

log_info() { echo -e "${GREEN}✓ $1${NC}"; }
log_warn() { echo -e "${YELLOW}⚠ $1${NC}"; }
log_error() { echo -e "${RED}✗ $1${NC}"; }

# Step 1: Create releases directory if it doesn't exist
log_info "Setting up releases directory..."
mkdir -p $RELEASE_DIR

# Step 2: Copy new build to release directory
log_info "Copying new build to $NEW_RELEASE_DIR..."
cp -r $SOURCE_BUILD $NEW_RELEASE_DIR

# Step 3: Set correct permissions
log_info "Setting permissions..."
chmod -R 755 $NEW_RELEASE_DIR
# chown to www-data is optional - chmod 755 gives read access to all users including nginx
chown -R www-data:www-data $NEW_RELEASE_DIR 2>/dev/null || log_warn "chown skipped (not root), files are still readable via chmod 755"

# Step 4: Verify new build
log_info "Verifying new build..."
if [ ! -f "$NEW_RELEASE_DIR/index.html" ]; then
    log_error "index.html not found in new release!"
    rm -rf $NEW_RELEASE_DIR
    exit 1
fi

# Step 5: Atomic symlink swap (THIS IS THE KEY FOR ZERO DOWNTIME)
log_info "Performing atomic symlink swap..."
# Create temporary symlink
ln -sfn $NEW_RELEASE_DIR $NGINX_ROOT/html_tmp
# Atomically move it over the current symlink
mv -Tf $NGINX_ROOT/html_tmp $CURRENT_SYMLINK

# Step 6: Test nginx configuration
log_info "Testing Nginx configuration..."
if nginx -t; then
    log_info "Reloading Nginx..."
    systemctl reload nginx
else
    log_error "Nginx configuration test failed!"
    # Rollback is not needed - old release is still there
    exit 1
fi

# Step 7: Clean up old releases (keep last 5)
log_info "Cleaning up old releases (keeping last 5)..."
cd $RELEASE_DIR
ls -t | tail -n +6 | xargs -r rm -rf

# Success
log_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
log_info "✅ Frontend Deployment Complete!"
log_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
log_info "Current release: $TIMESTAMP"
log_info "Active symlink: $CURRENT_SYMLINK -> $NEW_RELEASE_DIR"
log_info ""
log_info "Verify deployment:"
log_info "  curl -I https://nammaoorudelivary.in"
log_info ""
log_info "Rollback if needed:"
log_info "  PREVIOUS=\$(ls -t $RELEASE_DIR | head -n 2 | tail -n 1)"
log_info "  ln -sfn $RELEASE_DIR/\$PREVIOUS $CURRENT_SYMLINK"
log_info "  systemctl reload nginx"
log_info ""

# Show available releases
log_info "Available releases:"
ls -lth $RELEASE_DIR | head -n 6
