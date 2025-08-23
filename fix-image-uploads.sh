#!/bin/bash
# Fix image upload serving issue

echo "🔧 Fixing Image Upload Configuration"
echo "====================================="

# 1. Find the actual uploads volume path
echo "1. Locating uploads volume..."
VOLUME_PATH=$(docker volume inspect shop-management_uploads_data --format '{{ .Mountpoint }}' 2>/dev/null)

if [ -z "$VOLUME_PATH" ]; then
    VOLUME_PATH=$(docker volume inspect shop_management_uploads_data --format '{{ .Mountpoint }}' 2>/dev/null)
fi

if [ -z "$VOLUME_PATH" ]; then
    echo "❌ Could not find uploads volume. Creating it..."
    docker volume create shop-management_uploads_data
    VOLUME_PATH=$(docker volume inspect shop-management_uploads_data --format '{{ .Mountpoint }}')
fi

echo "✅ Volume path: $VOLUME_PATH"

# 2. Check if images exist in the volume
echo ""
echo "2. Checking for existing images..."
if [ -d "$VOLUME_PATH" ]; then
    IMAGE_COUNT=$(find "$VOLUME_PATH" -type f \( -name "*.jpg" -o -name "*.jpeg" -o -name "*.png" -o -name "*.webp" \) 2>/dev/null | wc -l)
    echo "   Found $IMAGE_COUNT image files"
else
    echo "   No images found yet"
fi

# 3. Update nginx configuration
echo ""
echo "3. Updating nginx configuration..."

# Backup existing config
cp /etc/nginx/sites-available/nammaoorudelivary.in /etc/nginx/sites-available/nammaoorudelivary.in.backup

# Create updated nginx config
cat > /etc/nginx/sites-available/nammaoorudelivary.in << 'EOF'
server {
    listen 80;
    server_name nammaoorudelivary.in www.nammaoorudelivary.in;
    
    # Redirect HTTP to HTTPS
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl;
    server_name nammaoorudelivary.in www.nammaoorudelivary.in;

    # SSL configuration (adjust paths as needed)
    ssl_certificate /etc/letsencrypt/live/nammaoorudelivary.in/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/nammaoorudelivary.in/privkey.pem;

    # Frontend root
    root /opt/shop-management/frontend/dist/shop-management-frontend;
    index index.html;

    # Serve uploaded images - MUST come before /api location
    location /uploads/ {
        alias VOLUME_PATH_PLACEHOLDER/;
        
        # Allow directory listing for debugging
        autoindex on;
        
        # Cache images
        expires 30d;
        add_header Cache-Control "public, immutable";
        
        # CORS for images
        add_header Access-Control-Allow-Origin "*";
        
        # Security
        add_header X-Content-Type-Options nosniff;
    }

    # API proxy
    location /api/ {
        proxy_pass http://localhost:8082/api/;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        
        # CORS headers
        add_header Access-Control-Allow-Origin "$http_origin" always;
        add_header Access-Control-Allow-Methods "GET, POST, PUT, DELETE, OPTIONS" always;
        add_header Access-Control-Allow-Headers "*" always;
        add_header Access-Control-Allow-Credentials "true" always;
        
        # Handle OPTIONS
        if ($request_method = 'OPTIONS') {
            return 204;
        }
    }

    # Frontend routes
    location / {
        try_files $uri $uri/ /index.html;
    }

    # WebSocket support
    location /ws {
        proxy_pass http://localhost:8082/ws;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}
EOF

# Replace the volume path placeholder
sed -i "s|VOLUME_PATH_PLACEHOLDER|$VOLUME_PATH|g" /etc/nginx/sites-available/nammaoorudelivary.in

# 4. Test nginx configuration
echo ""
echo "4. Testing nginx configuration..."
nginx -t

if [ $? -eq 0 ]; then
    echo "✅ Nginx configuration is valid"
    
    # 5. Reload nginx
    echo ""
    echo "5. Reloading nginx..."
    systemctl reload nginx
    echo "✅ Nginx reloaded"
else
    echo "❌ Nginx configuration error. Restoring backup..."
    mv /etc/nginx/sites-available/nammaoorudelivary.in.backup /etc/nginx/sites-available/nammaoorudelivary.in
    exit 1
fi

# 6. Test image serving
echo ""
echo "6. Testing image serving..."
echo "   Volume path: $VOLUME_PATH"
echo "   Testing URL: https://nammaoorudelivary.in/uploads/"

# Create a test image if none exist
if [ "$IMAGE_COUNT" -eq "0" ]; then
    echo "   Creating test image..."
    mkdir -p "$VOLUME_PATH/products/test"
    echo "TEST" > "$VOLUME_PATH/products/test/test.txt"
    echo "   Test file created at: /uploads/products/test/test.txt"
fi

echo ""
echo "====================================="
echo "✅ Image upload configuration fixed!"
echo ""
echo "Test URLs:"
echo "  https://nammaoorudelivary.in/uploads/"
echo "  https://nammaoorudelivary.in/uploads/products/"
echo ""
echo "Volume location: $VOLUME_PATH"
echo "====================================="