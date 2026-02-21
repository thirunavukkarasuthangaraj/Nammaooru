#!/bin/bash
set -e

# Zero Downtime Deployment Script
# Uses dynamic ports + scale approach (no --force-recreate)

echo "🚀 Starting Zero Downtime Deployment..."

# Configuration
PROJECT_DIR="/opt/shop-management"
COMPOSE_FILE="docker-compose.yml"
NGINX_CONFIG="/etc/nginx/sites-available/api.nammaoorudelivary.in"
API_URL="https://api.nammaoorudelivary.in/api/version"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() { echo -e "${GREEN}✓ [$(date '+%Y-%m-%d %H:%M:%S')] $1${NC}"; }
log_warn() { echo -e "${YELLOW}⚠ [$(date '+%Y-%m-%d %H:%M:%S')] $1${NC}"; }
log_error() { echo -e "${RED}✗ [$(date '+%Y-%m-%d %H:%M:%S')] $1${NC}"; }
log_step() { echo -e "${BLUE}→ [$(date '+%Y-%m-%d %H:%M:%S')] $1${NC}"; }

cd $PROJECT_DIR

# Step 1: Build new image
log_step "Building new backend image..."
DOCKER_BUILDKIT=1 docker-compose -f $COMPOSE_FILE build --no-cache --build-arg MAVEN_OPTS="-Xmx512m" backend
log_info "Backend image built successfully"

# Step 2: Get current backend container
OLD_BACKEND=$(docker ps --filter "label=com.shop.service=backend" --format "{{.Names}}" | head -n 1)
if [ -n "$OLD_BACKEND" ]; then
    log_info "Current backend container: $OLD_BACKEND"
else
    log_warn "No existing backend container found"
fi

# Step 3: Start new backend alongside old one (dynamic port)
log_step "Starting new backend container..."
docker-compose -f $COMPOSE_FILE up -d --no-deps --scale backend=2 --no-recreate backend
log_info "New backend container started"

# Step 4: Get new backend container
sleep 5
NEW_BACKEND=$(docker ps --filter "label=com.shop.service=backend" --format "{{.Names}}" | grep -v "$OLD_BACKEND" | head -n 1)

if [ -z "$NEW_BACKEND" ]; then
    # If no old backend existed, just get the first one
    NEW_BACKEND=$(docker ps --filter "label=com.shop.service=backend" --format "{{.Names}}" | head -n 1)
fi

log_info "New backend container: $NEW_BACKEND"

# Step 5: Wait for new backend to be healthy
log_step "Waiting for new backend to be healthy..."
RETRY_COUNT=0
MAX_RETRIES=40

while [ $RETRY_COUNT -lt $MAX_RETRIES ]; do
    HEALTH_STATUS=$(docker inspect --format='{{.State.Health.Status}}' $NEW_BACKEND 2>/dev/null || echo "starting")

    if [ "$HEALTH_STATUS" = "healthy" ]; then
        log_info "New backend is healthy!"
        break
    fi

    log_warn "Health: $HEALTH_STATUS (attempt $((RETRY_COUNT+1))/$MAX_RETRIES)"
    sleep 5
    RETRY_COUNT=$((RETRY_COUNT+1))
done

if [ $RETRY_COUNT -eq $MAX_RETRIES ]; then
    log_error "New backend failed to become healthy!"
    docker logs $NEW_BACKEND --tail 50
    log_warn "Rolling back - removing new container..."
    docker stop $NEW_BACKEND
    docker rm $NEW_BACKEND
    exit 1
fi

# Step 6: Update Nginx to point to new backend's dynamic port
log_step "Updating Nginx to new backend..."
NEW_PORT=$(docker port $NEW_BACKEND 8080 | cut -d':' -f2)
log_info "New backend port: $NEW_PORT"

sudo sed -i "s|proxy_pass http://localhost:[0-9]*;|proxy_pass http://localhost:$NEW_PORT;|" $NGINX_CONFIG

if sudo nginx -t; then
    sudo systemctl reload nginx
    log_info "Nginx updated to port $NEW_PORT"
else
    log_error "Nginx config test failed!"
    exit 1
fi

# Step 7: Wait for connections to drain from old backend
if [ -n "$OLD_BACKEND" ]; then
    log_step "Waiting 15s for connections to drain..."
    sleep 15

    # Step 8: Stop and remove old backend
    log_step "Removing old backend: $OLD_BACKEND"
    docker stop $OLD_BACKEND
    docker rm $OLD_BACKEND
    log_info "Old backend removed"
fi

# Step 9: Verify API is responding
log_step "Verifying API..."
sleep 3
VERIFY_COUNT=0
while [ $VERIFY_COUNT -lt 6 ]; do
    HTTP_CODE=$(curl -s -o /dev/null -w '%{http_code}' "$API_URL" 2>/dev/null || echo "000")
    if [ "$HTTP_CODE" = "200" ]; then
        log_info "API is UP (HTTP $HTTP_CODE)"
        break
    fi
    log_warn "API not ready (HTTP $HTTP_CODE), retrying..."
    sleep 5
    VERIFY_COUNT=$((VERIFY_COUNT+1))
done

# Step 10: Clean up
log_step "Cleaning up old images..."
docker image prune -f >/dev/null 2>&1 || true

# Final status
echo ""
log_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
log_info "✅ Zero Downtime Deployment Complete!"
log_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
log_info "Container: $NEW_BACKEND (port $NEW_PORT)"
echo ""
docker ps --filter "label=com.shop.service=backend"
