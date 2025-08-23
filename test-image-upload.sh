#!/bin/bash
# Test image upload functionality

echo "🖼️ Testing Image Upload Functionality"
echo "====================================="

# Check if uploads volume exists
echo "1. Checking uploads volume..."
docker volume inspect shop-management-system_uploads_data > /dev/null 2>&1
if [ $? -eq 0 ]; then
    echo "✅ Uploads volume exists"
else
    echo "❌ Uploads volume not found"
fi

# Check volume mount in backend container
echo ""
echo "2. Checking backend volume mounts..."
docker exec backend ls -la /app/uploads 2>/dev/null
if [ $? -eq 0 ]; then
    echo "✅ /app/uploads directory accessible in backend"
else
    echo "❌ /app/uploads directory not accessible"
fi

# Check write permissions
echo ""
echo "3. Testing write permissions..."
docker exec backend touch /app/uploads/test.txt 2>/dev/null
if [ $? -eq 0 ]; then
    echo "✅ Write permissions OK"
    docker exec backend rm /app/uploads/test.txt
else
    echo "❌ No write permissions"
fi

# Check API endpoints
echo ""
echo "4. Checking image upload endpoints..."
curl -s -o /dev/null -w "%{http_code}" http://localhost:8082/api/products/images/upload
echo " - Product image upload endpoint"

curl -s -o /dev/null -w "%{http_code}" http://localhost:8082/api/shops/images/upload
echo " - Shop image upload endpoint"

# Check actual files in upload directory
echo ""
echo "5. Files in upload directory:"
docker exec backend find /app/uploads -type f 2>/dev/null | head -10

echo ""
echo "====================================="
echo "📊 Summary:"
echo "- Volume: shop-management-system_uploads_data"
echo "- Path in container: /app/uploads"
echo "- Max file size: 10MB"
echo ""
echo "To manually check uploads:"
echo "  docker exec backend ls -la /app/uploads"
echo ""
echo "To see uploaded images:"
echo "  docker exec backend find /app/uploads -name '*.jpg' -o -name '*.png'"