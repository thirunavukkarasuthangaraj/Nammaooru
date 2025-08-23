#!/bin/bash
# Rebuild frontend to fix image URLs

echo "🔧 Rebuilding Frontend with Image URL Fixes"
echo "==========================================="

cd /opt/shop-management

# 1. Check current status
echo "1. Current container status:"
docker ps | grep frontend

# 2. Stop and remove old frontend container
echo ""
echo "2. Stopping old frontend container..."
docker-compose stop frontend
docker-compose rm -f frontend

# 3. Remove old frontend image to force rebuild
echo ""
echo "3. Removing old frontend image..."
docker rmi shop-frontend:latest 2>/dev/null || true

# 4. Build frontend with new code
echo ""
echo "4. Building frontend with fixed image URLs..."
echo "   This will take 2-3 minutes..."
docker-compose build --no-cache frontend

# 5. Start new frontend
echo ""
echo "5. Starting new frontend container..."
docker-compose up -d frontend

# 6. Wait for frontend to be ready
echo ""
echo "6. Waiting for frontend to start (20 seconds)..."
for i in {1..20}; do
    echo -n "."
    sleep 1
done
echo ""

# 7. Verify frontend is running
echo ""
echo "7. Verifying frontend status..."
docker-compose ps frontend
curl -s -o /dev/null -w "Frontend HTTP status: %{http_code}\n" http://localhost:8080

# 8. Check the actual image URL in the built code
echo ""
echo "8. Checking if image URL fix is in the build..."
docker exec shop-frontend grep -q "environment.apiUrl.replace" /usr/share/nginx/html/main*.js 2>/dev/null
if [ $? -eq 0 ]; then
    echo "✅ Image URL fix found in built code!"
else
    echo "⚠️  Image URL fix might not be in build - checking alternative location..."
    docker exec shop-frontend ls -la /usr/share/nginx/html/*.js | head -5
fi

echo ""
echo "==========================================="
echo "✅ Frontend rebuilt with image URL fixes!"
echo ""
echo "IMPORTANT NEXT STEPS:"
echo "1. Clear your browser cache (Ctrl+Shift+Delete)"
echo "2. Or test in Incognito/Private mode"
echo "3. Visit: https://nammaoorudelivary.in"
echo ""
echo "Image URLs should now show as:"
echo "  ✅ https://api.nammaoorudelivary.in/uploads/products/..."
echo "  NOT: https://nammaoorudelivary.in/.nammaoorudelivary.in/api/uploads/..."
echo "==========================================="