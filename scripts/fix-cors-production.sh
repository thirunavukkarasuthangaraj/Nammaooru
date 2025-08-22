#!/bin/bash

# Fix CORS issue in production
# This script updates nginx config and restarts services

echo "=== Fixing CORS Configuration for Production ==="
echo "Time: $(date)"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if running as root or with sudo
if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}This script must be run as root or with sudo${NC}" 
   exit 1
fi

echo -e "${YELLOW}Step 1: Updating nginx configuration for API...${NC}"

# Create the updated nginx config for API
cat > /etc/nginx/sites-available/api.nammaoorudelivary.in << 'EOF'
server {
    listen 80;
    server_name api.nammaoorudelivary.in;
    
    # Redirect HTTP to HTTPS
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl http2;
    server_name api.nammaoorudelivary.in;
    
    # SSL certificates (you'll need to obtain these via Let's Encrypt)
    ssl_certificate /etc/letsencrypt/live/api.nammaoorudelivary.in/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/api.nammaoorudelivary.in/privkey.pem;
    
    # SSL configuration
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;
    ssl_prefer_server_ciphers on;
    
    # Proxy settings
    location / {
        proxy_pass http://localhost:8082;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
        
        # CORS headers - Allow both www and non-www domains
        set $cors_origin "";
        if ($http_origin ~* ^https://(www\.)?nammaoorudelivary\.in$) {
            set $cors_origin $http_origin;
        }
        
        add_header 'Access-Control-Allow-Origin' $cors_origin always;
        add_header 'Access-Control-Allow-Methods' 'GET, POST, PUT, DELETE, OPTIONS' always;
        add_header 'Access-Control-Allow-Headers' 'DNT,User-Agent,X-Requested-With,If-Modified-Since,Cache-Control,Content-Type,Range,Authorization' always;
        add_header 'Access-Control-Allow-Credentials' 'true' always;
        add_header 'Access-Control-Expose-Headers' 'Content-Length,Content-Range' always;
        
        # Handle preflight requests
        if ($request_method = 'OPTIONS') {
            add_header 'Access-Control-Allow-Origin' $cors_origin;
            add_header 'Access-Control-Allow-Methods' 'GET, POST, PUT, DELETE, OPTIONS';
            add_header 'Access-Control-Allow-Headers' 'DNT,User-Agent,X-Requested-With,If-Modified-Since,Cache-Control,Content-Type,Range,Authorization';
            add_header 'Access-Control-Allow-Credentials' 'true';
            add_header 'Access-Control-Max-Age' 1728000;
            add_header 'Content-Type' 'text/plain; charset=utf-8';
            add_header 'Content-Length' 0;
            return 204;
        }
    }
    
    # WebSocket support
    location /ws {
        proxy_pass http://localhost:8082/ws;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
EOF

echo -e "${GREEN}✓ Nginx config updated${NC}"

echo -e "${YELLOW}Step 2: Testing nginx configuration...${NC}"
nginx -t
if [ $? -ne 0 ]; then
    echo -e "${RED}✗ Nginx configuration test failed! Please check the configuration.${NC}"
    exit 1
fi
echo -e "${GREEN}✓ Nginx configuration test passed${NC}"

echo -e "${YELLOW}Step 3: Reloading nginx...${NC}"
systemctl reload nginx
echo -e "${GREEN}✓ Nginx reloaded${NC}"

echo -e "${YELLOW}Step 4: Updating docker-compose.yml...${NC}"
cd /root/shop-management-system || exit 1

# Backup current docker-compose.yml
cp docker-compose.yml docker-compose.yml.backup.$(date +%Y%m%d_%H%M%S)

# Update CORS environment variables in docker-compose.yml
# This ensures the backend has the correct CORS settings
sed -i '/FILE_UPLOAD_PATH=\/app\/uploads/a\      - APP_CORS_ALLOWED_ORIGINS=https://nammaoorudelivary.in,https://www.nammaoorudelivary.in\n      - APP_CORS_ALLOWED_METHODS=GET,POST,PUT,DELETE,OPTIONS\n      - APP_CORS_ALLOWED_HEADERS=*\n      - APP_CORS_ALLOW_CREDENTIALS=true' docker-compose.yml

# Remove old CORS_ALLOWED_ORIGINS if it exists
sed -i '/CORS_ALLOWED_ORIGINS=/d' docker-compose.yml

echo -e "${GREEN}✓ docker-compose.yml updated${NC}"

echo -e "${YELLOW}Step 5: Restarting backend container...${NC}"
docker-compose stop backend
docker-compose up -d backend
echo -e "${GREEN}✓ Backend container restarted${NC}"

echo -e "${YELLOW}Step 6: Waiting for backend to be healthy...${NC}"
sleep 10

# Check if backend is responding
for i in {1..30}; do
    if curl -f http://localhost:8082/actuator/health > /dev/null 2>&1; then
        echo -e "${GREEN}✓ Backend is healthy${NC}"
        break
    fi
    echo "Waiting for backend... ($i/30)"
    sleep 2
done

echo -e "${YELLOW}Step 7: Testing CORS headers...${NC}"
echo "Testing from https://nammaoorudelivary.in..."
curl -I -X OPTIONS \
  -H "Origin: https://nammaoorudelivary.in" \
  -H "Access-Control-Request-Method: POST" \
  -H "Access-Control-Request-Headers: Content-Type" \
  https://api.nammaoorudelivary.in/api/auth/login 2>/dev/null | grep -i "access-control"

echo ""
echo "Testing from https://www.nammaoorudelivary.in..."
curl -I -X OPTIONS \
  -H "Origin: https://www.nammaoorudelivary.in" \
  -H "Access-Control-Request-Method: POST" \
  -H "Access-Control-Request-Headers: Content-Type" \
  https://api.nammaoorudelivary.in/api/auth/login 2>/dev/null | grep -i "access-control"

echo ""
echo -e "${GREEN}=== CORS Fix Deployment Complete ===${NC}"
echo "Please test login from both:"
echo "  - https://nammaoorudelivary.in"
echo "  - https://www.nammaoorudelivary.in"
echo ""
echo "If issues persist, check logs with:"
echo "  docker-compose logs -f backend"
echo "  tail -f /var/log/nginx/error.log"