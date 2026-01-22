#!/bin/bash
set -e

# Fast Deployment Script with Fixed Port
# Uses fixed port 8085 - brief downtime during restart but reliable

echo "🚀 Starting Fast Deployment..."

# Configuration
PROJECT_DIR="/opt/shop-management"
COMPOSE_FILE="docker-compose.yml"
BACKEND_PORT=8085

# Colors for output
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

# Step 1: Build new image FIRST (no downtime during build)
log_step "Building new backend image..."
docker-compose -f $COMPOSE_FILE build backend
log_info "Build complete!"

# Step 2: Get current backend (if exists)
OLD_BACKEND=$(docker ps --filter "label=com.shop.service=backend" --format "{{.Names}}" | head -n 1 || echo "")

if [ -n "$OLD_BACKEND" ]; then
    log_info "Found existing backend: $OLD_BACKEND"

    # Step 3: Stop old backend
    log_step "Stopping old backend..."
    STOP_TIME=$(date '+%Y-%m-%d %H:%M:%S.%3N')
    docker stop $OLD_BACKEND
    docker rm $OLD_BACKEND
    log_info "Old backend stopped at $STOP_TIME"
else
    log_warn "No existing backend found"
fi

# Step 4: Start new backend
log_step "Starting new backend on port $BACKEND_PORT..."
START_TIME=$(date '+%Y-%m-%d %H:%M:%S.%3N')
docker-compose -f $COMPOSE_FILE up -d backend
log_info "New backend started at $START_TIME"

# Step 5: Wait for new backend to be healthy
log_step "Waiting for backend to be healthy..."
NEW_BACKEND=$(docker ps --filter "label=com.shop.service=backend" --format "{{.Names}}" | head -n 1)

RETRY_COUNT=0
MAX_RETRIES=30

while [ $RETRY_COUNT -lt $MAX_RETRIES ]; do
    # Check container health status
    HEALTH_STATUS=$(docker inspect --format='{{.State.Health.Status}}' $NEW_BACKEND 2>/dev/null || echo "starting")

    if [ "$HEALTH_STATUS" = "healthy" ]; then
        log_info "Backend is healthy!"
        break
    fi

    # Also try direct health check
    if curl -f -s http://localhost:$BACKEND_PORT/actuator/health > /dev/null 2>&1; then
        log_info "Backend health endpoint responding!"
        break
    fi

    log_warn "Health: $HEALTH_STATUS (attempt $((RETRY_COUNT+1))/$MAX_RETRIES)"
    sleep 3
    RETRY_COUNT=$((RETRY_COUNT+1))
done

if [ $RETRY_COUNT -eq $MAX_RETRIES ]; then
    log_error "Backend failed to become healthy!"
    docker logs $NEW_BACKEND --tail 100
    exit 1
fi

# Step 6: Clean up old images (keep last 3)
log_step "Cleaning up old images..."
docker images --filter "reference=*backend*" --format "{{.ID}} {{.CreatedAt}}" | sort -rk 2 | awk 'NR>3 {print $1}' | xargs -r docker rmi -f 2>/dev/null || true
docker image prune -f >/dev/null 2>&1

# Final status
echo ""
log_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
log_info "✅ Deployment Complete!"
log_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
log_info "Active backend: $NEW_BACKEND (port $BACKEND_PORT)"
if [ -n "$STOP_TIME" ]; then
    log_info "Old container stopped: $STOP_TIME"
fi
log_info "New container started: $START_TIME"
echo ""
docker ps --filter "label=com.shop.service=backend"
