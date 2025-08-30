#!/bin/bash

# Production Deployment Script for NammaOoru Shop Management System
# This script deploys the application to production server

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Production Configuration
PRODUCTION_SERVER="65.21.4.236"
PRODUCTION_USER="root"
DEPLOYMENT_DIR="/root/nammaooru"
BACKUP_DIR="/root/backups"

# Print functions
print_status() {
    echo -e "${GREEN}✓${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
    exit 1
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

print_info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

# Header
echo ""
echo "================================================"
echo "   NammaOoru Production Deployment Script"
echo "   Server: $PRODUCTION_SERVER"
echo "   Time: $(date)"
echo "================================================"
echo ""

# Step 1: Check prerequisites
print_info "Checking prerequisites..."

# Check if .env.production exists
if [ ! -f ".env.production" ]; then
    print_error ".env.production file not found! Create it from .env.example"
fi

# Load production environment variables
export $(cat .env.production | grep -v '^#' | xargs)

# Step 2: Backup current deployment
print_info "Creating backup of current deployment..."

ssh $PRODUCTION_USER@$PRODUCTION_SERVER << 'ENDSSH'
    # Create backup directory if it doesn't exist
    mkdir -p /root/backups
    
    # Backup database
    echo "Backing up database..."
    pg_dump -U postgres shop_management_db > /root/backups/db_backup_$(date +%Y%m%d_%H%M%S).sql
    
    # Backup uploads
    echo "Backing up uploaded files..."
    if [ -d "/root/nammaooru/uploads" ]; then
        tar -czf /root/backups/uploads_backup_$(date +%Y%m%d_%H%M%S).tar.gz -C /root/nammaooru uploads
    fi
    
    echo "Backup completed"
ENDSSH

print_status "Backup completed"

# Step 3: Build Docker images
print_info "Building Docker images..."

# Build backend
echo "Building backend..."
cd backend
docker build -t nammaooru/backend:latest \
    --build-arg DB_URL="${DB_URL}" \
    --build-arg DB_USERNAME="${DB_USERNAME}" \
    --build-arg DB_PASSWORD="${DB_PASSWORD}" \
    --build-arg JWT_SECRET="${JWT_SECRET}" \
    --build-arg EMAIL_PASSWORD="${EMAIL_PASSWORD}" .

# Build frontend
echo "Building frontend..."
cd ../frontend
docker build -t nammaooru/frontend:latest \
    --build-arg API_URL="http://${PRODUCTION_SERVER}/api" .

cd ..
print_status "Docker images built"

# Step 4: Push to Docker Hub
print_info "Pushing images to Docker Hub..."

# Login to Docker Hub
echo "$DOCKER_PASSWORD" | docker login -u "$DOCKER_USERNAME" --password-stdin

# Push images
docker push nammaooru/backend:latest
docker push nammaooru/frontend:latest

print_status "Images pushed to Docker Hub"

# Step 5: Deploy to production server
print_info "Deploying to production server..."

# Copy necessary files to server
scp docker-compose.yml $PRODUCTION_USER@$PRODUCTION_SERVER:$DEPLOYMENT_DIR/
scp .env.production $PRODUCTION_USER@$PRODUCTION_SERVER:$DEPLOYMENT_DIR/

# Deploy on server
ssh $PRODUCTION_USER@$PRODUCTION_SERVER << 'ENDSSH'
    cd /root/nammaooru
    
    # Pull latest images
    echo "Pulling latest Docker images..."
    docker pull nammaooru/backend:latest
    docker pull nammaooru/frontend:latest
    
    # Stop current containers
    echo "Stopping current containers..."
    docker-compose down || true
    
    # Start new containers with production environment
    echo "Starting new containers..."
    docker-compose --env-file .env.production up -d
    
    # Wait for services to be ready
    echo "Waiting for services to be ready..."
    sleep 15
    
    # Health check
    echo "Running health checks..."
    if curl -f http://localhost:8082/actuator/health > /dev/null 2>&1; then
        echo "✓ Backend is healthy"
    else
        echo "✗ Backend health check failed"
        docker-compose logs backend
        exit 1
    fi
    
    if curl -f http://localhost > /dev/null 2>&1; then
        echo "✓ Frontend is accessible"
    else
        echo "⚠ Frontend might not be ready yet"
    fi
    
    # Clean up old images
    echo "Cleaning up old images..."
    docker image prune -f
    
    # Show status
    echo ""
    echo "Deployment Status:"
    docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
ENDSSH

print_status "Deployment completed successfully!"

# Step 6: Verify deployment
print_info "Verifying deployment..."

# Check if services are accessible
if curl -f http://$PRODUCTION_SERVER > /dev/null 2>&1; then
    print_status "Frontend is accessible at http://$PRODUCTION_SERVER"
else
    print_warning "Frontend is not accessible yet"
fi

if curl -f http://$PRODUCTION_SERVER:8082/actuator/health > /dev/null 2>&1; then
    print_status "Backend API is healthy at http://$PRODUCTION_SERVER:8082"
else
    print_warning "Backend API health check failed"
fi

# Step 7: Run post-deployment tasks
print_info "Running post-deployment tasks..."

ssh $PRODUCTION_USER@$PRODUCTION_SERVER << 'ENDSSH'
    cd /root/nammaooru
    
    # Set proper permissions for uploads directory
    docker exec backend chmod -R 755 /app/uploads || true
    
    # Clear application cache if needed
    # docker exec backend ./clear-cache.sh || true
    
    echo "Post-deployment tasks completed"
ENDSSH

# Summary
echo ""
echo "================================================"
echo "   DEPLOYMENT COMPLETED SUCCESSFULLY!"
echo "================================================"
echo ""
echo "📌 Access Points:"
echo "   Frontend:    http://$PRODUCTION_SERVER"
echo "   Backend API: http://$PRODUCTION_SERVER:8082"
echo "   Domain:      https://nammaoorudelivary.in"
echo ""
echo "📊 Monitoring:"
echo "   Health:      http://$PRODUCTION_SERVER:8082/actuator/health"
echo "   Logs:        ssh $PRODUCTION_USER@$PRODUCTION_SERVER 'docker-compose logs -f'"
echo ""
echo "🔄 Rollback (if needed):"
echo "   ssh $PRODUCTION_USER@$PRODUCTION_SERVER"
echo "   cd $DEPLOYMENT_DIR"
echo "   docker-compose down"
echo "   docker pull nammaooru/backend:previous"
echo "   docker pull nammaooru/frontend:previous"
echo "   docker-compose up -d"
echo ""
echo "Time: $(date)"
echo "================================================"