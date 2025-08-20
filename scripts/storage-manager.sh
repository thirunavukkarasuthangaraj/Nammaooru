#!/bin/bash

# Storage Manager for Hetzner Image Uploads
# Your CX22 Server: 60GB+ available storage

UPLOAD_BASE="/app/uploads"

echo "🗂️  Setting up organized image storage structure..."

# Create folder structure inside Docker container
docker exec shop-backend mkdir -p \
  ${UPLOAD_BASE}/products/images \
  ${UPLOAD_BASE}/products/thumbnails \
  ${UPLOAD_BASE}/shops/logos \
  ${UPLOAD_BASE}/shops/banners \
  ${UPLOAD_BASE}/users/avatars \
  ${UPLOAD_BASE}/users/profiles \
  ${UPLOAD_BASE}/documents/verification \
  ${UPLOAD_BASE}/documents/licenses \
  ${UPLOAD_BASE}/temp/processing \
  ${UPLOAD_BASE}/backup/old-images

# Set proper permissions
docker exec shop-backend chown -R appuser:appgroup ${UPLOAD_BASE}
docker exec shop-backend chmod -R 755 ${UPLOAD_BASE}

# Display storage usage
echo "📊 Current storage usage:"
docker exec shop-backend du -sh ${UPLOAD_BASE}/*

echo "✅ Folder structure created successfully!"
echo ""
echo "📁 Available folders:"
echo "  📦 /uploads/products/images     - Product photos"
echo "  🖼️  /uploads/products/thumbnails - Product thumbnails"  
echo "  🏪 /uploads/shops/logos        - Shop logos"
echo "  🎨 /uploads/shops/banners      - Shop banner images"
echo "  👤 /uploads/users/avatars      - User profile pictures"
echo "  📄 /uploads/documents/         - Business documents"
echo "  🗑️  /uploads/temp/             - Temporary uploads"
echo ""
echo "🌐 Access URLs:"
echo "  https://api.nammaoorudelivary.in/uploads/products/images/filename.jpg"
echo "  https://api.nammaoorudelivary.in/uploads/shops/logos/filename.png"