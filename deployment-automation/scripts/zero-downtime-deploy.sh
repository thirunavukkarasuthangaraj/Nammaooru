#!/bin/bash
set -e

# Zero Downtime Deployment Script
# Run this on the production server: root@65.21.4.236

echo "🚀 Starting Zero Downtime Deployment..."

# Configuration
PROJECT_DIR="/opt/shop-management"
COMPOSE_FILE="docker-compose.yml"
NGINX_CONFIG="/etc/nginx/sites-available/api.nammaoorudelivary.in"
SERVICE_NAME="shop-management-system"

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Function to print colored output
log_info() { echo -e "${GREEN}✓ $1${NC}"; }
log_warn() { echo -e "${YELLOW}⚠ $1${NC}"; }
log_error() { echo -e "${RED}✗ $1${NC}"; }

# Change to project directory
cd $PROJECT_DIR

# Step 1: Pull latest code (if using git) - Skip if CI/CD already updated files
if [ -d ".git" ] && [ "${SKIP_GIT_PULL:-false}" != "true" ]; then
    log_info "Pulling latest code from git..."
    git pull || log_warn "Git pull failed (continuing anyway - CI/CD may have updated files via SCP)"
fi

# Step 2: Build new images with unique tag
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
log_info "Building new images with tag: $TIMESTAMP..."
docker-compose -f $COMPOSE_FILE build --build-arg BUILD_DATE=$TIMESTAMP

# Step 3: Get current backend container
OLD_BACKEND=$(docker ps --filter "label=com.shop.service=backend" --format "{{.Names}}" | head -n 1)
log_info "Current backend container: $OLD_BACKEND"

# Step 4: Start new backend container (will run alongside old one)
# IMPORTANT: Start with scheduling DISABLED to prevent duplicate job execution
log_info "Starting new backend container with scheduling disabled..."
APP_SCHEDULING_ENABLED=false docker-compose -f $COMPOSE_FILE up -d --no-deps --scale backend=2 --no-recreate backend

# Wait for new container to start
sleep 5

# Step 5: Get new backend container
NEW_BACKEND=$(docker ps --filter "label=com.shop.service=backend" --format "{{.Names}}" | grep -v "$OLD_BACKEND" | head -n 1)
log_info "New backend container: $NEW_BACKEND"

# Step 6: Wait for health check on new container
log_info "Waiting for new backend to be healthy..."
RETRY_COUNT=0
MAX_RETRIES=20

while [ $RETRY_COUNT -lt $MAX_RETRIES ]; do
    HEALTH_STATUS=$(docker inspect --format='{{.State.Health.Status}}' $NEW_BACKEND 2>/dev/null || echo "starting")

    if [ "$HEALTH_STATUS" = "healthy" ]; then
        log_info "New backend container is healthy!"
        break
    fi

    log_warn "Health status: $HEALTH_STATUS (attempt $((RETRY_COUNT+1))/$MAX_RETRIES)"
    sleep 5
    RETRY_COUNT=$((RETRY_COUNT+1))
done

if [ $RETRY_COUNT -eq $MAX_RETRIES ]; then
    log_error "New backend failed to become healthy!"
    log_error "Logs from new container:"
    docker logs $NEW_BACKEND --tail 50

    log_warn "Rolling back - removing new container..."
    docker stop $NEW_BACKEND
    docker rm $NEW_BACKEND
    exit 1
fi

# Step 6.5: Wait for APPLICATION readiness (not just container health)
log_info "Verifying application endpoints are ready..."
NEW_BACKEND_PORT=$(docker port $NEW_BACKEND 8080 | cut -d':' -f2)
APP_RETRY_COUNT=0
MAX_APP_RETRIES=30  # 30 attempts × 5s = 2.5 minutes

while [ $APP_RETRY_COUNT -lt $MAX_APP_RETRIES ]; do
    # Test multiple critical endpoints to ensure app is truly ready
    HEALTH_OK=false
    INFO_OK=false

    # Test 1: Health endpoint
    if curl -f -s -m 5 http://localhost:$NEW_BACKEND_PORT/actuator/health > /dev/null 2>&1; then
        HEALTH_OK=true
    fi

    # Test 2: Info endpoint (validates Spring Boot context is fully loaded)
    if curl -f -s -m 5 http://localhost:$NEW_BACKEND_PORT/actuator/info > /dev/null 2>&1; then
        INFO_OK=true
    fi

    if [ "$HEALTH_OK" = true ] && [ "$INFO_OK" = true ]; then
        log_info "✅ Application endpoints are fully ready!"

        # Additional verification: Check if JPA repositories are initialized
        log_info "Final check: Testing database connectivity..."
        sleep 5  # Give JPA one more moment to finalize

        if curl -f -s -m 5 http://localhost:$NEW_BACKEND_PORT/actuator/health > /dev/null 2>&1; then
            log_info "✅ Application is 100% ready for production traffic!"
            break
        fi
    fi

    log_warn "Application not fully ready yet (health=$HEALTH_OK, info=$INFO_OK) - attempt $((APP_RETRY_COUNT+1))/$MAX_APP_RETRIES"
    sleep 5
    APP_RETRY_COUNT=$((APP_RETRY_COUNT+1))
done

if [ $APP_RETRY_COUNT -eq $MAX_APP_RETRIES ]; then
    log_error "Application endpoints failed to become ready in time!"
    log_error "This is NOT a container health issue - the application is slow to initialize."
    log_error "Recent logs from new container:"
    docker logs $NEW_BACKEND --tail 100

    log_warn "Rolling back - removing new container..."
    docker stop $NEW_BACKEND
    docker rm $NEW_BACKEND
    exit 1
fi

# Step 7: Update Nginx to point to new backend
log_info "Updating Nginx configuration..."
NEW_BACKEND_PORT=$(docker port $NEW_BACKEND 8080 | cut -d':' -f2)
OLD_BACKEND_PORT=$(docker port $OLD_BACKEND 8080 | cut -d':' -f2)

log_info "Updating Nginx to use new backend on port $NEW_BACKEND_PORT..."
# Update proxy_pass line to use new backend port
sed -i "s|proxy_pass http://localhost:[0-9]*;|proxy_pass http://localhost:$NEW_BACKEND_PORT;|" $NGINX_CONFIG

# Step 8: Test and reload Nginx
log_info "Testing Nginx configuration..."
if nginx -t; then
    log_info "Reloading Nginx..."
    systemctl reload nginx
else
    log_error "Nginx configuration test failed!"
    log_error "Rolling back to old backend port..."
    sed -i "s|proxy_pass http://localhost:[0-9]*;|proxy_pass http://localhost:$OLD_BACKEND_PORT;|" $NGINX_CONFIG
    exit 1
fi

# Step 8.5: VERIFY Nginx is serving traffic from new backend
log_info "Verifying Nginx is serving traffic from new backend..."
VERIFY_RETRY=0
MAX_VERIFY=15

while [ $VERIFY_RETRY -lt $MAX_VERIFY ]; do
    # Test through Nginx (actual production URL)
    if curl -f -s -m 5 http://localhost/actuator/health > /dev/null 2>&1; then
        log_info "✅ Nginx successfully serving traffic from new backend!"
        break
    fi

    log_warn "Nginx not serving traffic yet (attempt $((VERIFY_RETRY+1))/$MAX_VERIFY)"
    sleep 2
    VERIFY_RETRY=$((VERIFY_RETRY+1))
done

if [ $VERIFY_RETRY -eq $MAX_VERIFY ]; then
    log_error "Nginx failed to serve traffic from new backend!"
    log_error "Rolling back to old backend..."
    sed -i "s|proxy_pass http://localhost:[0-9]*;|proxy_pass http://localhost:$OLD_BACKEND_PORT;|" $NGINX_CONFIG
    nginx -t && systemctl reload nginx
    log_error "Stopping new container..."
    docker stop $NEW_BACKEND
    docker rm $NEW_BACKEND
    log_info "Rollback complete. Old backend still running."
    exit 1
fi

# Step 9: Wait for connections to drain from old backend
log_info "Waiting 30s for connections to drain from old backend..."
sleep 30

# Step 10: Stop and remove old backend
log_info "Stopping old backend container: $OLD_BACKEND"
docker stop $OLD_BACKEND
docker rm $OLD_BACKEND

# Step 10.5: Enable scheduling on new backend
log_info "Enabling scheduled jobs on new backend..."
docker exec $NEW_BACKEND env | grep APP_SCHEDULING || true
# Restart new backend with scheduling enabled
docker stop $NEW_BACKEND
APP_SCHEDULING_ENABLED=true docker-compose -f $COMPOSE_FILE up -d --no-deps --no-recreate backend
sleep 5

# Step 11: Scale down to single backend instance
log_info "Scaling backend to 1 instance..."
docker-compose -f $COMPOSE_FILE up -d --scale backend=1 --no-recreate

# Step 12: Clean up old images (keep last 2 builds as backup)
log_info "Cleaning up old Docker images (keeping last 2 builds)..."

# Get all backend images, sorted by creation date (newest first)
BACKEND_IMAGES=$(docker images --filter "reference=shop-management-system-backend*" --format "{{.ID}} {{.CreatedAt}}" | sort -rk 2 | awk '{print $1}')

# Count total images
TOTAL_IMAGES=$(echo "$BACKEND_IMAGES" | wc -l)

if [ "$TOTAL_IMAGES" -gt 2 ]; then
    # Keep first 2 (newest), delete the rest
    IMAGES_TO_DELETE=$(echo "$BACKEND_IMAGES" | tail -n +3)

    if [ ! -z "$IMAGES_TO_DELETE" ]; then
        echo "$IMAGES_TO_DELETE" | xargs docker rmi -f 2>/dev/null || true
        DELETED_COUNT=$(echo "$IMAGES_TO_DELETE" | wc -l)
        log_info "Deleted $DELETED_COUNT old image(s), kept last 2 builds as backup"
    fi
else
    log_info "Only $TOTAL_IMAGES image(s) found, keeping all (target: 2)"
fi

# Also clean dangling images
docker image prune -f >/dev/null 2>&1

# Step 13: Update final Nginx config to point to single backend
FINAL_BACKEND=$(docker ps --filter "label=com.shop.service=backend" --format "{{.Names}}" | head -n 1)
FINAL_PORT=$(docker port $FINAL_BACKEND 8080 | cut -d':' -f2)

log_info "Updating Nginx to use single backend on port $FINAL_PORT..."
sed -i "s|proxy_pass http://localhost:[0-9]*;|proxy_pass http://localhost:$FINAL_PORT;|" $NGINX_CONFIG

nginx -t && systemctl reload nginx

# Final status
log_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
log_info "✅ Zero Downtime Deployment Complete!"
log_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
log_info "Active backend: $FINAL_BACKEND (port $FINAL_PORT)"
log_info "Deployment timestamp: $TIMESTAMP"
log_info ""
log_info "Verify deployment:"
log_info "  curl -f https://api.nammaoorudelivary.in/actuator/health"
log_info ""

# Show running containers
docker ps --filter "label=com.shop.service=backend"
