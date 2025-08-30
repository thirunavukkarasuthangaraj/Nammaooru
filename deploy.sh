#!/bin/bash

# NammaOoru Shop Management System - Deployment Script
# This script builds and deploys the application using Docker

set -e  # Exit on error

echo "🚀 Starting NammaOoru Deployment..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
DOCKER_REGISTRY="docker.io"
BACKEND_IMAGE="nammaooru/backend"
FRONTEND_IMAGE="nammaooru/frontend"
SERVER_HOST="${SERVER_HOST:-65.21.4.236}"
BUILD_TAG="${BUILD_TAG:-latest}"

# Function to print colored messages
print_status() {
    echo -e "${GREEN}✓${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    print_error "Docker is not installed. Please install Docker first."
    exit 1
fi

# Check if Docker Compose is installed
if ! command -v docker-compose &> /dev/null; then
    print_error "Docker Compose is not installed. Please install Docker Compose first."
    exit 1
fi

# 1. Build Backend
echo ""
echo "📦 Building Backend..."
cd backend
docker build -t ${DOCKER_REGISTRY}/${BACKEND_IMAGE}:${BUILD_TAG} .
print_status "Backend built successfully"

# 2. Build Frontend
echo ""
echo "📦 Building Frontend..."
cd ../frontend
docker build -t ${DOCKER_REGISTRY}/${FRONTEND_IMAGE}:${BUILD_TAG} \
  --build-arg API_URL=http://${SERVER_HOST}/api .
print_status "Frontend built successfully"

# 3. Stop existing containers
echo ""
echo "🛑 Stopping existing containers..."
cd ..
docker-compose down || true
print_status "Existing containers stopped"

# 4. Start new containers
echo ""
echo "🚀 Starting new containers..."
docker-compose up -d
print_status "New containers started"

# 5. Wait for services to be healthy
echo ""
echo "⏳ Waiting for services to be healthy..."
sleep 10

# Check backend health
if curl -f http://localhost:8082/actuator/health > /dev/null 2>&1; then
    print_status "Backend is healthy"
else
    print_error "Backend health check failed"
    docker-compose logs backend
    exit 1
fi

# Check frontend
if curl -f http://localhost > /dev/null 2>&1; then
    print_status "Frontend is accessible"
else
    print_warning "Frontend might not be accessible yet"
fi

# 6. Clean up old images
echo ""
echo "🧹 Cleaning up old images..."
docker image prune -f
print_status "Old images cleaned"

# 7. Show running containers
echo ""
echo "📊 Running containers:"
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

echo ""
echo "✅ Deployment completed successfully!"
echo ""
echo "📌 Access the application at:"
echo "   Frontend: http://${SERVER_HOST}"
echo "   Backend API: http://${SERVER_HOST}:8082"
echo ""
echo "📝 View logs:"
echo "   docker-compose logs -f backend"
echo "   docker-compose logs -f frontend"