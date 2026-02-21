#!/bin/bash
# Ensure Nginx points to fixed backend port 8081

set -e

echo "🔄 Ensuring Nginx is pointing to latest backend port..."

BACKEND_PORT=8081
NGINX_CONFIG="/etc/nginx/sites-available/api.nammaoorudelivary.in"

echo "✅ Found backend on port: $BACKEND_PORT"

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
