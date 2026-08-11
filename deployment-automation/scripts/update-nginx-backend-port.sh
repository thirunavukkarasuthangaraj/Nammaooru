#!/bin/bash
# Detect backend's dynamic port and update Nginx

set -e

echo "🔄 Ensuring Nginx is pointing to latest backend port..."

# This server loads a regular file from sites-enabled (not a symlink to
# sites-available), so update the file Nginx actually includes.
NGINX_CONFIG="/etc/nginx/sites-enabled/api.nammaoorudelivary.in"

# Always target the newest running slot. Falling back to an older healthy slot
# while the new container is still starting can undo a successful deployment.
BACKEND_CONTAINER=$(docker ps --filter "label=com.shop.service=backend" --format "{{.Names}}" | while read -r name; do
    created=$(docker inspect "$name" --format '{{.Created}}')
    echo "$created $name"
done | sort -r | head -n 1 | cut -d' ' -f2)

if [ -z "$BACKEND_CONTAINER" ]; then
    echo "❌ No backend container found!"
    exit 1
fi

for attempt in $(seq 1 18); do
    health=$(docker inspect "$BACKEND_CONTAINER" --format '{{.State.Health.Status}}' 2>/dev/null || true)
    [ "$health" = "healthy" ] && break
    echo "Waiting for newest backend to become healthy ($attempt/18)..."
    sleep 5
done

if [ "$health" != "healthy" ]; then
    echo "Newest backend did not become healthy; leaving Nginx unchanged."
    exit 1
fi

# docker port can emit both IPv4 and IPv6 mappings. Read exactly one line so
# the replacement never receives a newline-separated pair of port numbers.
BACKEND_PORT=$(docker port "$BACKEND_CONTAINER" 8080 | tail -n 1 | awk -F: '{print $NF}')

if [ -z "$BACKEND_PORT" ]; then
    echo "❌ Could not detect backend port!"
    exit 1
fi

echo "✅ Found backend on port: $BACKEND_PORT (container: $BACKEND_CONTAINER)"

# Update Nginx configuration
# Use a delimiter that is not also the ERE alternation operator. Using `|` as
# both delimiter and `(localhost|127...)` alternation made sed parse the command
# incorrectly and left Nginx pointing at a removed container after deployment.
NGINX_TEMP=$(mktemp)
sed -E "s#proxy_pass http://(localhost|127\.0\.0\.1):[0-9]+;#proxy_pass http://127.0.0.1:$BACKEND_PORT;#" "$NGINX_CONFIG" > "$NGINX_TEMP"
cat "$NGINX_TEMP" > "$NGINX_CONFIG"
rm -f "$NGINX_TEMP"

# Test and reload Nginx
if sudo nginx -t; then
    sudo systemctl reload nginx
    echo "✅ Nginx updated and reloaded successfully!"
    echo "   Backend API now accessible at: https://api.nammaoorudelivary.in"
else
    echo "❌ Nginx configuration test failed!"
    exit 1
fi
