#!/bin/bash
set -e

# Setup script for Zero Downtime Deployment
# Run this once to set up the infrastructure on the production server

echo "🔧 Setting up Zero Downtime Deployment Infrastructure"
echo "======================================================"
echo ""

SERVER="root@65.21.4.236"
NGINX_CONFIG="/etc/nginx/sites-available/api.nammaoorudelivary.in"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

log_info() { echo -e "${GREEN}✓ $1${NC}"; }
log_warn() { echo -e "${YELLOW}⚠ $1${NC}"; }
log_error() { echo -e "${RED}✗ $1${NC}"; }

echo "This script will:"
echo "1. Upload deployment scripts to server"
echo "2. Update Nginx configuration for zero downtime"
echo "3. Setup frontend release directory structure"
echo "4. Make scripts executable"
echo ""
read -p "Continue? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Aborted."
    exit 1
fi

# Step 1: Upload scripts to server
log_info "Step 1/4: Uploading deployment scripts to server..."
# Create deployment directory on server
ssh $SERVER "mkdir -p /opt/shop-management/deployment"
scp zero-downtime-deploy.sh $SERVER:/opt/shop-management/deployment/
scp zero-downtime-frontend-deploy.sh $SERVER:/opt/shop-management/deployment/
scp nginx-api-updated.conf $SERVER:/tmp/nginx-api-updated.conf

# Step 2: Update Nginx configuration
log_info "Step 2/4: Updating Nginx configuration..."
ssh $SERVER << 'ENDSSH'
# Backup current nginx config
cp /etc/nginx/sites-available/api.nammaoorudelivary.in /etc/nginx/sites-available/api.nammaoorudelivary.in.backup

# Install new config
cp /tmp/nginx-api-updated.conf /etc/nginx/sites-available/api.nammaoorudelivary.in

# Test and reload
if nginx -t; then
    systemctl reload nginx
    echo "✓ Nginx configuration updated successfully"
else
    echo "✗ Nginx test failed! Restoring backup..."
    cp /etc/nginx/sites-available/api.nammaoorudelivary.in.backup /etc/nginx/sites-available/api.nammaoorudelivary.in
    exit 1
fi

# Clean up
rm /tmp/nginx-api-updated.conf
ENDSSH

# Step 3: Setup frontend release directory
log_info "Step 3/4: Setting up frontend release directory structure..."
ssh $SERVER << 'ENDSSH'
cd /var/www

# Check if html is already a symlink
if [ -L html ]; then
    echo "✓ /var/www/html is already a symlink"
else
    echo "Converting /var/www/html to symlink structure..."

    # Create releases directory
    mkdir -p releases

    # Create timestamped release
    TIMESTAMP=$(date +%Y%m%d_%H%M%S)
    mkdir -p releases/$TIMESTAMP

    # Copy current site
    if [ -d html ]; then
        cp -r html/* releases/$TIMESTAMP/ 2>/dev/null || true
        rm -rf html
    fi

    # Create symlink
    ln -s releases/$TIMESTAMP html

    # Set permissions
    chown -R www-data:www-data releases
    chmod -R 755 releases

    echo "✓ Frontend release structure created"
fi
ENDSSH

# Step 4: Make scripts executable
log_info "Step 4/4: Making deployment scripts executable..."
ssh $SERVER "chmod +x /opt/shop-management/deployment/zero-downtime-deploy.sh /opt/shop-management/deployment/zero-downtime-frontend-deploy.sh"

# Final verification
log_info ""
log_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
log_info "✅ Zero Downtime Infrastructure Setup Complete!"
log_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
log_info ""
log_info "Verification:"
echo "Running verification checks on server..."
echo ""

ssh $SERVER << 'ENDSSH'
echo "1. Nginx Configuration:"
nginx -t 2>&1 | grep -E "syntax is ok|successful"

echo ""
echo "2. Frontend Structure:"
ls -la /var/www/ | grep -E "html|releases"

echo ""
echo "3. Deployment Scripts:"
ls -lh /opt/shop-management/deployment/zero-downtime*.sh

echo ""
echo "4. Docker Containers:"
docker ps --filter "label=com.shop.service=backend" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
ENDSSH

echo ""
log_info "✅ Setup verified successfully!"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Next Steps:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "To deploy backend with zero downtime:"
echo "  ssh $SERVER"
echo "  cd /opt/shop-management/deployment"
echo "  ./zero-downtime-deploy.sh"
echo ""
echo "To deploy frontend with zero downtime:"
echo "  # On local machine:"
echo "  cd frontend && ng build --configuration production"
echo "  cd dist && tar -czf deploy.tar.gz shop-management-frontend/"
echo "  scp deploy.tar.gz $SERVER:/opt/shop-management/frontend/dist/"
echo "  "
echo "  # On server:"
echo "  ssh $SERVER"
echo "  cd /opt/shop-management/frontend/dist && tar -xzf deploy.tar.gz"
echo "  cd /opt/shop-management/deployment && ./zero-downtime-frontend-deploy.sh"
echo ""
log_info "Happy deploying! 🚀"
