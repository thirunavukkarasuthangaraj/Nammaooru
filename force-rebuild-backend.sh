#!/bin/bash
# Force complete rebuild of backend container
# This script removes ALL cached layers and rebuilds from scratch

echo "========================================="
echo " Force Rebuild Backend (NO CACHE)"
echo "========================================="
echo ""

SERVER="root@65.21.4.236"
PROJECT_PATH="/opt/shop-management"

echo "[Step 1/8] Checking current CORS headers..."
curl -I -X OPTIONS https://api.nammaoorudelivary.in/api/auth/login \
  -H "Origin: https://nammaoorudelivary.in" \
  -H "Access-Control-Request-Method: POST" 2>&1 | grep -i "access-control" | head -10

echo ""
echo "[Step 2/8] Stopping all containers..."
ssh $SERVER "cd $PROJECT_PATH && docker compose down"

echo ""
echo "[Step 3/8] Removing backend images..."
ssh $SERVER "docker rmi nammaooru-backend shop-management-backend nammaooru/backend 2>/dev/null || true"

echo ""
echo "[Step 4/8] Pruning all Docker build cache..."
ssh $SERVER "docker builder prune -af && docker system prune -af"

echo ""
echo "[Step 5/8] Verifying latest code..."
ssh $SERVER "cd $PROJECT_PATH && git log --oneline -1"

echo ""
echo "[Step 6/8] Building backend with NO CACHE..."
ssh $SERVER "cd $PROJECT_PATH && docker compose build --no-cache --pull backend"

echo ""
echo "[Step 7/8] Starting all containers..."
ssh $SERVER "cd $PROJECT_PATH && docker compose up -d"

echo ""
echo "[Step 8/8] Waiting for backend to start (30 seconds)..."
sleep 30

echo ""
echo "========================================="
echo " Container Status"
echo "========================================="
ssh $SERVER "docker ps"

echo ""
echo "========================================="
echo " Backend Logs (Last 20 lines)"
echo "========================================="
ssh $SERVER "docker logs nammaooru-backend --tail 20"

echo ""
echo "========================================="
echo " Testing CORS Headers (AFTER REBUILD)"
echo "========================================="
curl -I -X OPTIONS https://api.nammaoorudelivary.in/api/auth/login \
  -H "Origin: https://nammaoorudelivary.in" \
  -H "Access-Control-Request-Method: POST" 2>&1 | grep -i "access-control"

echo ""
echo "========================================="
echo " Expected: ONLY ONE set of CORS headers"
echo " If you still see duplicates, there's a deeper issue"
echo "========================================="
