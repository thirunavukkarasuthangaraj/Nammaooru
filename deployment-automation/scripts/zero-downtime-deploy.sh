#!/bin/bash
set -e

# Zero Downtime Deployment Script - With API health checks during container stop

echo "🚀 Starting Zero Downtime Deployment..."

# Configuration
PROJECT_DIR="/opt/shop-management"
COMPOSE_FILE="docker-compose.yml"
NGINX_CONFIG="/etc/nginx/sites-available/api.nammaoorudelivary.in"
API_URL="https://api.nammaoorudelivary.in/api/version"

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

# Function to check API health
check_api_health() {
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S.%3N')
    local http_code=$(curl -s -o /dev/null -w '%{http_code}' "$API_URL" 2>/dev/null || echo "000")
    
    if [ "$http_code" = "200" ]; then
        log_info "[$timestamp] ✅ API HEALTH CHECK: HTTP $http_code - API is UP and responding"
        return 0
    else
        log_error "[$timestamp] ❌ API HEALTH CHECK: HTTP $http_code - API is DOWN!"
        return 1
    fi
}

cd $PROJECT_DIR

# Step 1: Build new image
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
log_step "Building new backend image..."
docker-compose -f $COMPOSE_FILE build backend

# Step 2: Get current backend
OLD_BACKEND=$(docker ps --filter "label=com.shop.service=backend" --format "{{.Names}}" | head -n 1)
OLD_BACKEND_PORT=$(docker port $OLD_BACKEND 8080 | cut -d':' -f2)
log_info "Current backend: $OLD_BACKEND (port $OLD_BACKEND_PORT)"

# Initial API check
log_step "Checking API before deployment..."
check_api_health

# Step 3: Start new backend (will run alongside old)
log_step "Starting new backend container alongside old one..."
log_warn "⏰ API should remain accessible during this step"
docker-compose -f $COMPOSE_FILE up -d --no-deps --scale backend=2 --no-recreate backend
sleep 5

# Step 4: Get new backend
NEW_BACKEND=$(docker ps --filter "label=com.shop.service=backend" --format "{{.Names}}" | grep -v "$OLD_BACKEND" | head -n 1)
NEW_BACKEND_PORT=$(docker port $NEW_BACKEND 8080 | cut -d':' -f2)
log_info "New backend: $NEW_BACKEND (port $NEW_BACKEND_PORT)"

# API check after new container started
log_step "Checking API after new container started..."
check_api_health

# Step 5: Wait for new backend health
log_step "Waiting for new backend to be healthy..."
RETRY_COUNT=0
MAX_RETRIES=30

while [ $RETRY_COUNT -lt $MAX_RETRIES ]; do
    HEALTH_STATUS=$(docker inspect --format='{{.State.Health.Status}}' $NEW_BACKEND 2>/dev/null || echo "starting")
    
    if [ "$HEALTH_STATUS" = "healthy" ]; then
        log_info "New backend is healthy!"
        break
    fi
    
    log_warn "Health: $HEALTH_STATUS (attempt $((RETRY_COUNT+1))/$MAX_RETRIES)"
    sleep 3
    RETRY_COUNT=$((RETRY_COUNT+1))
done

if [ $RETRY_COUNT -eq $MAX_RETRIES ]; then
    log_error "New backend failed to become healthy!"
    docker logs $NEW_BACKEND --tail 100
    log_warn "Rolling back..."
    docker stop $NEW_BACKEND
    docker rm $NEW_BACKEND
    exit 1
fi

# API check after new container healthy
log_step "Checking API after new container is healthy..."
check_api_health

# Step 6: Update Nginx to new backend
log_step "Switching Nginx from port $OLD_BACKEND_PORT to $NEW_BACKEND_PORT"
log_warn "⏰ CRITICAL MOMENT: Switching traffic from old to new container"
sed -i "s|proxy_pass http://localhost:[0-9]*;|proxy_pass http://localhost:$NEW_BACKEND_PORT;|" $NGINX_CONFIG

# Step 7: Test and reload Nginx
if nginx -t 2>&1 | grep -q "successful"; then
    log_step "Reloading Nginx..."
    NGINX_RELOAD_TIME=$(date '+%Y-%m-%d %H:%M:%S.%3N')
    systemctl reload nginx
    log_info "✅ Nginx reloaded at $NGINX_RELOAD_TIME - Traffic now on new container"
else
    log_error "Nginx config test failed! Rolling back..."
    sed -i "s|proxy_pass http://localhost:[0-9]*;|proxy_pass http://localhost:$OLD_BACKEND_PORT;|" $NGINX_CONFIG
    docker stop $NEW_BACKEND
    docker rm $NEW_BACKEND
    exit 1
fi

# API check immediately after Nginx switch
log_step "Checking API immediately after Nginx switch..."
check_api_health

# Step 8: Wait for connections to drain
log_step "Waiting 10s for connections to drain from old container..."
log_warn "⏰ Old container $OLD_BACKEND is still running, draining connections"

# API checks during drain period
for i in {1..5}; do
    sleep 2
    log_step "API check during drain period ($i/5)..."
    check_api_health
done

# Step 9: Stop old backend - WITH API CHECKS!
log_step "Stopping old backend container: $OLD_BACKEND"
OLD_CONTAINER_STOP_TIME=$(date '+%Y-%m-%d %H:%M:%S.%3N')

# API check BEFORE stopping old container
log_warn "⏰ API CHECK BEFORE STOPPING OLD CONTAINER"
check_api_health

log_warn "⏰ STOPPING OLD CONTAINER at $OLD_CONTAINER_STOP_TIME"
docker stop $OLD_BACKEND

# API check IMMEDIATELY AFTER stopping old container
log_warn "⏰ API CHECK IMMEDIATELY AFTER OLD CONTAINER STOPPED"
check_api_health

# More API checks to verify stability
for i in {1..3}; do
    sleep 1
    log_step "API check after old container stopped ($i/3)..."
    check_api_health
done

docker rm $OLD_BACKEND
log_info "Old container stopped at $OLD_CONTAINER_STOP_TIME"

# Step 10: Clean up old images (keep last 3)
log_step "Cleaning up old images..."
docker images --filter "reference=*backend*" --format "{{.ID}} {{.CreatedAt}}" | sort -rk 2 | awk 'NR>3 {print $1}' | xargs -r docker rmi -f 2>/dev/null || true
docker image prune -f >/dev/null 2>&1

# Final API health check
log_step "Final API health check..."
check_api_health

# Final status
echo ""
log_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
log_info "✅ Zero Downtime Deployment Complete!"
log_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
log_info "Active backend: $NEW_BACKEND (port $NEW_BACKEND_PORT)"
log_info "Deployment timestamp: $TIMESTAMP"
echo ""
log_info "Timeline Summary:"
log_info "  - Nginx switched at: $NGINX_RELOAD_TIME"
log_info "  - Old container stopped at: $OLD_CONTAINER_STOP_TIME"
echo ""
docker ps --filter "label=com.shop.service=backend"
