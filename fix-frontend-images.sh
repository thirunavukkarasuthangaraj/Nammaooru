#!/bin/bash
# Fix frontend image URLs by rebuilding with new code

echo "🔧 Fixing Frontend Image URLs"
echo "====================================="

cd /opt/shop-management

# 1. Pull latest code (already done)
echo "1. Code already updated from GitHub ✅"

# 2. Rebuild frontend with new code
echo ""
echo "2. Rebuilding frontend with fixed image URLs..."
docker-compose stop frontend
docker-compose build --no-cache frontend

# 3. Start frontend with new build
echo ""
echo "3. Starting frontend with new build..."
docker-compose up -d frontend

# 4. Wait for frontend to be ready
echo ""
echo "4. Waiting for frontend to start (15 seconds)..."
sleep 15

# 5. Check if frontend is running
echo ""
echo "5. Checking frontend status..."
docker-compose ps frontend

# 6. Clear browser cache reminder
echo ""
echo "====================================="
echo "✅ Frontend rebuilt with image URL fixes!"
echo ""
echo "IMPORTANT: Clear your browser cache!"
echo "  - Chrome: Ctrl+Shift+Delete → Clear browsing data"
echo "  - Or open in Incognito/Private mode"
echo ""
echo "The image URLs should now be correct:"
echo "  ❌ OLD: https://nammaoorudelivary.in/.nammaoorudelivary.in/api/uploads/..."
echo "  ✅ NEW: https://api.nammaoorudelivary.in/uploads/..."
echo "====================================="