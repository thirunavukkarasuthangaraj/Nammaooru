#!/bin/bash
# Auto-update Nginx to point to the latest backend container port
# Run this after starting a new backend container

set -e

echo "🔄 Updating Nginx to latest backend port..."

# Get the port of the running backend container
BACKEND_PORT=$(docker ps --filter "label=com.shop.service=backend" --format "{{.Ports}}" | grep -oP '0.0.0.0:\K[0-9]+' | head -1)

if [ -z "$BACKEND_PORT" ]; then
    echo "❌ No backend container found!"
    exit 1
fi

echo "✅ Found backend on port: $BACKEND_PORT"

# Update Nginx configuration
NGINX_CONFIG="/etc/nginx/sites-available/api.nammaoorudelivary.in"
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
