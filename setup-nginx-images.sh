#!/bin/bash
# Setup nginx to properly serve images

echo "🔧 Setting up Nginx for Image Serving"
echo "====================================="

# 1. Find where nginx configs are stored
echo "1. Checking nginx configuration..."
NGINX_SITES="/etc/nginx/sites-available"
NGINX_ENABLED="/etc/nginx/sites-enabled"

# Check if using sites-available or conf.d
if [ ! -d "$NGINX_SITES" ]; then
    NGINX_SITES="/etc/nginx/conf.d"
    NGINX_ENABLED="/etc/nginx/conf.d"
fi

echo "   Config directory: $NGINX_SITES"

# 2. Find the actual uploads volume path
echo ""
echo "2. Locating uploads volume..."
VOLUME_PATH=$(docker volume inspect shop-management_uploads_data --format '{{ .Mountpoint }}' 2>/dev/null)
echo "   Volume path: $VOLUME_PATH"

# 3. Create nginx config for api subdomain
echo ""
echo "3. Creating API nginx configuration..."

cat > $NGINX_SITES/api.nammaoorudelivary.in << EOF
# API and Image Serving Configuration
server {
    listen 80;
    server_name api.nammaoorudelivary.in;
    
    # Redirect to HTTPS if you have SSL
    # return 301 https://\$server_name\$request_uri;
    
    # For now, serve on HTTP
    
    # Serve uploaded images directly
    location /uploads/ {
        alias $VOLUME_PATH/;
        
        # Enable directory listing for debugging
        autoindex on;
        
        # Cache images
        expires 30d;
        add_header Cache-Control "public, immutable";
        
        # CORS headers
        add_header Access-Control-Allow-Origin "*" always;
        add_header Access-Control-Allow-Methods "GET, OPTIONS" always;
        
        # Security
        add_header X-Content-Type-Options nosniff;
    }
    
    # Proxy API requests to backend
    location /api/ {
        proxy_pass http://localhost:8082/api/;
        proxy_http_version 1.1;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        
        # CORS headers for API
        add_header Access-Control-Allow-Origin "*" always;
        add_header Access-Control-Allow-Methods "GET, POST, PUT, DELETE, OPTIONS" always;
        add_header Access-Control-Allow-Headers "*" always;
        add_header Access-Control-Allow-Credentials "true" always;
        
        # Handle OPTIONS
        if (\$request_method = 'OPTIONS') {
            return 204;
        }
    }
    
    # Default API endpoint
    location / {
        proxy_pass http://localhost:8082/;
        proxy_http_version 1.1;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}

# HTTPS configuration (if SSL is available)
server {
    listen 443 ssl;
    server_name api.nammaoorudelivary.in;
    
    # SSL certificates - update paths if they exist
    # ssl_certificate /etc/letsencrypt/live/api.nammaoorudelivary.in/fullchain.pem;
    # ssl_certificate_key /etc/letsencrypt/live/api.nammaoorudelivary.in/privkey.pem;
    
    # Same location blocks as above
    location /uploads/ {
        alias $VOLUME_PATH/;
        autoindex on;
        expires 30d;
        add_header Cache-Control "public, immutable";
        add_header Access-Control-Allow-Origin "*" always;
        add_header Access-Control-Allow-Methods "GET, OPTIONS" always;
        add_header X-Content-Type-Options nosniff;
    }
    
    location /api/ {
        proxy_pass http://localhost:8082/api/;
        proxy_http_version 1.1;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        
        add_header Access-Control-Allow-Origin "*" always;
        add_header Access-Control-Allow-Methods "GET, POST, PUT, DELETE, OPTIONS" always;
        add_header Access-Control-Allow-Headers "*" always;
        add_header Access-Control-Allow-Credentials "true" always;
        
        if (\$request_method = 'OPTIONS') {
            return 204;
        }
    }
    
    location / {
        proxy_pass http://localhost:8082/;
        proxy_http_version 1.1;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
EOF

# 4. Enable the site (if using sites-available)
if [ "$NGINX_SITES" = "/etc/nginx/sites-available" ]; then
    echo ""
    echo "4. Enabling site..."
    ln -sf $NGINX_SITES/api.nammaoorudelivary.in $NGINX_ENABLED/api.nammaoorudelivary.in
fi

# 5. Test nginx configuration
echo ""
echo "5. Testing nginx configuration..."
nginx -t

if [ $? -eq 0 ]; then
    echo "✅ Nginx configuration is valid"
    
    # 6. Reload nginx
    echo ""
    echo "6. Reloading nginx..."
    systemctl reload nginx
    echo "✅ Nginx reloaded"
else
    echo "❌ Nginx configuration error"
    exit 1
fi

# 7. Create test files in uploads directory
echo ""
echo "7. Creating test files..."
mkdir -p $VOLUME_PATH/products/master
echo "Test image" > $VOLUME_PATH/test.txt
echo "✅ Test file created"

# 8. Show results
echo ""
echo "====================================="
echo "✅ Nginx configuration complete!"
echo ""
echo "Image URLs will now work at:"
echo "  http://api.nammaoorudelivary.in/uploads/products/master/..."
echo "  https://api.nammaoorudelivary.in/uploads/products/master/..."
echo ""
echo "Test URLs:"
echo "  http://api.nammaoorudelivary.in/uploads/test.txt"
echo "  http://api.nammaoorudelivary.in/uploads/"
echo ""
echo "Volume location: $VOLUME_PATH"
echo ""
echo "Note: If api.nammaoorudelivary.in doesn't resolve,"
echo "      you need to add a DNS A record pointing to: $(curl -s ifconfig.me)"
echo "====================================="