#!/bin/bash
# Emergency fix for site being down

echo "🚨 EMERGENCY FIX - Site is Down!"
echo "====================================="

# 1. Check what's wrong
echo "1. Checking services..."
docker ps --format "table {{.Names}}\t{{.Status}}"

# 2. Check if backend is running
echo ""
echo "2. Checking backend..."
curl -s http://localhost:8082/actuator/health > /dev/null 2>&1
if [ $? -eq 0 ]; then
    echo "✅ Backend is running"
else
    echo "❌ Backend is down - restarting..."
    docker-compose restart backend
    sleep 20
fi

# 3. Check if frontend is running
echo ""
echo "3. Checking frontend..."
curl -s http://localhost:8080 > /dev/null 2>&1
if [ $? -eq 0 ]; then
    echo "✅ Frontend is running"
else
    echo "❌ Frontend is down - restarting..."
    docker-compose restart frontend
    sleep 10
fi

# 4. Check nginx configuration
echo ""
echo "4. Checking nginx..."
nginx -t > /dev/null 2>&1
if [ $? -ne 0 ]; then
    echo "❌ Nginx config is broken - fixing..."
    
    # Remove the problematic api config if it exists
    rm -f /etc/nginx/sites-enabled/api.nammaoorudelivary.in
    rm -f /etc/nginx/conf.d/api.nammaoorudelivary.in
    
    # Create a simple working config for main site
    cat > /etc/nginx/sites-available/default << 'EOF'
server {
    listen 80 default_server;
    listen [::]:80 default_server;
    server_name nammaoorudelivary.in www.nammaoorudelivary.in;

    # Frontend
    location / {
        proxy_pass http://localhost:8080;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
    }

    # API proxy
    location /api/ {
        proxy_pass http://localhost:8082/api/;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        
        # CORS
        add_header Access-Control-Allow-Origin "$http_origin" always;
        add_header Access-Control-Allow-Methods "GET, POST, PUT, DELETE, OPTIONS" always;
        add_header Access-Control-Allow-Headers "*" always;
        add_header Access-Control-Allow-Credentials "true" always;
        
        if ($request_method = 'OPTIONS') {
            return 204;
        }
    }

    # Serve uploads
    location /uploads/ {
        alias /var/lib/docker/volumes/shop-management_uploads_data/_data/;
        autoindex on;
        add_header Access-Control-Allow-Origin "*";
    }
}

server {
    listen 80;
    server_name api.nammaoorudelivary.in;

    location / {
        proxy_pass http://localhost:8082/;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }

    location /uploads/ {
        alias /var/lib/docker/volumes/shop-management_uploads_data/_data/;
        autoindex on;
        add_header Access-Control-Allow-Origin "*";
    }
}
EOF
    
    # Enable it
    ln -sf /etc/nginx/sites-available/default /etc/nginx/sites-enabled/default
fi

# 5. Test and reload nginx
echo ""
echo "5. Testing nginx configuration..."
nginx -t
if [ $? -eq 0 ]; then
    echo "✅ Nginx config valid - reloading..."
    systemctl reload nginx
else
    echo "❌ Still broken - trying simpler config..."
    systemctl restart nginx
fi

# 6. Quick status check
echo ""
echo "6. Final status check..."
echo "---"
echo "Backend: $(curl -s -o /dev/null -w '%{http_code}' http://localhost:8082/actuator/health)"
echo "Frontend: $(curl -s -o /dev/null -w '%{http_code}' http://localhost:8080)"
echo "Main site: $(curl -s -o /dev/null -w '%{http_code}' http://nammaoorudelivary.in)"

echo ""
echo "====================================="
echo "✅ Emergency fix applied!"
echo ""
echo "Check:"
echo "  https://nammaoorudelivary.in - Main site"
echo "  https://api.nammaoorudelivary.in/uploads/ - Images"
echo "====================================="