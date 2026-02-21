#!/bin/bash
set -e

# Backend Deployment Script - Fixed port (8081)
# Simple: build → stop old → start new → verify

echo "🚀 Starting Backend Deployment..."

# Configuration
PROJECT_DIR="/opt/shop-management"
COMPOSE_FILE="docker compose.yml"
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

# Step 1: Build new image (--no-cache ensures fresh build with latest code)
log_step "Building new backend image..."
DOCKER_BUILDKIT=1 docker compose -f $COMPOSE_FILE build --no-cache --build-arg MAVEN_OPTS="-Xmx512m" backend
log_info "Backend image built successfully"

# Step 2: Check current API status
log_step "Checking API before deployment..."
HTTP_CODE=$(curl -s -o /dev/null -w '%{http_code}' "$API_URL" 2>/dev/null || echo "000")
if [ "$HTTP_CODE" = "200" ]; then
    log_info "API is UP (HTTP $HTTP_CODE) - proceeding with deployment"
else
    log_warn "API is DOWN (HTTP $HTTP_CODE) - deploying anyway"
fi

# Step 3: Recreate backend container with new image
log_step "Stopping old backend and starting new one..."
DEPLOY_START=$(date '+%Y-%m-%d %H:%M:%S.%3N')
docker compose -f $COMPOSE_FILE up -d --force-recreate --no-deps backend
log_info "New backend container started"

# Step 4: Wait for new backend to be healthy
log_step "Waiting for backend to be healthy..."
RETRY_COUNT=0
MAX_RETRIES=40

while [ $RETRY_COUNT -lt $MAX_RETRIES ]; do
    CONTAINER_NAME=$(docker ps --filter "label=com.shop.service=backend" --format "{{.Names}}" | head -n 1)

    if [ -z "$CONTAINER_NAME" ]; then
        log_warn "No backend container found, waiting... (attempt $((RETRY_COUNT+1))/$MAX_RETRIES)"
        sleep 5
        RETRY_COUNT=$((RETRY_COUNT+1))
        continue
    fi

    HEALTH_STATUS=$(docker inspect --format='{{.State.Health.Status}}' $CONTAINER_NAME 2>/dev/null || echo "starting")

    if [ "$HEALTH_STATUS" = "healthy" ]; then
        log_info "Backend is healthy!"
        break
    fi

    log_warn "Health: $HEALTH_STATUS (attempt $((RETRY_COUNT+1))/$MAX_RETRIES)"
    sleep 5
    RETRY_COUNT=$((RETRY_COUNT+1))
done

if [ $RETRY_COUNT -eq $MAX_RETRIES ]; then
    log_error "Backend failed to become healthy!"
    docker logs $CONTAINER_NAME --tail 50
    exit 1
fi

# Step 5: Verify API is responding
log_step "Verifying API is responding..."
sleep 3
VERIFY_COUNT=0
while [ $VERIFY_COUNT -lt 6 ]; do
    HTTP_CODE=$(curl -s -o /dev/null -w '%{http_code}' "$API_URL" 2>/dev/null || echo "000")
    if [ "$HTTP_CODE" = "200" ]; then
        log_info "API is UP and responding (HTTP $HTTP_CODE)"
        break
    fi
    log_warn "API not ready yet (HTTP $HTTP_CODE), retrying..."
    sleep 5
    VERIFY_COUNT=$((VERIFY_COUNT+1))
done

# Step 6: Clean up old images
log_step "Cleaning up old images..."
docker image prune -f >/dev/null 2>&1 || true

# Final status
DEPLOY_END=$(date '+%Y-%m-%d %H:%M:%S.%3N')
echo ""
log_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
log_info "✅ Backend Deployment Complete!"
log_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
log_info "Container: $CONTAINER_NAME (port 8081)"
log_info "Deploy started: $DEPLOY_START"
log_info "Deploy finished: $DEPLOY_END"
echo ""
docker ps --filter "label=com.shop.service=backend"
