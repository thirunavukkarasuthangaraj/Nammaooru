#!/bin/bash
# Detect backend's dynamic port and update Nginx

set -e

echo "🔄 Ensuring Nginx is pointing to latest backend port..."

NGINX_CONFIG="/etc/nginx/sites-available/api.nammaoorudelivary.in"

# Find running backend container and its dynamic port
BACKEND_CONTAINER=$(docker ps --filter "label=com.shop.service=backend" --format "{{.Names}}" | head -n 1)

if [ -z "$BACKEND_CONTAINER" ]; then
    echo "❌ No backend container found!"
    exit 1
fi

BACKEND_PORT=$(docker port $BACKEND_CONTAINER 8080 | cut -d':' -f2)

if [ -z "$BACKEND_PORT" ]; then
    echo "❌ Could not detect backend port!"
    exit 1
fi

echo "✅ Found backend on port: $BACKEND_PORT (container: $BACKEND_CONTAINER)"

# Update Nginx configuration
sudo sed -i "s|proxy_pass http://localhost:[0-9]*;|proxy_pass http://localhost:$BACKEND_PORT;|" $NGINX_CONFIG

# Test and reload Nginx
if sudo nginx -t; then
    sudo systemctl reload nginx
    echo "✅ Nginx updated and reloaded successfully!"
    echo "   Backend API now accessible at: https://api.nammaoorudelivary.in"
else
    echo "❌ Nginx configuration test failed!"
    exit 1
fi
