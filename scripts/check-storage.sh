#!/bin/bash

# Storage Usage Monitor for Your 60GB+ Hetzner Server

echo "🖥️  CX22 Server Storage Analysis"
echo "================================"

# Server disk usage
echo "💾 Server Disk Usage:"
df -h | grep -E "Size|/dev"

echo ""
echo "📦 Docker Volumes:"
docker system df -v | grep -A 10 "VOLUME NAME"

echo ""
echo "🗂️  Upload Folders Usage:"
docker exec shop-backend sh -c 'du -sh /app/uploads/* 2>/dev/null || echo "No files yet"'

echo ""
echo "📊 Storage Capacity Planning:"
echo "  Total Available: ~60GB"
echo "  Current Usage: $(df -h / | awk 'NR==2{print $3}')"
echo "  Available Space: $(df -h / | awk 'NR==2{print $4}')"

echo ""
echo "💰 Cost Analysis:"
echo "  ✅ Your current plan: €3.99/month" 
echo "  ✅ Storage included: Up to 60GB"
echo "  ✅ Additional cost: €0"

echo ""
echo "📈 Image Capacity Estimate:"
AVAILABLE_KB=$(df / | awk 'NR==2{print $4}')
AVAILABLE_GB=$((AVAILABLE_KB / 1024 / 1024))
IMAGES_500KB=$((AVAILABLE_GB * 2000))
IMAGES_1MB=$((AVAILABLE_GB * 1000))

echo "  At 500KB/image: ~$IMAGES_500KB images"
echo "  At 1MB/image: ~$IMAGES_1MB images"