#!/bin/bash
# Update Nginx to point to the backend container on fixed port 8085
# Run this after starting a new backend container

set -e

echo "🔄 Updating Nginx to use backend port 8085..."

# Fixed backend port (must match docker-compose.yml)
BACKEND_PORT=8085

echo "✅ Using fixed backend port: $BACKEND_PORT"

# Update Nginx configuration
NGINX_CONFIG="/etc/nginx/sites-available/api.nammaoorudelivary.in"
sed -i "s|proxy_pass http://localhost:[0-9]*;|proxy_pass http://localhost:$BACKEND_PORT;|" $NGINX_CONFIG

# Test and reload Nginx
if nginx -t; then
    systemctl reload nginx
    echo "✅ Nginx updated and reloaded successfully!"
    echo "   Backend API now accessible at: https://api.nammaoorudelivary.in"
else
    echo "❌ Nginx configuration test failed!"
    exit 1
fi
