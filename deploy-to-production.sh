#!/bin/bash
# Production Deployment Script
# Run this on your production server (65.21.4.236)

set -e  # Exit on error

echo "=========================================="
echo "Starting Production Deployment"
echo "=========================================="

# Navigate to deployment directory
cd /opt/shop-management

echo "Step 1: Stopping existing containers..."
docker compose down || docker-compose down

echo "Step 2: Pulling latest code changes..."
git pull origin main

echo "Step 3: Building Docker images..."
docker compose build --no-cache

echo "Step 4: Starting services..."
docker compose up -d

echo "Step 5: Waiting for services to start..."
sleep 15

echo "Step 6: Checking container status..."
docker ps -a

echo "Step 7: Checking backend logs..."
docker logs nammaooru-backend --tail 50

echo "Step 8: Testing backend health..."
curl -f http://localhost:8082/actuator/health || echo "Backend health check failed!"

echo "Step 9: Testing frontend..."
curl -f http://localhost:80 || echo "Frontend check failed!"

echo "=========================================="
echo "Deployment Complete!"
echo "=========================================="
echo "Backend: http://65.21.4.236:8082"
echo "Frontend: http://65.21.4.236"
echo ""
echo "To view logs:"
echo "  Backend:  docker logs -f nammaooru-backend"
echo "  Frontend: docker logs -f nammaooru-frontend"
