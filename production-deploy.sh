#!/bin/bash

# Production deployment script with full rebuild
# Run this on your production server at 65.21.4.236

echo "🚀 Starting production deployment with fresh build..."

# Navigate to project directory
cd /home/ubuntu/shop-management-system || exit 1

# Pull latest code from main branch
echo "📥 Pulling latest code from main branch..."
git fetch origin
git reset --hard origin/main
git pull origin main

# Show current commit
echo "📌 Current commit:"
git log --oneline -1

# Stop all running containers
echo "🛑 Stopping existing containers..."
docker-compose down

# Remove old images to force rebuild
echo "🗑️  Removing old Docker images..."
docker image rm shop-management-system-backend:latest 2>/dev/null || true
docker image rm shop-management-system-frontend:latest 2>/dev/null || true
docker image prune -f

# Clean Docker build cache
echo "🧹 Cleaning Docker build cache..."
docker builder prune -f

# Build and start containers with fresh images
echo "🏗️  Building containers from scratch..."
docker-compose build --no-cache

echo "🚀 Starting containers..."
docker-compose up -d

# Wait for services to start
echo "⏳ Waiting for services to start (60 seconds)..."
sleep 60

# Check container status
echo "📊 Container Status:"
docker-compose ps

# Check backend health and version
echo "🏥 Checking backend health and version..."
curl -s http://localhost:8082/api/actuator/health | head -20
echo ""
echo "📦 Backend version:"
curl -s http://localhost:8082/api/version

echo ""
echo "✅ Deployment completed!"
echo "📝 To view logs: docker-compose logs -f"