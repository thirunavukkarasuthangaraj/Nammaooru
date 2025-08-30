#!/bin/bash

# Production Fix Script - Run after CI/CD deployment
echo "🔧 Fixing production deployment issues..."

# Fix frontend container if it exists
docker rm -f nammaooru-frontend 2>/dev/null || true
docker-compose rm -f frontend 2>/dev/null || true

# Ensure correct ports in docker-compose.yml
sed -i 's/"80:80"/"3000:80"/g' docker-compose.yml

# Start services
docker-compose down
docker-compose up -d

# Wait for services to start
sleep 10

# Configure nginx for frontend proxy
cat > /etc/nginx/sites-available/nammaoorudelivary.in << 'EOF'
server {
    listen 80;
    server_name nammaoorudelivary.in www.nammaoorudelivary.in;

    location / {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    location /api {
        proxy_pass http://localhost:8082;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
EOF

# Enable nginx site
ln -sf /etc/nginx/sites-available/nammaoorudelivary.in /etc/nginx/sites-enabled/

# Test and reload nginx
nginx -t && systemctl reload nginx

echo "✅ Production fixes applied!"
docker ps