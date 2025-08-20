#!/bin/bash

echo "🚀 Manual Deployment Script"
echo "============================"

SERVER="root@65.21.4.236"
DEPLOY_DIR="/opt/shop-management"

echo "1. Stopping and removing old containers..."
ssh $SERVER "docker stop shop-postgres shop-redis shop-frontend shop-backend 2>/dev/null || true"
ssh $SERVER "docker rm shop-postgres shop-redis shop-frontend shop-backend 2>/dev/null || true"

echo "2. Removing old images..."
ssh $SERVER "docker rmi shop-frontend:latest shop-backend:latest 2>/dev/null || true"

echo "3. Starting containers with fresh build..."
ssh $SERVER "cd $DEPLOY_DIR && docker-compose build --no-cache && docker-compose up -d"

echo "4. Waiting for containers to start..."
sleep 30

echo "5. Checking container status..."
ssh $SERVER "docker ps --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}'"

echo "6. Testing frontend..."
ssh $SERVER "curl -s http://localhost | head -20"

echo "✅ Deployment complete!"
echo "🌐 Check: https://nammaoorudelivary.in"